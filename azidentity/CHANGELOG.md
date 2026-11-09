# azidentity changes

Newest first. The module's Xo version is v0.1.0. It is moving to Go's
azidentity v1.15.0 (with MSAL Go v1.10.1) item by item, as listed in
`docs/reports/azidentity-v1.15.0-gaps.md`; each change is checked against
the lines a Go program prints with v1.15.0 (`govectors_test.xo`).

## Unreleased

- Tenants as azidentity v1.15.0 and MSAL Go v1.10.1 resolve them.
  azidentity's resolveTenant: "ADFS doesn't support tenants" for a
  credential at `adfs` asked for another tenant, Go's invalid tenant ID
  error, and any tenant for a credential at `organizations` (or "")
  that has no allow list. MSAL's WithTenantID check: an ADFS authority
  takes no other tenant, an AAD one no `common`, `consumers` or
  `organizations` request, and a `consumers` client no other tenant.
  Device code returns these as MSAL's text; the other credentials
  return them as authentication failures. MSAL reads the authority in
  lower case, so a tenant `ADFS` is an ADFS authority (a confidential
  credential there fails every request, as in Go), and the persistent
  cache's realm and partition hint are the tenant in lower case. A
  client certificate at an ADFS authority signs its assertion with
  RS256 and sends the SHA-1 thumbprint as `x5t`, as MSAL does.
- The persistent cache reads a stored cache as MSAL Go v1.10.1 decodes
  it: each section and entry must be an object, a known string field a
  string, a Unix time an integer Go's Atoi reads (as a string or a
  number); Go's error texts otherwise ("unix time(...) could not be
  converted from string to int: ...", "json: cannot unmarshal number
  into Go value of type string", "Unmarshal expected opening {,
  received ..."). Known fields are written back as MSAL writes them
  (times as strings, empty and null strings left out), a time of 0 is
  the Unix epoch, and text after the object is ignored. Entries under
  v1.0 keys (with an upper-case letter) are upgraded to lower case
  when a read matches them, an existing lower-case entry winning, as
  MSAL does.
- A persistent token cache (decision 0012 step a, gap item 19), Go's
  `Cache` option: `Options.cache` takes a `Cache` (`new_cache`, from a
  factory of `TokenStore`s the caller supplies: `replace(hint)` and
  `export(hint, json)`, one store for CAE requests and one for the
  rest, each made on first use). As MSAL Go v1.10.1 does, a credential
  reads the store before each lookup (not for a request with claims)
  and reads, merges and writes it after each token response, in MSAL's
  shared cache schema under MSAL's partition hints
  (`<client>_<tenant>_AppTokenCache` for an app; the account's home id
  for a user), so other MSAL programs read the same cache. Lookups
  match entries by their fields as MSAL does (environment aliases from
  instance metadata), access tokens are written only when good for 5
  minutes or more, and entries this module doesn't write are kept.
  The user flows store refresh tokens, ID tokens and the account, so
  an AuthenticationRecord signs the user in silently in a new process.
  `Options` and the credentials Go gives `Cache` take an effect
  parameter for the store's effects (`[()]` for none). Decision 0012's
  text is corrected: the store sits at the credential, not on
  `runtime.TokenCache`.
- UsernamePasswordCredential (gap item 17, decision 0003 Amendment 2),
  deprecated as Go's is (it can't support multifactor authentication;
  https://aka.ms/azsdk/identity/mfa), as azidentity v1.15.0 runs it
  through MSAL Go v1.10.1's AcquireTokenByUsernamePassword: the silent
  request first, then `GET <host>/common/UserRealm/<user>?api-version=1.0`
  (read as MSAL's JSON decoder reads it: a token at a time, an empty
  body an empty realm, exact field names, then MSAL's checks of the
  realm). A `Managed` account posts `grant_type=password` with
  `username` and `password`. A `Federated` one GETs the mex document,
  takes its WS-Trust username endpoint as MSAL's NewFromDef does (the
  policies with a transport binding and a user name token, their SOAP
  over HTTP bindings, the ports' addresses, a 1.3 endpoint over a 2005
  one), POSTs the WS-Trust 1.3 request as Go's xml.Marshal writes it
  (`SOAPAction`, a ten minute timestamp, two fresh UUIDs, the user name
  and password escaped as Go's EscapeText), and posts the response's
  SAML assertion (the raw content of its RequestedSecurityToken, base64)
  with `grant_type` `urn:ietf:params:oauth:grant-type:saml1_1-bearer` or
  `saml2-bearer` by the assertion's `xmlns:saml`. The XML is read as Go's
  encoding/xml Unmarshal reads MSAL's structs (local names in any
  namespace, the last attribute of a name, nothing after the root
  element). MSAL's errors are kept: "problem getting user realm from
  authority", "problem getting mex doc from federated url(...)",
  "problem getting SAML token info", "unknown account type", and a
  response that is not 200 or 201 as azidentity's authentication failed
  error. Checked line for line against a Go program over a fake token
  host and a fake WS-Trust host (`upvectors_test.xo`, 50 sections).
