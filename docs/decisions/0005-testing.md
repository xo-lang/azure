# 0005: Testing without real Azure

Status: Proposed (Xo Azure 1, 2026-11-05)

## Context

No real Azure until the owner confirms a test plan (services, operations,
resources, cost, cleanup) through the lead, and the owner provides the
subscription. Until then: Docker emulators, Microsoft's published test
recordings, and fakes with invented credentials.

## Decision

### Layers

1. **Unit tests with fakes:** `testing.FakeNet`, `FakeClock`,
   `FakeEnv`, `MemFs`: the pipeline (retry delays, `Retry-After`,
   telemetry, request IDs), errors, pagers, every poller kind and resume
   token, RP registration, each credential's request shape (IMDS, App
   Service, client secret, the client assertion JWT checked with
   std/jwt), the token cache's refresh timing.
2. **Signing vectors:** Shared Key, SAS and Cosmos master key strings to
   sign and signatures. Microsoft publishes no vectors with a known key,
   so vectors are made from Go's code (azblob, azcosmos) run once on
   inputs with Azurite's public development key, stored with their
   source, and checked again by Azurite itself (layer 4).
3. **Recordings:** azure-sdk-for-go's test recordings (Azure/azure-sdk-assets,
   MIT), fetched per module tag into `testdata/recordings` with their
   source tag. A replayer serves each entry (method, URI, body) to the
   generated client, with a relaxed matcher (User-Agent, request IDs and
   the sanitized host ignored), and checks the client reaches the same
   final result. This tests generated ARM clients against real Azure
   responses without calling Azure.
4. **Emulators in Docker**, published on 127.0.0.1 only:
   - Azurite (Blob, Queue, Table), which checks Shared Key and SAS
     signatures;
   - the Cosmos DB Linux emulator (it runs on arm64 but does not check
     auth, so it tests the protocol only; master key auth is covered by
     layer 2);
   - later, the Service Bus and Event Hubs emulators (AMQP, decision
     0006; they need SQL Edge or Azurite beside them);
   - Key Vault and ARM have no emulator: recordings and fakes.

### Guards against reaching real Azure

- Tests get a `Net` that reaches only the loopback host
  (`os.net.only(["127.0.0.1", "localhost"])`) or a `FakeNet`; a test that
  resolves an Azure host fails.
- Credentials in tests are invented (`00000000-0000-0000-0000-000000000000`
  style IDs, made up secrets) and come from `FakeEnv`, never the real
  environment: no test reads `AZURE_*`, `~/.azure` or the az CLI.
- `scripts/check-public.sh` fails on anything that looks like a real
  subscription, tenant or client ID, key, SAS or connection string
  (decision 0007).

### Gates

`scripts/gate.sh` (every module's tests and type check), the generator's
"regenerates unchanged" check, the recordings replay, and the emulator
run, all on the machine-wide lock (`heavy.sh`), and in CI.

## Consequences

- ARM clients are tested against real responses from day one, without a
  subscription.
- Key Vault's and Cosmos DB's auth are tested only against vectors until
  real Azure is allowed.

## Alternatives

- Microsoft's test proxy (.NET) to replay: the reference implementation,
  but a .NET tool in the loop; a small Xo replayer of the same JSON format
  needs nothing else.
