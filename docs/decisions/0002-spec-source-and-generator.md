# 0002: The specification source and the generator

Status: Accepted (owner, 2026-11-05; proposed by Xo Azure 1, 2026-11-05)

## Context

github.com/Azure/azure-rest-api-specs (MIT, about 640 MB) has 320 service
folders under `specification/`: 310 with `resource-manager/`, 57 with
`data-plane/`. Two layouts live side by side:

- OpenAPI 2.0 (Swagger) written by hand:
  `<svc>/resource-manager/Microsoft.X/{stable|preview}/<api-version>/*.json`,
  with `readme.md` holding `### Tag: package-...` blocks (a YAML block per
  tag listing its `input-file`s) and a default `tag:`.
- TypeSpec (required for new ARM services):
  `<svc>/resource-manager/<Namespace>/<Service>/main.tsp` with
  `tspconfig.yaml`, whose `@azure-tools/typespec-autorest` emitter writes
  `{stable|preview}/<version>/openapi.json` into the same folder. That
  JSON is checked in ("do not modify generated files").

azure-sdk-for-go records, per module, which spec it was generated from:
102 modules have `autorest.md` (the readme at a pinned commit, a
`module-version`, sometimes a `tag:`), 223 have `tsp-location.yaml`
(`directory`, `commit`). A pinned path can disappear later (armaad's
readme is gone at main).

## Decision

- **Read OpenAPI 2.0 JSON only**, both hand written and emitted from
  TypeSpec. Every service has it checked in, so one reader covers all of
  them, and the generator needs no TypeSpec compiler (Node.js) in the
  loop. TypeSpec stays the authors' format; the JSON is its compiled
  output.
- **Which api-version:** the one azure-sdk-for-go ships, so the Xo
  module and its Go counterpart cover the same operations. A table,
  `codegen/services.toml`, has one row per module: its directory, spec
  folder, readme tag (or TypeSpec directory and version), and the spec
  commit. A tool (`codegen/cmd/sync-go`) fills it from azure-sdk-for-go's
  `autorest.md` and `tsp-location.yaml` files at a pinned Go SDK commit;
  for a readme the tag is the file's own or the readme's default. The
  generator reads that tag's `input-file` list (YAML inside Markdown,
  read with std/yaml).
- **Spec pinning:** one azure-rest-api-specs commit for everything, in
  `codegen/specs.lock`, moved forward by CI weekly (decision 0008). The
  generator fetches only what it reads (a partial, sparse clone of the
  JSON and readme files under `resource-manager/` and the data planes it
  generates) into `codegen/.specs`, ignored by git. A module whose spec
  vanished at the new commit keeps its committed code and is reported.
- **The generator is written in Xo**, in `codegen/`, as the AWS SDK's is:
  it reads the JSON into a model (resolving `$ref`s across files,
  `allOf`, `x-ms-paths` beside `paths`), plans every name once, and emits
  explicit serializers and deserializers (no reflection at run time).
  Generated code is committed and regenerating must leave it unchanged
  (a CI check).
- **Extensions handled:** `x-ms-paths` (query strings in keys, not sent),
  `x-ms-pageable` (`nextLinkName`, null for a single flattened page,
  `itemName` default `value`, `operationName`), `x-ms-long-running-operation`
  and its options (`final-state-via`: azure-async-operation, location,
  original-uri, operation-location), `x-ms-enum` (`modelAsString`: an
  extensible string type, else a closed enum with `Unknown`),
  `discriminator` with `x-ms-discriminator-value` (a union type),
  `x-ms-client-name`, `x-ms-parameter-location` (client or method
  parameter), `x-ms-skip-url-encoding`, `x-ms-client-flatten`,
  `x-ms-secret` (a `Secret[Str]`), `x-ms-error-response`, `x-ms-odata`.
  `x-ms-mutability` and `x-ms-azure-resource` change only documentation.
  An extension the generator does not know is listed in a report, never
  silently dropped.
- **Data planes** come from the same specs (`data-plane/`), with the
  hand written pieces each Go package has (Storage's Shared Key and SAS,
  Cosmos DB entirely by hand, Key Vault's challenge auth).

## Consequences

- The generator does not depend on Node.js, AutoRest or TypeSpec.
- Matching Go's api-versions makes Go's tests and recordings usable
  (decision 0005).
- A service authored in TypeSpec whose emitted JSON loses information
  the Go emitter uses directly (rare: client customizations in
  `client.tsp`) needs a customization entry in the generator.

## Alternatives

- Read TypeSpec: the source of truth for new services, but it needs the
  TypeSpec compiler (Node.js) and its libraries, and half the services
  have no TypeSpec at all.
- Always the newest stable api-version: more operations sooner, but the
  modules would no longer match Go's, and the newest version is
  sometimes not one Go has released.
- Per module spec commits (as Go pins them): exact, but the generator
  would fetch hundreds of commits; one commit is reproducible enough.
