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
- Reading many items: `read_many_items` groups the ids by the physical
  partition holding each key (a hierarchical prefix goes to every range
  under it) and sends one parameterized query per partition, up to 1000
  items each, with Go's three query shapes; a partition that is gone
  (410 with substatus 1002, 1007 or 1008) reads the container and its
  ranges again and retries, three times at most. Query documents, here
  and in the query pager, are Go's json.Marshal of each one (compact,
  HTML escaped).
- Feed ranges: `read_feed_ranges` lists a container's partition key
  ranges, read through the pkranges change feed (each page's etag sent
  back until 304 Not Modified, a 429 page retried with Go's backoff)
  and cached per container resource id, with split and merge parents
  dropped and an incomplete set reported as Go reports it. Effective
  partition keys (MurmurHash3 for version 1 and 2 keys, hierarchical
  keys per component) match Go's baselines.

Each request is Go's byte for byte: the test replays Go programs' 36
requests against the same fake account and compares the host, path and
query as sent, the headers with the master key signature (activity ids
normalized), and the body, and what is read back. Feed ranges replay
15 cases of Go's requests and results against scripted feeds, and
ReadMany 16 cases of Go's full requests (a 1000 item query body compared
by SHA-256).

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
- Cross partition ORDER BY and aggregates are not supported, matching
  Go v1.5.0 (its query engine is only in the 1.6.0 preview).
- Go shares its container and partition key range caches between
  clients of the same endpoint; here they belong to one `Client` and
  the database and container clients made from it.
- Go retries a throttled pkranges page until the call's context ends;
  here a page gets at most 100 tries. An invalidation waits for a
  refresh in progress instead of cancelling it.
- ReadMany's queries run one after another; Go runs them on as many
  goroutines as `MaxConcurrency` (default the CPU count), so there is
  no `max_concurrency` option. `DedicatedGatewayRequestOptions` is not
  ported (nor is it for item reads), and the request charge is a Float
  where Go sums a float32.
- A hierarchical key's prefix in ReadMany is queried as Go queries it:
  the missing levels as `IS_NULL(...)`, so only items whose lower levels
  are JSON null match (an unfiled upstream draft).
- Not ported yet: the change feed, throughput read and
  replace (offers), and vector or full text policies.
- Options are Xo's: optional values are `T?`, JSON values are
  `json.Value`, items are JSON text, and errors are `azcore.CallErr`.
