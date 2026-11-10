# aztables changes

## v0.1.0

The first tagged release: every module of github.com/xo-lang/azure is
tagged v0.1.0 at one commit.

Tracing (decision 0013): with `policy.ClientOptions.tracing_provider`,
every method opens Go's span (`ServiceClient.CreateTable`,
`Client.AddEntity`, ...) and both pagers theirs, with `az.namespace`
`Microsoft.Tables`, checked against Go aztables v1.4.1.

### Before the first release

Milestones of the port, never tagged; their numbers are not module
versions.

#### v0.2.0 (untagged milestone)

Behavior fix: a response header that repeats is read as Go's
`resp.Header.Get` reads it, its first field. Before, the fields were
joined with `, `, so a repeated header read as `a, zz` and a repeated
number, date or boolean did not parse.

- The ETag and the continuation headers of the table and entity
  pagers.
- The Go vector tests rerun with every response header field
  repeated (a second field "zz"), which leaves Go aztables
  v1.4.1's output unchanged.

#### v0.1.0 (untagged milestone)

No changelog was kept before v0.2.0; see the git history.
