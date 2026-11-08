# aztables changes

## Unreleased

Tracing (decision 0013): with `policy.ClientOptions.tracing_provider`,
every method opens Go's span (`ServiceClient.CreateTable`,
`Client.AddEntity`, ...) and both pagers theirs, with `az.namespace`
`Microsoft.Tables`, checked against Go aztables v1.4.1.

## v0.2.0

Behavior fix: a response header that repeats is read as Go's
`resp.Header.Get` reads it, its first field. Before, the fields were
joined with `, `, so a repeated header read as `a, zz` and a repeated
number, date or boolean did not parse.

- The ETag and the continuation headers of the table and entity
  pagers.
- The Go vector tests rerun with every response header field
  repeated (a second field "zz"), which leaves Go aztables
  v1.4.1's output unchanged.

## v0.1.0

No changelog was kept before v0.2.0; see the git history.
