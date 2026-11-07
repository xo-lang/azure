# azsystemevents

The Azure system events delivered through Event Grid, for Xo: a port of
Go's `sdk/messaging/eventgrid/azsystemevents` v1.1.0. It has no client:
it is the types an event's `data` decodes into.

- 270 models and 34 enums, one data type per system event
  (`StorageBlobCreatedEventData`, `ACSMessageReceivedEventData`, ...),
  with Go's names and fields, times as `azcore.DateTimeUTC`.
- `system_events.xo`: Go's 206 event type constants
  (`TYPE_STORAGE_BLOB_CREATED` is Go's `TypeStorageBlobCreated`), each
  documented with its data type.
- `EventGridEvent`: an event in the Event Grid schema, its `data` kept
  as the JSON text received, as Go's. `decode_event` and
  `decode_events` (a delivery's list) keep that text byte for byte;
  `derive Json` keeps it compacted. Writing an event writes `data`
  base64, as Go writes its `[]byte`.
- `ErrorModel` (Go's `Error`): the error an ACS message's `error` and a
  router job's `errors` carry, with Go's code and message: a router
  error's details and inner errors folded into the message, indented,
  as Go's.

The models and constants are generated from the 2024-01-01 OpenAPI
file that EventGridSystemEvents' TypeSpec emits, at Go's tsp-location
commit, with the TypeSpec's Go renames and every definition kept
(`codegen/custom/azsystemevents.toml`). The event, the error and the
test are written by hand.

The test runs every case through a Go program built against
azsystemevents v1.1.0 and compares each output: each of the spec's
2024-01-01 examples (ids, hosts, addresses and resource names
replaced) as its event type's data and as an Event Grid event, and
cases written by hand for the errors and the event. It also checks
each of Go's type constants.

Where it differs from Go v1.1.0:

- A map is written in the order its keys were read (Xo's json writes a
  `Map` and a `json.Value` object in insertion order); Go's
  encoding/json writes a map's keys sorted.
- Go's float32 fields are `Float`, and its int32 fields `Int`: a float
  is kept at full precision.
- Go's `Error` is `ErrorModel` (`Error` is Xo's prelude type); its
  internal error types are the module's own.
- One decoder reads both error shapes: an object with `channelCode` or
  `channelMessage` is a channel error, any other a router error. A
  `null` ACS message error is None, where Go's decode panics; an empty
  `errors` list is kept and written, where Go's is nil and left out.
- `EventGridEvent.data` is `Bytes?` (Go's `any`, set to the received
  text); an event with other data is built with its JSON text.
