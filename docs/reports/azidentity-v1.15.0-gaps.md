# azidentity: the port against Go v1.15.0

Status (2026-11-07): (1), (2), (3), (4), (6), (7), (8), (9), (10), (11), (12), (13) and (14) are ported (azidentity/CHANGELOG.md).
Lead calls: (11) approved by the owner, built to decision 0009 (accepted); (5) is unblocked: std/tls and std/http have `verify_conn`, `with_server_name` and `Request.with_host` (decision 0541). Go's azidentity
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
   Fabric, but the port has no source for it. **Blocked on std**: std/tls
   and std/http give a client no way to see or check the server's
   certificate beyond `Verify` and `Roots`. That needs an upstream draft,
   for example a client option that pins a SHA-1 or SHA-256 thumbprint,
   or the peer certificates on a response, as Go's
   `VerifyPeerCertificate`.
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
may come as an opt-in through its own decision record),
DeviceCodeCredential, InteractiveBrowserCredential,
UsernamePasswordCredential, AuthenticationRecord,
AuthenticationRequiredError and the persistent `Cache` (decision 0003:
no MSAL port, no interactive flows, no shared cache file).

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
the lead's and owner's calls. (5) waits on the std draft. Each item
gets its vectors from the Go program above, extended per item.
