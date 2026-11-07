# azidentity changes

Newest first. The module's Xo version is v0.1.0. It is moving to Go's
azidentity v1.15.0 (with MSAL Go v1.10.1) item by item, as listed in
`docs/reports/azidentity-v1.15.0-gaps.md`; each change is checked against
the lines a Go program prints with v1.15.0 (`govectors_test.xo`).

## Unreleased

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