- The ADFS authority: tenant `adfs` reads the OpenID configuration at
  `https://<host>/adfs/.well-known/openid-configuration`, with no instance
  discovery, as MSAL does, for every credential.
- InteractiveBrowserCredential (gap item 16, decision 0003 Amendment 2),
  as azidentity v1.15.0 runs it through MSAL Go v1.10.1's
  AcquireTokenInteractive: the silent request first, then a PKCE
  verifier (32 random bytes, S256 challenge), a listener on
  `localhost` (the port of `redirect_url`, else a free one), and the
  authorize URL (`response_mode=form_post`, `prompt=select_account`,
  `login_hint`, the claims, `state`) handed to the caller's `open_url`,
  which is required: the module never starts a process
  (`interactive_example_test.xo` shows a caller passing the system's
  opener). The listener answers the first whole request as MSAL's
  local.Server does: a GET is refused (405), `error` gives the escaped
  `error_description` as the error, a missing or wrong `state` and a
  missing `code` are 500s with MSAL's texts; a connection that sends
  nothing is skipped. Then `grant_type=authorization_code` with the
  code, `code_verifier` and `redirect_uri`. `authenticate`, the
  AuthenticationRecord and `disable_automatic_authentication` are the
  device code credential's. Checked line for line against a Go program
  whose browser is a scratch hook passing MSAL's WithOpenURL
  (`interactivevectors_test.xo`).
