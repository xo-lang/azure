# azquery

Azure Monitor queries for Xo, a port of Go's `sdk/monitor/azquery`
v1.2.0: Kusto queries against Log Analytics (REST API v1), and one Azure
resource's metrics, metric definitions and metric namespaces through
Azure Resource Manager (API version 2024-02-01). Go's newer modules
split these: `monitor/query/azlogs` for logs and `monitor/query/azmetrics`
for metrics over many resources, both ported here too.

What it does:

- `new_logs_client(net, clock, rand, cred, opts)` and
  `new_metrics_client(...)`: the endpoint and token audience come from
  the cloud's `SERVICE_NAME_LOGS` (`azqueryLogs`) and
  `SERVICE_NAME_METRICS` (`azqueryMetrics`) entries, built in for
  Azure's three clouds as Go's `cloud_config.go` adds them. Another
  cloud without an entry, or with an empty field, is Go's error.
- `LogsClient`: `query_workspace`, `query_resource` and `query_batch`,
  with `LogsQueryOptions` for the `Prefer` header, and
  `new_batch_query_request` as Go's `NewBatchQueryRequest`. A partial
  failure is a result whose `error` is set; in a batch each answer has
  its own status.
- `MetricsClient`: `query_resource` with every Go option,
  `new_list_definitions_pager` and `new_list_namespaces_pager` (one page
  each, as Go's). `policy.ClientOptions.api_version` replaces the API
  version, as in Go.
- `TimeInterval`: `new_time_interval`, `new_time_interval_in` and
  `values`, with Go's errors.

Each request is Go's byte for byte: the test replays a Go program's
calls against the same fake service and compares the method, URL,
headers and body of each request, and what is read back.

Where it differs from Go v1.2.0:

- A row's integers keep every digit. Go decodes a row into `[]any`, so
  a `long` of `9007199254740993` reads as `9007199254740992`.
- A decoding error names the JSON path (`at $.value[0]...`) where Go's
  names each struct on the way down.
