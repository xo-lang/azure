# azmetrics

Azure Monitor metrics queries for Xo, a port of Go's
`sdk/monitor/query/azmetrics` v1.3.0 (REST API version 2024-02-01): the
metrics of many resources in one region, with one `metrics:getBatch`
request.

What it does:

- `new_client(net, clock, rand, endpoint, cred, opts)` for a regional
  endpoint (`https://<region>.metrics.monitor.azure.com`), with an
  Entra ID token for the cloud's audience (the three Azure clouds built
  in; another cloud needs a `SERVICE_NAME` entry, or it is Go's error).
  `policy.ClientOptions.api_version` replaces the API version.
- `query_resources(subscription_id, metric_namespace, metric_names,
  resource_ids, options)`, with `QueryResourcesOptions` for the
  aggregation, time span, interval, filter, order, roll up and top. Only
  a 200 succeeds.
- The models (`MetricResults`, `MetricData`, `Metric`,
  `TimeSeriesElement`, `MetricValue`, `MetricUnit`), with Go's JSON
  names. A time stamp without an offset is UTC, as Go reads it.

Each request is Go's byte for byte: the test replays a Go program's
calls against the same fake service and compares the method, URL (the
query sorted, as Go's url.Values encodes it), headers and body of each
request, and what is read back.

Where it differs from Go v1.3.0:

- An empty `resource_ids` is left out of the body (`{}`); Go writes
  `[]` for a non-nil empty slice.
- A time stamp is written in UTC (Go keeps the offset it read).
- A decode error is `azcore.CallErr.Decode` with Xo's reader's text
  (Go's names each struct on the way down).
- Every request has an `x-ms-client-request-id` (decision 0003).
