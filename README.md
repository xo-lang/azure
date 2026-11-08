# Azure SDK for Xo

A community Azure SDK for the Xo language. Not affiliated with or
endorsed by Microsoft. Microsoft and Azure are trademarks of the
Microsoft group of companies.

## Coverage

What this repo ports of Go's `github.com/Azure/azure-sdk-for-go/sdk`,
checked against Go's own code (full table:
[docs/reports/azure-go-coverage.md](docs/reports/azure-go-coverage.md)):

- **ARM (resource manager): 307 of 307 modules Go-verified.** Every
  module is generated from the spec Go's own release pins, and every
  call of every client is checked against a local Go program's
  requests and results over a fake transport.
- **Data plane: 27 of Go's 36 library modules ported** (the other 4
  of its 40 are support and sample modules), each at Go's latest
  release except azidentity, a subset (see its
  [gap list](docs/reports/azidentity-v1.15.0-gaps.md)): azcore, Storage (blob,
  Data Lake, files, queues), Cosmos DB, Tables, App Configuration,
  Service Bus, Event Hubs, Event Grid, Web PubSub, Key Vault, Monitor
  query and ingestion, Container Registry, Batch and Azure OpenAI's
  Azure types. Each is checked against Go's vectors from the released
  code and local fakes.
- **Not ported yet:** azidentity/cache and tracing/azotel (see
  decisions [0012](docs/decisions/0012-persistent-token-cache.md) and
  [0013](docs/decisions/0013-tracing.md)); the rest are deprecated Go
  modules.
- No test calls Azure: every check runs against fakes and recorded Go
  output.

Design: accepted ([docs/decisions](docs/decisions/README.md),
2026-11-05).

Hand-written code stays only in the core that Go hand-writes too:
azcore, azidentity, the runtime and policies, the ARM extras, and the
service signing. Everything else is generated, and refreshed from Go's
releases by one command
([decision 0011](docs/decisions/0011-refresh-from-go.md)):

    XO_CLI=/path/to/xo scripts/refresh.sh [module dir ...]

It derives each module's row from Go's module, fetches the specs,
regenerates, writes and runs Go's vector program for each module (a
fake transport, no network), runs the tests, and rewrites the coverage
report's status. A failure is fixed in the generator, never in one
module.

Go names that are Xo keywords are renamed: each module's README lists
its renames, and the generated modules add a trailing `_` (`Type` is
`type_`; see [codegen](codegen/README.md)).
