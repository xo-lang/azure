# azqueue

Azure Queue Storage for Xo, a port of Go's `sdk/storage/azqueue` v1.0.1
(REST API version 2024-08-04).

What it does:

- `ServiceClient` and `QueueClient`, with Entra ID tokens, the account
  key (azblob's `SharedKeyCredential` and policy), no credential (a SAS
  in the URL), or a connection string (`AccountName` with
  `DefaultEndpointsProtocol` and `EndpointSuffix`, or `QueueEndpoint`;
  `AccountKey` or `SharedAccessSignature`).
- The service's properties (logging, hour and minute metrics, CORS),
  statistics, the queue list pager, and creating and deleting queues.
- A queue's create, delete, metadata, properties (with the approximate
  message count) and stored access policies.
- Messages: enqueue (time to live, visibility timeout), dequeue one or
  many, update, delete, peek one or many, clear.
- `sas`: account SAS for the Queue service and queue SAS, and
  `get_sas_url` on both clients. `parse_url` splits a queue URL (an IP
  host's first segment is the account, as Azurite's).
- `queueerror`: the error codes and `has_code`.

Each request is Go's byte for byte: the test replays a Go program's
calls against the same fake service and compares every request
(method, URL, headers with the Shared Key signature, body) and what is
read back.

Where it differs from Go v1.0.1:

- Times are instants. Go's SAS code writes a start or expiry that is
  not in UTC in its own zone with a `Z` appended (it signs
  `01:02:03Z` for `00:02:03Z` given in UTC+1); here every SAS time is
  UTC. `get_sas_url` converts to UTC in Go too, so its URLs match.
- A caller's `x-ms-date` is kept. Go's signer looks the header up by its
  lowercase name in a canonicalized header map, so it never sees one and
  always signs its own clock's date.
- Options are Xo's: optional values are `T?` with `None` for Go's nil,
  permissions and resource types are letter strings (`"raup"`), and
  service properties come back in `.properties` rather than embedded.
- Response metadata names stay as the service sent them (Go
  canonicalizes them: `Color`).
- Bearer tokens use azcore's bearer token policy with the Storage scope;
  Go's storage challenge policy (a tenant from a 401 challenge) is not
  ported yet.
