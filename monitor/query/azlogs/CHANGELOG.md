# azlogs (query) changes

## v0.1.0

The first tagged release: every module of github.com/xo-lang/azure is
tagged v0.1.0 at one commit.

Tracing (decision 0013): with `policy.ClientOptions.tracing_provider`,
the three query methods open Go's spans, checked against Go
query/azlogs v1.2.0.

First release: a port of Go's `sdk/monitor/query/azlogs` v1.2.0.
