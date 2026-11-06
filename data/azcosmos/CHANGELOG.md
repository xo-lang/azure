# azcosmos changes

## v0.2.0

Behavior fix: a response header that repeats is read as Go's
`resp.Header.Get` reads it, its first field. Before, the fields were
joined with `, `, so a repeated header read as `a, zz` and a repeated
number, date or boolean did not parse.

- Every response header the clients read: the request charge,
  activity ID, ETag, session token, continuation, substatus (read
  by the failover and read-many retries), the offer headers and
  the query metrics.
- The Go vector tests rerun with every response header field
  repeated (a second field "zz"), which leaves Go azcosmos
  v1.5.0's output unchanged.

## v0.1.0

No changelog was kept before v0.2.0; see the git history.
