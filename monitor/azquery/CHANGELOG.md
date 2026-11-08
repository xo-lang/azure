# azquery changes

## Unreleased

Tracing (decision 0013): with `policy.ClientOptions.tracing_provider`,
the logs and metrics methods open Go's spans and the two metrics
pagers theirs, checked against Go azquery v1.2.0.

## v0.1.0

First release: a port of Go's `sdk/monitor/azquery` v1.2.0.
