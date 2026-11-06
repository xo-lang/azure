# azcosmos

Azure Cosmos DB for NoSQL for Xo, the core of Go's `sdk/data/azcosmos`
v1.5.0 (REST API version 2020-11-05).

What it does:

- `Client` with the master key (`new_client_with_key`), Entra ID tokens
  for the account's scope (`type=aad&ver=1.0&sig=<token>`), or a
  connection string (`AccountEndpoint` and `AccountKey`).
- The account's regional endpoints: read once from the account on
  first use, writes to its first write region and reads to the first
  preferred region it has (`ClientOptions.preferred_regions`), else its
  first read region.
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

Each request is Go's byte for byte: the test replays Go programs' 33
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
- The pipeline sends `x-ms-client-request-id` (decision 0003); Go's
  Cosmos pipeline has no request ID policy.
- Not ported yet: cross-region failover and Go's Cosmos retry policy
  (requests use azcore's retry), the partition key range cache and
  cross partition query execution (ORDER BY, aggregates), ReadMany, the change feed, throughput read and replace
  (offers), and vector or full text policies.
- Options are Xo's: optional values are `T?`, JSON values are
  `json.Value`, items are JSON text, and errors are `azcore.CallErr`.
