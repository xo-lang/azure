# azbatch

Azure Batch's data plane client, for Xo: a port of Go's
`sdk/batch/azbatch` v0.1.0 (REST API version 2024-07-01.20.0).

- `new_client(net, clock, rand, endpoint, credential, options)`: Entra
  ID tokens for `https://batch.core.windows.net//.default` (Go's
  scope, double slash included). `insecure_allow_credential_with_http`
  allows a token over plain HTTP, as Go's option does.
- The 76 public operations of Go's `Client`: applications, pools,
  nodes, node extensions and files, jobs, job schedules, tasks and task
  files, certificates and supported images, with Go's names, options
  and response headers (`client_request_id`, `etag`, `last_modified`,
  `ocp_batch_file_is_directory`, ...). List operations are pagers
  (`new_list_jobs_pager`, ...). Go's internal `listPoolUsageMetrics`
  is `raw_list_pool_usage_metrics` and not public, as in Go.
- File downloads (`get_node_file`, `get_task_file`) return the bytes
  in `body`, with the media type in `content_type`.

Everything is generated from the TypeSpec's 2024-07-01.20.0 OpenAPI
file at Go's tsp-location commit, with Go's `@clientName` renames read
from the .tsp files (`codegen/custom/azbatch.toml`); only the
constructor is written by hand.

The test runs every public call through a Go program built against
azbatch v0.1.0 with a fake transport, every argument and option filled,
and compares each request (method, URL, headers, body), each response
served and each result, two pages of each pager included.

Where it differs from Go v0.1.0:

- Go's int32 fields and options are `Int`, and `azcore.ETag` is `Str`.
- A header time Go cannot parse fails with Go's prefix and Xo's
  reason after it.
