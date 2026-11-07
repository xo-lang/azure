# 0011: Every ARM module is generated and refreshed from Go's releases

Status: Accepted (owner, 2026-11-07, through the lead).

## Context

azure-sdk-for-go ships about 300 ARM modules, all generated, each
pinning the azure-rest-api-specs commit and spec folder it was made
from (tsp-location.yaml for TypeSpec, autorest.md for autorest). Go
releases new versions of them every week. Hand-maintaining 300 rows,
spec choices and per-module fixes would not keep up, and every hand
edit would be one more place where this port and Go drift apart. The
owner's requirement: when new features come out, they are generated,
not hand-maintained.

## Decision

- Hand-written code stays only in the core that Go hand-writes too:
  azcore, azidentity, the runtime and policies, the ARM extras, and the
  signing of Storage, Key Vault and Cosmos ([0003](0003-core.md)).
  Every service client is generated.
- A module's services.toml row is derived from Go's own module by
  codegen/gorows: the spec commit and folder from tsp-location.yaml or
  autorest.md, the readme tag, the OpenAPI files (the newest
  api-version's files with Go's requests, and the older api-versions'
  files that hold Go's request paths), Go's module path and version,
  and the options Go's code shows (UTC date-times, sealed single-value
  enums). codegen/cmd/rows merges the derived rows into services.toml;
  a row's own keys (`version`) are kept.
- Per-module customization lives only in data the generator reads,
  and comes from Go's inputs where Go has it (tspconfig.yaml, readme.go.md
  directives, client.tsp decorators). A failure class is fixed once in
  the generator, with a full regeneration diff of every module, never
  by editing one module.
- A module is checked against Go by its vectors: codegen/govec reads
  Go's module source and writes a Go program that calls every public
  method of every client by reflection, every argument and option
  filled, against a fake transport (no network, no Azure);
  codegen/cmd/vectors turns its output into the module's
  govectors_test.xo. Vectors that do not all pass are not committed.
- docs/reports/azure-go-coverage.md's ARM status is written by
  codegen/cmd/coverage, never by hand: Go-verified (vectors pass),
  compiled (generated and gated, no vectors yet), not generated. A
  module is "ported" only when Go-verified.
- `scripts/refresh.sh` runs all of it: Go's newest releases (the Go
  module proxy, never Azure), rows, specs, generation, Go's vector
  programs, tests, and the report, printing each module's result, so a
  new failure class shows as one list.

## Consequences

- A new Go release becomes a refresh and a gate, not a port.
- A behavior Go adds by hand in a generated module (Go's `custom_*.go`
  files) is not generated; the vectors show it, and it is added to the
  core or to generator data, whichever Go's code calls for.
- The refresh needs Go's toolchain and the Go module cache on the
  machine that runs it, and the spec cache (codegen/fetch-specs.sh).
