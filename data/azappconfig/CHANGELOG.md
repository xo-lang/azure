# azappconfig changes

## v0.1.0

The first tagged release: every module of github.com/xo-lang/azure is
tagged v0.1.0 at one commit.

Tracing (decision 0013): with `policy.ClientOptions.tracing_provider`,
every method opens Go's span (`Client.GetSetting`, ...), the five
pagers theirs and the snapshot poller its own, with `az.namespace`
`Microsoft.AppConfig`, checked against Go azappconfig/v2 v2.3.0.

First release: a port of Go's `sdk/data/azappconfig/v2` v2.3.0 (REST
API version 2026-04-01).
