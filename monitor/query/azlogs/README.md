# azlogs (query)

Azure Monitor Logs queries for Xo, a port of Go's
`sdk/monitor/query/azlogs` v1.2.0 (Log Analytics REST API v1): Kusto
queries against workspaces and Azure resources.

What it does:

- `new_client(net, clock, rand, cred, opts)`: the endpoint and token
  audience come from the cloud (`https://api.loganalytics.io` and its
  China and Government hosts built in; another cloud needs a
  `SERVICE_NAME` entry with both fields, or it is Go's error).
- `query_workspace`, `query_resource` and `query_batch`, with
  `QueryOptions` for the `Prefer` header (statistics, visualization,
  server timeout). Only a 200 succeeds. A partial failure is a result
  whose `error` is set; in a batch each answer has its own status.
- `QueryResults`: tables with their columns and rows (each cell a
  `json.Value`), the `statistics` and `render` JSON as sent, and
  `ErrorInfo` (its code; it displays as the whole error JSON, as Go's).
- `TimeInterval`: `new_time_interval`, `new_time_interval_in` and
  `values`, with Go's errors.

Each request is Go's byte for byte: the test replays a Go program's
calls against the same fake service and compares the method, URL,
headers and body of each request, and what is read back.

Where it differs from Go v1.2.0:

- A row's integers keep every digit. Go decodes a row into `[]any`, so
  a `long` of `9007199254740993` reads as `9007199254740992`.
- `values()` gives each time in UTC (Xo's `Time` is an instant, with no
  zone); `new_time_interval_in` writes each time in a zone, as Go's
  `NewTimeInterval` writes each time's own offset.
- An empty `additional_workspaces` or batch `headers` is left out of
  the body; Go writes `[]` or `{}` for a non-nil empty one. A null
  header value in a batch answer is left out.
- A decode error is `azcore.CallErr.Decode` with Xo's reader's text.
- Every request has an `x-ms-client-request-id` (decision 0003).

Kept as Go has it: `query_resource` puts the resource ID in the path
as it is, without escaping or checking it (an empty ID queries
`/v1/query`).
