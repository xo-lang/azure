# azidentity changes

Newest first. The module's Xo version is v0.1.0. It is moving to Go's
azidentity v1.15.0 (with MSAL Go v1.10.1) item by item, as listed in
`docs/reports/azidentity-v1.15.0-gaps.md`; each change is checked against
the lines a Go program prints with v1.15.0 (`govectors_test.xo`).

## Unreleased

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
