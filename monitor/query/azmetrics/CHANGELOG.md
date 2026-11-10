# azmetrics changes

## v0.1.0

The first tagged release: every module of github.com/xo-lang/azure is
tagged v0.1.0 at one commit.

Tracing (decision 0013): with `policy.ClientOptions.tracing_provider`,
`query_resources` opens Go's span, checked against Go azmetrics
v1.3.0.

First release: a port of Go's `sdk/monitor/query/azmetrics` v1.3.0.
