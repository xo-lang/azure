# azqueue changes

## Unreleased

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
