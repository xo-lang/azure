# azcosmos

Azure Cosmos DB for NoSQL for Xo, the core of Go's `sdk/data/azcosmos`
v1.5.0 (REST API version 2020-11-05).

What it does:

- `Client` with the master key (`new_client_with_key`), Entra ID tokens
  for the account's scope (`type=aad&ver=1.0&sig=<token>`), or a
  connection string (`AccountEndpoint` and `AccountKey`).
- Regional routing and failover as Go's: the account read on first
  use and every 5 minutes; reads in the order of
  `ClientOptions.preferred_regions` (names compared without case or
  spaces), writes to the first write region (or the preferred ones on
  a multi-write account, with `x-ms-cosmos-allow-tentative-writes`);
  an endpoint that fails is put last for 5 minutes.
- Go's Cosmos retry rules: 403 write-forbidden and account-not-found
  mark the endpoint and retry after a fresh account read; 404
  read-session-not-available retries on the write region; 503 moves to
  the next preferred region (writes only on multi-write accounts);
  408 once and 500, 502, 504 once in region then once in the next
  region, for reads; a connection that fails retries in region three
  times, then marks the region and fails over. What the policy gives up
  on is not retried again by azcore's retry policy; 429 is left to it.
- Databases: create (with manual or autoscale throughput), read,
  delete, and the query pager.
- Containers: create (partition key definition, indexing policy,
  unique keys, conflict resolution, time to live, throughput), read,
  replace, delete, and the query pager.
- Items as JSON text: create, upsert, replace, read, delete, patch (add,
  set, replace, remove, increment, with a condition), and the query
  pager with parameters, page size, continuation tokens, metrics and
  one correlated activity id across its pages.
- Partition keys: string, number, bool and null values, hierarchical
  keys by appending, and the empty key for a cross partition query.
- Transactional batches on one partition key: create, upsert, replace,
  delete, patch and read, with ETag conditions, session token and
  consistency options, and each operation's status, charge, ETag and
  item as the service wrote it; `success` is false on 207 Multi-Status.
- Priority-based execution and throughput buckets, for the client and
  for each item operation or batch.

Each request is Go's byte for byte: the test replays Go programs' 36
requests against the same fake account and compares the host, path and
query as sent, the headers with the master key signature (activity ids
normalized), and the body, and what is read back.

Where it differs from Go v1.5.0:

- A partition key string is written as JSON. Go uses
  strconv.QuoteToASCII, which writes `\U0001f600` and `\x01`, neither
  of them JSON; here they are `\ud83d\ude00` and `\u0001` (the rest is
  the same bytes).
- Database and container ids and patch conditions are JSON strings.
  Go writes them into its JSON with `%s`, so one with a quote fails to
  marshal and the call returns an error.
- A response error's `error_code` is the service's code (`NotFound`).
  Go's is the HTTP status text (`404 Not Found`).
- Batch operation ids are JSON strings too (Go's `%s` again).
  `create_item` and `read_item` on a batch take no options; Go takes
  them and ignores them. `TransactionalBatchOptions` with
  `enable_content_response_on_write` left None keeps the client's
  option; Go's options struct always overrides it (false when unset).
- With a token credential, one token cache serves the account read and
  the operations. Go's endpoint manager has its own pipeline and asks
  for a second token.
- The pipeline sends `x-ms-client-request-id` (decision 0003); Go's
  Cosmos pipeline has no request ID policy.
- Go reads the account again in the background after a failover or
  when 5 minutes have passed; here the call that needs it reads it
  first. The regions each attempt goes to are Go's (the test replays
  14 failover cases against Go's output).
- Not ported yet: the partition key range cache and cross partition
  query execution (ORDER BY, aggregates), ReadMany, the change feed,
  throughput read and replace (offers), and vector or full text
  policies.
- Options are Xo's: optional values are `T?`, JSON values are
  `json.Value`, items are JSON text, and errors are `azcore.CallErr`.
