# Azure SDK for Xo

A community Azure SDK for the Xo language. Not affiliated with or
endorsed by Microsoft. Microsoft and Azure are trademarks of the
Microsoft group of companies.

Status: design accepted ([docs/decisions](docs/decisions/README.md),
2026-11-05); the core is being written. No service code is generated yet.

Go names that are Xo keywords are renamed: each module's README lists
its renames, and the generated modules add a trailing `_` (`Type` is
`type_`; see [codegen](codegen/README.md)).
