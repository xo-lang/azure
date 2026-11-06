# azqueue changes

## Unreleased

The storage challenge policy, at Go azqueue v1.0.1 parity on captured
vectors.

- `new_queue_client` answers a 401 bearer challenge naming a
  `resource_id` with a token for that resource, kept for later calls,
  and asks for `ClientOptions.audience`'s scope (new), as Go's
  NewQueueClient. `ClientOptions.insecure_allow_credential_with_http`
  (new) sends tokens over plain http to local fakes and emulators.
- `new_service_client` keeps Storage's scope and no challenge
  handling, as Go.

Responses and errors, at Go azqueue v1.0.1 parity on captured vectors.

- A response's Date, a message's times, an access policy's times, the
  approximate message count and an update's next-visible time that do
  not parse fail the call, as Go's generated handlers do, with Go's
  error text; XML decode errors name Go's type.
- `ListQueuesSegmentResponse.response`: each list page's request ID,
  version and date.

## v0.1.0

The service and queue clients, messages, SAS, connection strings and
queueerror, requests byte for byte with Go azqueue v1.0.1's.
