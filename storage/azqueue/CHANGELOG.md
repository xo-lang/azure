# azqueue changes

## Unreleased

Follows Go's `sdk/storage/azqueue/v2` v2.1.2 (was azqueue v1.0.1). The
Go programs behind every vector file were rerun on v2.1.2 and the
vectors regenerated; each change below is checked against Go's output.

- REST API version 2026-04-06 (was 2024-08-04).
- `get_sas_url` on a URL that already has a query joins the SAS with
  `&` and keeps a fragment last (Go v2.1.1); before, a second `?` made a
  broken URL. A service URL gets its `/` before the query.
- Queue URLs from a service client or a connection string join the
  queue name as azcore v1.23's JoinPaths does: a root's query goes
  after the name with `&`.
- An access policy's `Start` and `Expiry` are read as Go v2's
  dateTimeRFC3339: a space for the `T` (with or without a zone), a
  one-digit hour, a fraction after `.` or `,`; a field out of range is
  Go's error (`parsing time "x": hour out of range`, and month, day,
  minute, second), and text after a zoneless time is Go's `extra text`.
- An empty time element, and Go's zero time, read as no time, as Go
  v2's generated models leave them (an empty one was an error).
- A message count past 64 bits is Go's `value out of range` error, not
  `invalid syntax`; one past 32 bits was already read (Go v2 made it
  int64).
- A SAS start or expiry is written in UTC, which this port always did;
  Go v2.1.2 now does too (v1.0.1 wrote a zoned time's wall clock with a
  `Z`), so its vectors include that case again.

Added: user delegation SAS (`sign_with_user_delegation`, the
`sduoid` and `skdutid` parameters, `QueueSignatureValues`'s object and
correlation IDs), checked against Go v2.1.2's own SignWithUserDelegation
(`udvectors_test.xo`), and `ServiceClient.get_user_delegation_credential`
with `KeyInfo`, beyond Go (see the README).

## v0.4.0

Behavior fix: a response header that repeats is read as Go's
`resp.Header.Get` reads it, its first field. Before, the fields were
joined with `, `, so a repeated header read as `a, zz` and a repeated
number, date or boolean did not parse.

- Every response header the clients read, and each `x-ms-meta-*`
  entry. The Go vector test reruns with every response header field
  repeated, which leaves Go azqueue v1.0.1's output unchanged.

## v0.3.0

- `parse_url` reads the URL with azblob's Go url.Parse port (ports,
  IPv6 literals, host bytes, user info, control bytes, fragments) and
  the query as Go's URL.Query: one bad pair no longer drops them all.
- Error texts quote a value as Go's strconv.Quote (a tab is `\t`);
  azqueue's own copy of the quoting did not escape `\n`, `\t` or
  `\r`, and now forwards to azblob's.

## v0.2.0

Constructors and URLs, at Go azqueue v1.0.1 parity on captured
vectors (with the SAS and URL, challenge policy and response work
below, all in this release).

- `ServiceClient.new_queue_client` escapes the queue name
  (url.PathEscape), as Go: `q 1` was sent unescaped.
- Queue and message URLs are joined as azcore v1.21.0's
  runtime.JoinPaths joins them: the path cleaned (`a/../b`), a
  trailing `/` kept, and only the query part before a second `?`.
- A message's URL is cleaned together with `messages`, as Go's
  getMessageIDURL: an empty id is the messages URL.
- A bad account key reads `decode account key: ...`, Go's text.
- `queueerror`: `INVALID_MD5` and `MD5_MISMATCH`, the two codes that
  were missing; a test checks every code against Go's list.

SAS and URLs, at Go azqueue v1.0.1 parity on captured vectors.

- `sas.QueryParameters` has every field of Go's (resource, response
  headers, user delegation keys, sdd, saoid, suoid, scid) and encodes
  as Go's Encode; `sas.new_query_parameters` reads one from a query.
- `sas.URLParts`, `sas.parse_url` and `URLParts.to_url` (Go's
  ParseURL and String, with url.Parse's errors); the root
  `URLParts` is now an alias of it, with the SAS and the other
  parameters apart.

The storage challenge policy, at Go azqueue v1.0.1 parity on captured
vectors.

- `new_queue_client` answers a 401 bearer challenge naming a
  `resource_id` with a token for that resource, kept for later calls,
  and asks for `ClientOptions.audience`'s scope (new), as Go's
  NewQueueClient. `ClientOptions.insecure_allow_credential_with_http`
  (new) sends tokens over plain http to local fakes and emulators.
- `new_service_client` keeps Storage's scope and no challenge
  handling, as Go.

Responses and errors, at Go azqueue v1.0.1 parity on captured vectors.

- A response's Date, a message's times, an access policy's times, the
  approximate message count and an update's next-visible time that do
  not parse fail the call, as Go's generated handlers do, with Go's
  error text; XML decode errors name Go's type.
- `ListQueuesSegmentResponse.response`: each list page's request ID,
  version and date.

## v0.1.0

The service and queue clients, messages, SAS, connection strings and
queueerror, requests byte for byte with Go azqueue v1.0.1's.
