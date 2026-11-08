# azlogs (ingestion) changes

## Unreleased

Tracing (decision 0013): with `policy.ClientOptions.tracing_provider`,
`upload` opens Go's span, checked against Go ingestion/azlogs v1.1.0.

## v0.1.0

First release: a port of Go's `sdk/monitor/ingestion/azlogs` v1.1.0.
