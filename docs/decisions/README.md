# Decisions

Architecture decision records, numbered `NNNN-short-title.md`, each with
Status, Context, Decision, Consequences, Alternatives. A reversed decision
gets a new record and the old one is marked `Superseded by NNNN`; none is
deleted.

- [0001](0001-architecture-and-module-layout.md): a core module plus azidentity and one module per service, at azure-sdk-for-go's paths without `sdk/`, each tagged `<dir>/vX.Y.Z` (Accepted)
- [0002](0002-spec-source-and-generator.md): read the OpenAPI 2.0 JSON of azure-rest-api-specs (hand written and TypeSpec emitted), at the api-versions azure-sdk-for-go ships, with a generator in Xo and committed output (Accepted)
- [0003](0003-core.md): the hand written core: azcore's pipeline and policies, errors, pagers, pollers, ARM extras, the Entra ID credentials without MSAL, Storage, Key Vault and Cosmos signing (Accepted; amendment 1, a public token cache, request values and final send errors, Accepted)
- [0004](0004-api-shape.md): azure-sdk-for-go's shape in Xo style: clients, options structs, pagers, pollers, snake_case names (Accepted)
- [0005](0005-testing.md): testing without real Azure: fakes, signing vectors, replayed Go recordings, Azurite and the Cosmos emulator, loopback-only networks (Accepted)
- [0006](0006-xo-gaps.md): Xo gaps: AMQP 1.0, PKCS#12, JWT header fields, closures with effects, hex formatting (Accepted)
- [0007](0007-license-and-hygiene.md): MIT, attribution to Microsoft's MIT sources, the trademark notice, no sensitive data, checks before every push (Accepted)
- [0008](0008-continuous-integration.md): a weekly workflow: newest Xo, newest specs, every check, merge and tag on green, no Azure in CI (Accepted)
- [0009](0009-token-credential-effects.md): an effect parameter on TokenCredential (decision 0534's pattern), so Azure Arc's managed identity can read its key file; needs the native backends to dispatch an effect-generic struct's method through an interface (Accepted; the native support is on xo main as fb952a75a)
- [0010](0010-float32.md): Go's float32 fields and parameters are Float32, written as Go writes a float32; int32 stays Int (Accepted)
- [0011](0011-refresh-from-go.md): every ARM module is generated and refreshed from Go's releases (rows derived from Go, vectors from Go's source, scripts/refresh.sh); hand-written code only in the core Go hand-writes too (Accepted)
- [0012](0012-persistent-token-cache.md): a persistent token cache (azidentity/cache): an optional store on runtime.TokenCache in MSAL's cache schema, then Go's per-OS protected file; waits on std AES-CBC, keychain, DPAPI and keyctl (Proposed)
