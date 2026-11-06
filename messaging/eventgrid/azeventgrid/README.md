# azeventgrid

Azure Event Grid's publisher client for basic topics, for Xo: a port of
Go's `sdk/messaging/eventgrid/azeventgrid` v1.0.0 (REST API version
2018-01-01).

What it does:

- `new_client(net, clock, rand, endpoint, cred, options)` with Entra ID
  tokens (scope `https://eventgrid.azure.net/.default`),
  `new_client_with_shared_key_credential` (the topic's access key in
  `aeg-sas-key`, an `azcore.KeyCredential`) and `new_client_with_sas`
  (a signature in `aeg-sas-token`, an `azcore.SASCredential`). Updating
  the credential changes the next request's header. A key or signature
  is sent only over HTTPS.
- `publish_cloud_events(events, options)`: CloudEvents 1.0
  (`azcore/messaging.CloudEvent`), with an optional partner channel
  (`aeg-channel-name`).
- `publish_events(events)`: the Event Grid schema (`Event`).
- `publish_custom_event_events(events)`: any JSON values.
- Only a 200 succeeds.

The test replays a Go program's calls against the same fake and
compares each request (method, URL, headers, body), the token scope
asked for and each result, line for line.

Where it differs from Go v1.0.0:

- A list is never nil here, so an empty list is sent as `[]` (Go sends
  `null` for a nil slice).
- An `Event`'s `data` and a custom event are `json.Value`s: an object
  is written in its fields' order (Go sorts a map's keys).
- Every request has an `x-ms-client-request-id` (decision 0003).
