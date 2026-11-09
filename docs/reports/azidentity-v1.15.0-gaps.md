# azidentity: the port against Go v1.15.0

Status (2026-11-07): (1), (2), (3), (4), (6), (7), (8), (9), (10), (11), (12), (13) and (14) are ported (azidentity/CHANGELOG.md).
Lead calls: (11) approved by the owner, built to decision 0009 (accepted); (5) is ported, its self signed certificate accepted by the pin alone (std/http's `Client.with_verify`, Verify.None only with the pin). Go's azidentity
v1.15.0 is 3781 hand-written lines over MSAL Go v1.10.1; our port is
837 lines, version mark `v0.1.0`, written to decision 0003 (the client
credentials grant by hand, no MSAL).

Method: a Go program runs azidentity v1.15.0 against a fake transport
and prints every request each credential makes and each result. Its
authority host is `https://login.example.test/`, `http.DefaultTransport`
is replaced by one that refuses every request (none was refused: every
request went through the fake), and it runs under `env -i` with no
`AZURE_*` variables. DefaultAzureCredential runs only with
`AZURE_TOKEN_CREDENTIALS=prod`, so the developer tools are never started.
Each managed identity source runs in its own process, because MSAL Go
keeps one managed identity token cache per process.

## In scope by decision 0003, missing or different

Ranked by how many callers meet the gap first.

1. **What MSAL adds to the token request.** Go's form has `scope=<scopes>
   openid offline_access profile`, an assertion grant adds
   `client_info=1`, the content type is `application/x-www-form-urlencoded;
   charset=utf-8`, and the headers carry `client-request-id` (a UUID) and
   `return-client-request-id: false`. Ours sends the scopes alone and
   neither header. Cheap, and every confidential credential sends it.
2. **Instance discovery and the tenant's OpenID metadata.** Before its
   first token request, MSAL Go sends `GET
   https://login.microsoftonline.com/common/discovery/instance?api-version=1.1&authorization_endpoint=<authority>/<tenant>/oauth2/v2.0/authorize`
   (twice), then `GET <authority>/<tenant>/v2.0/.well-known/openid-configuration`,
   and posts to the `token_endpoint` that document names. It does this
   once per tenant per MSAL client (azidentity keeps a CAE client and a
   plain one, so a CAE request looks the tenant up again). With `DisableInstanceDiscovery` it skips
   the first and keeps the second. Ours posts to
   `<authority>/<tenant>/oauth2/v2.0/token` directly. This needs a call:
   port the two lookups (and `disable_instance_discovery`), or record the
   shortcut as a divergence (fewer round trips; the same token for a
   valid authority; a different error for an invalid one).
3. **Error text.** Go's `AuthenticationFailedError` prints `<Credential>
   authentication failed.`, the request line, the `RESPONSE <code>` block
   with the body indented, and a troubleshooting link
   (`https://aka.ms/azsdk/go/identity/troubleshoot#client-secret`, one
   anchor per credential). Its tenant errors are Go's sentences too
   (`invalid tenantID. You can locate your tenantID ...`, `... isn't
   configured to acquire tokens for tenant "x". To enable acquiring
   tokens for this tenant add it to the AdditionallyAllowedTenants ...`).
   Ours are short messages of our own. azcore's ResponseError text is
   already Go's, so this reuses it.
4. **The IMDS probe inside DefaultAzureCredential.** Go first sends a
   malformed `GET http://169.254.169.254/metadata/identity/oauth2/token`
   (no query, no `Metadata` header, 1 s, no retries): any answer means
   IMDS is there, a timeout means unavailable (`managed identity timed
   out. See https://aka.ms/azsdk/go/identity/troubleshoot#dac ...`). Then
   it sends the real request with normal retries. Ours sends the real
   request with a 1 s timeout and no retries. Also: an IMDS reply that is
   not JSON is "unavailable" inside a chain (something else listens there).
5. **Service Fabric.** `IDENTITY_ENDPOINT`, `IDENTITY_HEADER` and
   `IDENTITY_SERVER_THUMBPRINT`: v1.15.0 pins the endpoint's certificate
   to that thumbprint and refuses redirects. Decision 0003 lists Service
   Fabric. **Done**: the pin runs on every new connection
   (`Client.with_verify_conn`, decision 0541), and the chain and name
   checks are off for the self signed certificate (`Client.with_verify(
   tls.Verify.None)`, only together with the pin).
