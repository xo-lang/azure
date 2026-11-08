# azcosmos changes

## Unreleased

Tracing (decision 0013): with `policy.ClientOptions.tracing_provider`,
every operation opens Go's span (`create_item c1`, kind Client, with
the `db.*` and `server.*` attributes, and each response's request
charge and status code), checked against Go azcosmos v1.5.0.

Behavior fix: a failed operation's `ResponseError.error_code` is the
status line (`404 Not Found`), as Go's; before, it was the service's
code from the body (`NotFound`).

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
