# azlogs (ingestion)

Azure Monitor Logs ingestion for Xo, a port of Go's
`sdk/monitor/ingestion/azlogs` v1.1.0 (REST API version 2023-01-01):
upload custom logs to a data collection endpoint through the Logs
Ingestion API.

What it does:

- `new_client(net, clock, rand, endpoint, cred, opts)` for a data
  collection endpoint, with an Entra ID token for the cloud's audience
  (`https://monitor.azure.com/` and its China and Government forms built
  in; another cloud needs a `SERVICE_NAME` entry in
  `cloud.Configuration.services`, or it is Go's error).
- `upload(rule_id, stream_name, logs, options)`: `logs` is the JSON
  array of records as bytes, gzipped with
  `UploadOptions{content_encoding: Some("gzip")}`. Only a 204 succeeds;
  anything else is the response error, as Go's.

Each request is Go's byte for byte: the test replays a Go program's
calls against the same fake endpoint and compares the method, URL,
headers and body of each request, and each result.

Where it differs from Go v1.1.0:

- Every request has an `x-ms-client-request-id`, as the Xo pipeline
  sets one (decision 0003); Go's azcore sets none here.
- The empty-parameter errors are `azcore.CallErr.InvalidInput` with
  Go's text (`parameter ruleID cannot be empty`).

Kept as Go has it: the token scope is the audience with `/.default`
appended, so the public cloud's scope is
`https://monitor.azure.com//.default`, with two slashes.