6. **Certificates from PKCS #12.** Decision 0003 says PKCS #12 waits on
   std. std now has `x509.parse_pkcs12` (Go's pkcs12.Decode with chains),
   so `parse_certificates` can read a `.pfx` with a password
   (`AZURE_CLIENT_CERTIFICATE_PASSWORD`), as Go's `ParseCertificates`.
7. **DefaultAzureCredential's options and selection.**
   `RequireAzureTokenCredentials` (error text checked against Go),
   `TenantID`, and `AZURE_TOKEN_CREDENTIALS=dev`, which Go accepts and
   which our chain can only reject (the developer credentials are out),
   with Go's message for an unknown value (`invalid
   AZURE_TOKEN_CREDENTIALS value "bogus". Valid values are "dev", "prod",
   or the name of any credential type in the default chain. See ...`).
8. **ChainedTokenCredential `RetrySources`.** Go's chain keeps using the
   credential that worked unless `RetrySources` is set. Ours always
   keeps it. Ported 2026-11-06 (`retry_sources`), checked against a Go
   chain whose first source fails once and then works.
9. **WorkloadIdentityCredential options.** In Go, `ClientID`, `TenantID`
   and `TokenFilePath` default to `AZURE_CLIENT_ID`, `AZURE_TENANT_ID` and
   `AZURE_FEDERATED_TOKEN_FILE`, with Go's errors (`no client ID
   specified. Check pod configuration or set ClientID in the options`).
   Ours takes all three as arguments. Ported 2026-11-06
   (`new_workload_identity_credential_from_env`), with 8 Go cases.
10. **v1.15.0: workload identity's Azure proxy mode**
    (`EnableAzureProxy`): the token request goes to
    `AZURE_KUBERNETES_TOKEN_PROXY`, with `AZURE_KUBERNETES_SNI_NAME` and
    a CA from `AZURE_KUBERNETES_CA_FILE` or `AZURE_KUBERNETES_CA_DATA`.
    Ported 2026-11-07, with std/http's `with_server_name` and
    `Request.with_host` (decision 0541).

## In scope, owner decision pending

11. **Azure Arc** (system-assigned, and v1.15.0's user-assigned):
    `IDENTITY_ENDPOINT` with `IMDS_ENDPOINT`. A GET with
    `api-version=2020-06-01` must get a 401 whose `WWW-Authenticate: Basic
    realm=<path>` names a key file under the agent's directory. The
    credential reads that file and retries with `Authorization: Basic
    <key>`. A 200 to the first request is an error (`expected a 401
    response, received 200`). Owner notes (2026-11-05): "comes later".
    v1.15.0's user-assigned support is the reason to ask now.
    Ported 2026-11-06 (decision 0009), with 49 Go cases.

## New credentials that fit the port

These are server-side flows with no user interaction, built on the same
grant code.

12. **ClientAssertionCredential**: `client_assertion` from a callback.
    About 30 lines on top of `Confidential`.
13. **OnBehalfOfCredential** (secret, certificate, assertion callback):
    `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer`,
    `assertion=<user token>`, `requested_token_use=on_behalf_of`, and a
    cache keyed by the user assertion.
    Ported 2026-11-06 with 4 Go sections (secret, certificate, assertion
    callback, refresh token): MSAL redeems the refresh token an
    on-behalf-of response carries for any later scope, tenant or claims
    request, and falls back to the on-behalf-of grant when that fails.
14. **AzurePipelinesCredential**: `POST
    <SYSTEM_OIDCREQUESTURI>?api-version=7.1&serviceConnectionId=<id>`
    with `Authorization: Bearer <system token>` and
    `X-TFS-FedAuthRedirect: Suppress`, then its `oidcToken` as the
    client assertion.
    Ported 2026-11-06 with 22 Go cases (constructor errors, cache and
    tenants, the OIDC endpoint's errors with `x-msedge-ref` and
    `x-vss-e2eid`, and Go's URL building).

## Out by decision (no change proposed)

AzureCLICredential, AzureDeveloperCLICredential and
AzurePowerShellCredential (owner: not without the owner's word; the CLI
may come as an opt-in through its own decision record). The user flows
and the persistent cache below are out by decision 0003 (no MSAL port,
no interactive flows, no shared cache file); each lists exactly what it
waits on, read from azidentity v1.15.0 over MSAL Go v1.10.1 and
azidentity/cache v0.4.0.

### Waiting on MSAL behaviour

Common to all three user flows: a public client (no client secret),
`AcquireTokenSilent` first with the account of the credential's
`AuthenticationRecord`, which redeems a cached refresh token
(`grant_type=refresh_token`, `client_info=1`) before any user step;
MSAL's account model (`home_account_id` = `<uid>.<utid>` from the
base64url `client_info` the token response carries, `environment`,
`realm`, the ID token's `preferred_username`), from which azidentity
builds the `AuthenticationRecord`; and the per-account cache lookup
(access token by home account, environment, client, realm and scopes;
refresh token by home account, environment and client, or family `1`).

15. **DeviceCodeCredential**: `POST <authority>/<tenant>/oauth2/v2.0/devicecode`
    (`client_id`, `scope` with `openid offline_access profile`), the
    `UserPrompt` callback with Go's message, then polling the token
    endpoint with `grant_type=device_code` and `device_code`, waiting
    `interval` seconds, continuing on `authorization_pending` and
    `slow_down`, stopping at `expires_in` or on any other error.
16. **InteractiveBrowserCredential**: a loopback HTTP server on
    `RedirectURL` or `http://localhost:<free port>`, the authorize URL
    (`response_type=code`, `code_challenge` with
    `code_challenge_method=S256`, `prompt=select_account`, `login_hint`,
    `state`) opened in the system browser, the redirect's `code` and
    `state` checked, then `grant_type=authorization_code` with
    `code_verifier`. Starting a browser is an outside-process effect
    this port has no decision for.
17. **UsernamePasswordCredential** (deprecated in Go, kept for ROPC):
    `GET https://<authority host>/common/UserRealm/<user>?api-version=1.0`;
    `account_type` `Managed` posts `grant_type=password` with
    `username` and `password`; `Federated` fetches the mex document at
    `federation_metadata_url`, sends a WS-Trust 1.3 or 2005 SOAP
    request to its username endpoint, and exchanges the SAML assertion
    with `grant_type=urn:ietf:params:oauth:grant-type:saml1_1-bearer`
    or `saml2-bearer`.
18. **AuthenticationRecord and AuthenticationRequiredError**: the record
    is MSAL's account (item 15's common part) serialized as Go's JSON
    (`authority`, `clientId`, `homeAccountId`, `tenantId`, `username`,
    `version` `1.0`); `Authenticate()` runs the flow once and returns
    it. `DisableAutomaticAuthentication` turns a failed silent request
    into `AuthenticationRequiredError` with its `TokenRequestOptions`
    instead of starting the flow.

