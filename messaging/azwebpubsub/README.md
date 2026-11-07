# azwebpubsub

Azure Web PubSub's service client, for Xo: a port of Go's
`sdk/messaging/azwebpubsub` v0.1.1 (REST API version 2023-07-01).

- `new_client(net, clock, rand, endpoint, credential)`: Entra ID tokens
  for `https://webpubsub.azure.com/.default`.
- `new_client_from_connection_string(net, clock, rand, s)`:
  `Endpoint=...;AccessKey=...;` read with Go's rules (keys in any case,
  trailing `;` dropped, `Port` replacing the endpoint's port, a `/`
  added). Each try is signed with the access key: a JSON Web Token
  (HS256) for the request's URL that expires in an hour, as Go's.
- The 18 operations: send to all, a connection, a group or a user;
  add and remove connections and users to and from groups; close
  connections; grant and revoke permissions. Go's private ones
  (`checkPermission`, the `...Exists` calls, `generateClientToken`) are
  `raw_...` and not public, as in Go.
- `generate_client_access_url(hub, options)`: the WebSocket URL a client
  connects to and its token: signed with the access key (user, roles,
  groups and expiry as Go's claims), or issued by the service for a
  token credential's client.

The operations and models are generated from the 2023-07-01 OpenAPI
file at Go's autorest.md commit, with its directives
(`codegen/custom/azwebpubsub.toml`). The constructors, the key's
policy, the access URL and the test are written by hand.

The test runs every public call through a Go program built against
azwebpubsub v0.1.1 with a fake transport and compares each request
(method, URL, headers, body, and each token's header, claims and
signature) and result, including connection string cases, the access
URL's options and error responses; it also checks two tokens byte for
byte against golang-jwt's.

Where it differs from Go v0.1.1:

- `generate_client_access_url` takes its options by value: with the
  defaults, a token credential's client asks the service, where Go's
  dereferences a nil options and panics. A service response without a
  token is an error, where Go's panics.
- A request to an endpoint without a scheme (`wps.example.test`) fails
  in Xo's HTTP client's words; Go's fails with `no Host in request URL`.
- A bearer token over plain HTTP is refused with runtime's message; a
  response body that is not JSON is reported with Xo's JSON error.
- The connection string's endpoint is read as Go's url.Parse reads it,
  with azblob's Go URL reader: its user info and fragment are dropped.
- Go's int32 options (`message_ttl_seconds`, minutes to expire) are
  `Int`.