- DeviceCodeCredential and the public client account model (gap items 15
  and 18, decision 0003 Amendment 2), as azidentity v1.15.0 makes them
  through MSAL Go v1.10.1: the silent request first (the cached access
  token, not with claims; then `grant_type=refresh_token` for the
  account), then `POST .../oauth2/v2.0/devicecode` (the token endpoint
  with `token` replaced, as MSAL derives it), the caller's prompt, and
  `grant_type=device_code` polls. As MSAL's, the polls wait 50 ms, then
  three times longer each time up to 5 s, whatever the service's
  `interval`; `authorization_pending` and `slow_down` go on; the code's
  `expires_in` is the deadline ("context deadline exceeded"); another
  400 is azidentity's error with no body, as MSAL read it. A token
  response must grant every requested scope ("declined scopes are
  present"). The account (`AuthenticationRecord`, Go's JSON and version
  check) comes from `client_info` and the ID token; refresh tokens are
  kept per account and per CAE client in memory. `authenticate` runs the
  flow once with no silent request (the cloud's Resource Manager scope
  when none is given); `disable_automatic_authentication` turns a failed
  silent request into an AuthenticationRequired error (`AuthErr.required`
  with the request's options, `unavailable` so a chain goes on). Unlike
  Go's, the prompt is a required parameter: printing is the caller's
  effect. Checked against a Go program's 136 lines over a fake token
  host (`devicecodevectors_test.xo`, nine sections).
- Service Fabric managed identity (gap item 5), as MSAL Go v1.10.1's:
  chosen when IDENTITY_ENDPOINT, IDENTITY_HEADER and
  IDENTITY_SERVER_THUMBPRINT are set. The thumbprint (colons and white
  space ignored, 40 hex digits) pins the endpoint's certificate: the
  SHA-1 of the server's leaf is compared in constant time on every new
  connection (`sf_verify`, std/http's `with_verify_conn`), and a
  redirect is refused. The endpoint must be https with a host; a
  user-assigned identity is refused. The request is a GET with
  `api-version=2019-07-01-preview` and `resource` set over the
  endpoint's own query, `Accept: application/json` and `Secret`. Go's
  errors and order. Checked against a Go program's requests to a local
  TLS endpoint (`sfvectors_test.xo`). As Go's, the chain and name
  checks are off for the self signed certificate (`tls.Verify.None`,
  Go's InsecureSkipVerify), set only together with the pin; std/http
  refuses a Verify.None client without one. A loopback TLS test
  (`sf_tls_test.xo`, `xo test --real --run=loopback`,
  `scripts/integration-loopback.sh`) shows the right pin accepted, a
  wrong one failing before any request byte, and Verify.None without
  the pin refused. Needs xo d6f52c2d9 or later (`Client.with_verify`,
  `TlsOptions.verify`).
- Workload identity's Azure Kubernetes token proxy (gap item 10), as
  azidentity's internal/customtokenproxy: with
  `WorkloadIdentityOptions.enable_azure_proxy`, every request goes to
  AZURE_KUBERNETES_TOKEN_PROXY (an https URL with no user, query or
  fragment; its path joined before the request's, the query kept), with
  the authority's host as the request's Host, AZURE_KUBERNETES_SNI_NAME
  as the TLS server name (std/http's `with_server_name` and
  `Request.with_host`, decision 0541), and the CA of
  AZURE_KUBERNETES_CA_FILE (read again before each token request, the
  client rebuilt when its bytes change, an empty file keeping the last)
  or AZURE_KUBERNETES_CA_DATA. Go's errors for the settings, in Go's
  order. Checked against a Go program's requests through a local TLS
  proxy (`proxyvectors_test.xo`); FakeNet does no TLS, so the server
  name is checked on the proxy's client.
- AzurePipelinesCredential (gap item 14), as azidentity's:
  `new_azure_pipelines_credential(tenant_id, client_id,
  service_connection_id, system_access_token, env, ...)`, reading
  SYSTEM_OIDCREQUESTURI, with Go's errors in Go's order. A token request
  that misses the cache POSTs to the OIDC endpoint with the system
  access token and sends its `oidcToken` as the client assertion. An
  error response is an AuthenticationFailedError naming the status and
  any `x-msedge-ref` and `x-vss-e2eid` headers. The URL is built as Go
  builds it: the connection ID is appended unescaped and the query is
  then parsed and encoded again, so `&` or `=` in it adds parameters.
  Checked against 22 Go cases (`pipelinesvectors_test.xo`).
- OnBehalfOfCredential (gap item 13), as azidentity's with MSAL Go's
  AcquireTokenOnBehalfOf: `new_on_behalf_of_credential_with_secret`,
  `_with_certificate` and `_with_client_assertions`, with
  `OnBehalfOfOptions` (`opts`, `send_chain`). The request is MSAL's JWT
  bearer grant (`assertion`, `requested_token_use=on_behalf_of`,
  `client_info=1`). A refresh token in the response is kept (CAE's
  apart) and redeemed for a later request that misses the cache, for any
  scope or tenant and with claims; if that fails, the on-behalf-of grant
  is asked instead and the error is dropped. An empty user assertion is
  a client credentials request, as in Go. Checked against 4 Go sections
  (`obovectors_test.xo`). Go's nil callback error cannot happen in Xo.
- ChainedTokenCredential's `retry_sources` (Go's RetrySources, gap item
  8): every call starts from the first source again instead of keeping
  the one that worked. **Breaking**: `new_chained_token_credential`
  returns `! azcore.AuthErr`, Go's `sources must contain at least one
  TokenCredential` for an empty list (Go's other error, a nil source,
  cannot happen in Xo).
- `new_workload_identity_credential_from_env` and
  `WorkloadIdentityOptions` (gap item 9): an empty `client_id`,
  `token_file_path` or `tenant_id` comes from AZURE_CLIENT_ID,
  AZURE_FEDERATED_TOKEN_FILE or AZURE_TENANT_ID, checked in that order
  with Go's errors (`no client ID specified. Check pod configuration or
  set ClientID in the options`, then the token file, then the tenant
  ID). A variable set but empty counts as set, as Go's os.LookupEnv.
  DefaultAzureCredential builds its workload identity with it. The
  three-argument `new_workload_identity_credential` stays.
- DefaultAzureCredential's selection, options and errors are Go's (gap
  item 7; 23 Go cases in `dacvectors_test.xo`):
  - `AZURE_TOKEN_CREDENTIALS`: `prod`, or one source's name in any case;
    unset keeps all three. Any other value is Go's error (`invalid
    AZURE_TOKEN_CREDENTIALS value "x". Valid values are ...`), including
    `""`, `PROD` and ` prod`. `dev` and the developer tools' names, which
    Go accepts, are refused with a message saying this SDK does not
    include them.
  - **Breaking**: it takes `DefaultAzureCredentialOptions` (`client`,
    `additionally_allowed_tenants`, `disable_instance_discovery`,
    `require_azure_token_credentials`, `tenant_id`). The options'
    tenants replace AZURE_ADDITIONALLY_ALLOWED_TENANTS instead of adding
    to it. `tenant_id` is the workload identity's tenant.
  - A source that cannot be built stays in the chain as unavailable,
    with Go's reason: `missing environment variable AZURE_TENANT_ID`
    (then AZURE_CLIENT_ID), `incomplete environment variable
    configuration. Only AZURE_TENANT_ID and AZURE_CLIENT_ID are set`,
    `no client ID specified. Check pod configuration or set ClientID in
    the options` (then the token file, then the tenant ID, each read as
    set even when empty), `empty managedidentity.UserAssignedClientID`.
  - IMDS is probed whenever another source is in the chain (before: only
    with AZURE_TOKEN_CREDENTIALS unset).
- ChainedTokenCredential's error is Go's: `<name>: failed to acquire a
  token.` then `Attempted credentials:`, each source's error on a tab
  with its own lines on two. It is unavailable when the last error is,
  else an AuthenticationFailedError without the response block.
- **Breaking**: WorkloadIdentityCredential reads its token file when a
  token is asked for, after the endpoint lookup, and again 10 minutes
  after each read, as Go's. It is a `TokenCredential[fs.read]`; its
  constructor no longer reads the file, and `watch` is gone. The file's
  text is sent as it is (before: trimmed). A missing file is
  `WorkloadIdentityCredential: open <path>: no such file or directory`.
- **Breaking**: `new_managed_identity_credential` returns a Result: an
  empty user-assigned ID is MSAL Go's `empty
  managedidentity.UserAssignedClientID` (or ObjectID, ResourceID).
- EnvironmentCredential's own errors are Go's texts (above). The
  options' additionally allowed tenants replace the environment's.

- ManagedIdentityCredential supports Azure Arc (gap item 11; decision
  0009). It is selected after App Service, Azure ML and Cloud Shell, when
  `IDENTITY_ENDPOINT` and `IMDS_ENDPOINT` are set or the agent's himds
  file exists. The credential then makes MSAL Go's two requests: a `GET`
  of `IDENTITY_ENDPOINT` (else `http://127.0.0.1:40342/...`, keeping the
  endpoint's own query) with `api-version=2020-06-01`, answered 401 with
  `WWW-Authenticate: Basic realm=<path>`; then the same request with
  `Authorization: Basic <key>`. The key file must be a `.key` file
  directly in the token directory (`/var/opt/azcmagent/tokens`, or
  `%ProgramData%\AzureConnectedMachineAgent\Tokens` joined as Go's
  filepath on Windows) and at most 4096 bytes. Each failure is MSAL Go's
  text. A user-assigned identity must be confirmed in the token response
  (`client_id`, `object_id`, or `msi_res_id` then `mi_res_id`, compared
  ignoring case), as in MSAL Go v1.10.1. The 49 Go cases are in
  `arcvectors_test.xo`.
- **Breaking**: `new_managed_identity_credential` takes an `Fs` after
  `env`, and the credential is a `TokenCredential[fs.read]` (it may read
  Arc's key file). `DefaultAzureCredential` is a
  `ChainedTokenCredential[fs.read]`. `ChainedTokenCredential[fx]` is as
  effectful as its sources, and a chain without managed identity stays
  `[()]`. New options `arc_token_dir` and `arc_himds` replace the
  platform's paths (tests point them at MemFs).
- Differs from Go on purpose: outside Windows, a key path with a `..`
  element is refused (`invalid file path, expected a file in <dir> named
  without .., got <path>`); when the directory before `..` is missing,
  the error is Go's stat error. Not ported: Go's `couldn't parse` error
  for an IDENTITY_ENDPOINT that is not a URL (here the text before `?`
  is the base), and the text
  of OS errors on Windows (they are the Linux ones).

- ManagedIdentityCredential inside DefaultAzureCredential probes IMDS
  first, as Go: a `GET` of the token endpoint with no query and no
  `Metadata` header, 1 s, no retries. Any answer ends the probing; a
  timeout is unavailable (`managed identity timed out. See
  https://aka.ms/azsdk/go/identity/troubleshoot#dac for more
  information`), another failure unavailable with its text, and either
  probes again on the next call. The token request then has the normal
  retries.
- Managed identity errors are Go's: an IMDS 400 for a user-assigned
  identity is the AuthenticationFailedError block opened by `the
  requested identity isn't assigned to this resource`; for the system
  identity it is unavailable (`failed to authenticate a system assigned
  identity. The endpoint responded with <body>`); a 403 that says
  `unreachable` is unavailable (`unexpected response "<body>"`, Docker
  Desktop's proxy); other statuses are the AuthenticationFailedError
  block, and a transport error is `ManagedIdentityCredential: <err>. To
  troubleshoot, visit ...#managed-id`.
- **Behavior change**: a managed identity token response is read as
  MSAL Go reads it: `expires_on` (Unix seconds as a number or string,
  or `01/02/2006 15:04:05`, `2006-01-02 15:04:05` or RFC 3339 in UTC)
  wins over `expires_in`; `expires_in` and `refresh_in` are the value's
  JSON text through strconv.Atoi (`"3600"` and `3600`, not `3600.5` or
  `1e3`), with Go's `unix time(...) could not be converted ...` error;
  names match without case and the last of a name wins. Without
  `refresh_in` a token living over 2 hours refreshes at half its life.
  A response with no `access_token` gives an empty token, which is not
  cached (before: an error). A body that is not JSON, a bad value, or no
  expiry is `error parsing the json error: ...`; under
  DefaultAzureCredential, from IMDS, it is unavailable (something else
  answers there), else the AuthenticationFailedError.
- **Behavior change**: the managed identity request's query is sorted
  by name, as MSAL Go encodes it, and Azure ML sends `clientid=` empty
  for the system identity.
- Differences: Go marks a credential as chained by its type
  (DefaultAzureCredential and ChainedTokenCredential); Xo has no
  downcast, so DefaultAzureCredential sets the new
  `ManagedIdentityOptions.chained`, and a ManagedIdentityCredential put
  in `new_chained_token_credential` by hand gets the standalone texts
  unless `chained` is set. The aggregate error's own text is item (7).

- `parse_certificates(data, password = "")` is Go's ParseCertificates:
  a PEM file, or a PKCS #12 file (`.pfx`) opened with `password`
  through std's `x509.parse_pkcs12` (3DES and 40 bit RC2, as Go's
  golang.org/x/crypto/pkcs12; an AES file is refused by both). PEM keys
  follow Go: `PRIVATE KEY` (PKCS #8, else PKCS #1) and `RSA PRIVATE KEY`
  blocks, `EC PRIVATE KEY` blocks skipped, two keys an error. Its
  errors are Go's texts (`found no certificate`, `certData contains
  multiple private keys`, `pkcs12: decryption password incorrect`, ...).
  EnvironmentCredential reads `AZURE_CLIENT_CERTIFICATE_PASSWORD` and
  reports Go's `failed to parse "<path>" due to error ...`.
- **Behavior change**: `new_client_certificate_credential` signs with
  the certificate whose public key is the private key's, wherever it is
  in the list, and `x5c` lists it first, then the others in order (MSAL
  Go's NewCredFromCert). Before, the first certificate signed. A
  non-RSA key, no certificate, or no certificate for the key is Go's
  error.
- **Behavior change**: `x5t#S256` is standard base64 with padding, as
  MSAL Go v1.10.1 writes it (base64url without padding before).
- Differences: a PKCS #12 file's certificates come back with the key's
  certificate first, then the rest in file order (Go: file order; the
  credential picks the same certificate either way). A malformed file's
  error is `pkcs12: error reading P12 data: malformed PFX` where Go
  prints encoding/asn1's detail.
- `ClientAssertionCredential` (`new_client_assertion_credential`), Go's:
  the assertion comes from a callback, which runs only when no cached
  token fits and after the tenant's endpoint is resolved. Its error is
  the credential's AuthenticationFailedError
  (`ClientAssertionCredential: <msg>`, no troubleshooting link). The
  callback may use the network (`uses (net.dial, clock, rand)`, as
  `get_token`); a callback that reads a file reads it outside, since a
  credential's `get_token` has no file effect. Go's error for a nil
  callback has no counterpart (an Xo function value is never nil).
- **Behavior change**: the token endpoint is found as MSAL Go finds it.
  Before a credential's first token request for a host, it asks for the
  host's instance metadata (`GET
  https://login.microsoftonline.com/common/discovery/instance?api-version=1.1&authorization_endpoint=...`,
  at the authority itself for a host MSAL trusts); a failure there is
  ignored. Once per tenant it reads the tenant's OpenID configuration
  (from the discovery reply's `tenant_discovery_endpoint` for a host
  MSAL does not trust, else
  `<authority><tenant>/v2.0/.well-known/openid-configuration`), checks
  that it names the authorize and token endpoints and an issuer that
  matches the authority (the same host, an alias from discovery, a host
  MSAL trusts, or a regional host under the issuer's), and posts to its
  `token_endpoint`. CAE and plain requests keep separate lookups, as
  Go's two MSAL clients do. A failed lookup is Go's error (`unable to
  resolve an endpoint: ...`, or the response block).
- `Options.disable_instance_discovery` skips the instance metadata (Go's
  `DisableInstanceDiscovery`), for a private or disconnected cloud.
- `azcore.AuthErr` gains `failed`: true for what Go returns as an
  AuthenticationFailedError (the token request or the endpoint lookup
  failed, with or without a response).
- Not sent, unlike Go: the empty `?` Go puts after the OpenID
  configuration's URL (Xo's URL has no empty query) and MSAL's
  `x-client-*` library headers.

- **Behavior change**: the token request is MSAL Go's. The scopes are
  followed by `openid offline_access profile`, an assertion grant adds
  `client_info=1`, the form's keys are sorted, the content type is
  `application/x-www-form-urlencoded; charset=utf-8`, and the headers
  `client-request-id` (a UUID) and `return-client-request-id: false`
  are sent.
- **Behavior change**: errors print Go's text. An error response from
  the token endpoint is azidentity's AuthenticationFailedError: the
  request line, `RESPONSE <code>: <code> <status text>`, the body
  indented, and the troubleshooting link for the credential. The new
  `AuthErr.status` holds the response's status. A tenant that is not
  allowed, a malformed tenant ID and an empty client secret have Go's
  sentences. `azcore.AuthErr` gains `text` (the whole text, when it is
  not `<credential>: <msg>`) and `status`.
- An empty client ID is accepted when the credential is built, as Go's
  credentials accept it (the token endpoint rejects it).

Not yet: managed identity's error texts and the rest of the gap list.
