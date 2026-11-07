# Azure SDK for Xo

A community Azure SDK for the Xo language. Not affiliated with or
endorsed by Microsoft. Microsoft and Azure are trademarks of the
Microsoft group of companies.

Status: design accepted ([docs/decisions](docs/decisions/README.md),
2026-11-05). The core is written; every service client is generated
from the spec Go's own release pins, and each module is checked
against a local Go program's requests and results
([coverage](docs/reports/azure-go-coverage.md)).

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
