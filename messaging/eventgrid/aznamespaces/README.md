# aznamespaces

Azure Event Grid Namespaces' sender and receiver clients, for Xo: a port
of Go's `sdk/messaging/eventgrid/aznamespaces` v1.0.0 (REST API version
2024-06-01).

What it does:

- `new_sender_client(net, clock, rand, endpoint, topic, cred, options)`
  and `new_receiver_client(net, clock, rand, endpoint, topic,
  subscription, cred, options)` with Entra ID tokens (scope
  `https://eventgrid.azure.net/.default`), and the
  `..._with_shared_key_credential` constructors (the namespace's access
  key as `Authorization: SharedAccessKey <key>`, an
  `azcore.KeyCredential`). Updating the key changes the next request's
  header. A key is sent only over HTTPS.
- `SenderClient`: `send_event(event)` (`application/cloudevents+json`)
  and `send_events(events)` (`application/cloudevents-batch+json`),
  CloudEvents 1.0 (`azcore/messaging.CloudEvent`).
- `ReceiverClient`: `receive_events(options)` (`max_events`,
  `max_wait_time`), then `acknowledge_events`, `release_events`
  (`release_delay_in_seconds`, a `ReleaseDelay`), `reject_events` and
  `renew_event_locks` by lock token; each result lists the tokens that
  succeeded and those that failed, with their error.
- An empty topic or subscription is refused before any request, with
  Go's message. Only a 200 succeeds.

The test replays a Go program's calls against the same fake and
compares each request (method, URL, headers, body), the token scope
asked for and each result, line for line.

It is written by hand, as azeventgrid is: Go generates these clients
from TypeSpec and then rewrites them (models deleted, symbols renamed,
azcore's CloudEvent swapped in, the topic and subscription moved into
the client), so the port follows the released package rather than the
spec.

Where it differs from Go v1.0.0:

- Go's `Error` model is `ErrorModel` (`Error` is predeclared in Xo), and
  its `Error()` method is `display()`.
- A result's lists are never nil here: a missing list reads as `[]`.
- Every request has an `x-ms-client-request-id` (decision 0003).
