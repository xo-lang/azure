# azidentity changes

Newest first. The module's Xo version is v0.1.0. It is moving to Go's
azidentity v1.15.0 (with MSAL Go v1.10.1) item by item, as listed in
`docs/reports/azidentity-v1.15.0-gaps.md`; each change is checked against
the lines a Go program prints with v1.15.0 (`govectors_test.xo`).

## Unreleased

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

Not yet: instance discovery and the tenant's OpenID metadata (the lead
asked for both, next), managed identity's error texts, and the rest of
the gap list.