Decision 0003's Amendment 2 (Accepted by the owner, 2026-11-07) allows
15 to 18: it adds public clients and the account model by
hand, as 0003 did the client credentials grant, and gives 16 the
authorize URL through a caller callback instead of starting a browser.

Status (2026-11-08): 15 to 18 are done (`azidentity/public.xo`,
`azidentity/interactive.xo`, `azidentity/usernamepassword.xo`, checked
against Go programs over fakes: 16's with a scratch hook passing MSAL's
WithOpenURL, so no browser starts). For 17, MSAL Go v1.10.1 sends only
the WS-Trust 1.3 request: a mex document whose only username endpoint
is 2005 fails with MSAL's "WS Trust 2005 support is not implemented",
and the port keeps that. The ADFS authority (tenant `adfs`) is handled
where 17 needs it (the OpenID configuration at `/adfs/`, no instance
discovery, the password grant with no realm); MSAL's other ADFS rules
(the per-domain endpoint cache, "ADFS authority doesn't support
tenants" for a request's other tenant) are not ported yet.

### Waiting on a token-cache decision

19. **The persistent `Cache` and `azidentity/cache`**, decision
    [0012](../decisions/0012-persistent-token-cache.md). Status
    (2026-11-09): step a is done (`azidentity/cache.xo`): `Options.cache`
    takes a `Cache` of caller-supplied `TokenStore`s, and every
    credential Go gives `Cache` runs MSAL's `ExportReplace` protocol over
    MSAL's shared cache schema (access tokens for the confidential
    credentials; refresh tokens, ID tokens, accounts and app metadata
    for the user flows), checked against Go (`cache_run_test.xo`). Not
    yet: step b (Deferred, owner 2026-11-07), the per-OS store at
    `.IdentityService/<name>` (and `<name>.cae`) with a `.lockfile`, in
    the macOS keychain, under Windows DPAPI, or as A128CBC-HS256 JWE with
    its key in the Linux user keyring; MSAL's partitioned cache for
    on-behalf-of (Go gives that credential no `Cache`). Done since
    (2026-11-09, from more oracle cases): a stored cache is decoded as
    MSAL decodes it (each section and entry an object, string fields
    strings, Unix times read by Go's Atoi, with Go's error texts; empty
    and null strings dropped and times written back as strings; text
    after the object ignored), and v1.0 keys (with an upper-case
    letter) are upgraded to lower case when a read matches them, an
    existing lower-case entry winning.

## Already the same as Go (checked by the same program)

- Managed identity requests per source: IMDS `api-version=2018-02-01`
  with `Metadata: true` and `client_id` / `object_id` / `msi_res_id`; App
  Service `api-version=2019-08-01` with `X-IDENTITY-HEADER` and
  `client_id`; Cloud Shell `POST` with a form body `resource=...`; Azure
  ML `api-version=2017-09-01` with `secret` and `clientid`.
- Claims with CAE (`xms_cc` `CP1` merged under `access_token`), the
  per-credential cache, `AdditionallyAllowedTenants` including `*`.
- The certificate assertion: PS256 with `x5t#S256` (MSAL's choice for
  Entra ID authorities; RS256 with `x5t` only for ADFS and DSTS).

Two differences to recheck when porting: Go's Azure ML request sends
`clientid=` (empty) for a system-assigned identity, and ours omits it.
An Azure ML client ID and App Service resource ID use different names,
so every name gets a vector.

## Proposed order

(1) and (3) first, since every confidential credential shows them. Then
(12), (6), (4), (7) to (9), (13), (14) and (10). (2) and (11) wait for
the lead's and owner's calls. (5) is done. Each item
gets its vectors from the Go program above, extended per item.
