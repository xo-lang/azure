# azcosmos changes

## v0.1.0

The first tagged release: every module of github.com/xo-lang/azure is
tagged v0.1.0 at one commit.

Tracing (decision 0013): with `policy.ClientOptions.tracing_provider`,
every operation opens Go's span (`create_item c1`, kind Client, with
the `db.*` and `server.*` attributes, and each response's request
charge and status code), checked against Go azcosmos v1.5.0.

Behavior fix: a failed operation's `ResponseError.error_code` is the
status line (`404 Not Found`), as Go's; before, it was the service's
code from the body (`NotFound`).

### Before the first release

Milestones of the port, never tagged; their numbers are not module
versions.

#### v0.2.0 (untagged milestone)

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

#### v0.1.0 (untagged milestone)

No changelog was kept before v0.2.0; see the git history.
