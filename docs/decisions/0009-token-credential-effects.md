# 0009: An effect parameter on TokenCredential, for credentials that read files

Status: Proposed (Xo Azure 1, 2026-11-06; the lead's direction, for the
owner to decide)

## Context

`azcore.TokenCredential` is

```
pub interface TokenCredential {
  fn get_token(self, opts: TokenRequestOptions) -> AccessToken ! AuthErr uses (net.dial, clock, rand)
}
```

Every credential, every bearer and challenge policy, and every client
constructor (300 of them, 5 in azblob) takes it, and a client's
operations perform exactly `net.dial, clock, rand`.

Azure Arc's managed identity (gap list item 11, approved by the owner on
2026-11-06) cannot fit that interface. Its token request is answered
with a 401 whose `WWW-Authenticate: Basic realm=<path>` names a key file
the Arc agent has just written. MSAL Go then checks the path and reads
the file, inside GetToken (MSAL Go v1.10.1,
`apps/managedidentity/managedidentity.go`, `getAzureArcSecretKey`). The
file is new for each challenge, so it cannot be read when the
credential is built. Reading it needs `fs.read`, which `get_token` may
not perform (core 6.2: XO0701). Xo has no way to perform an effect a
function's type does not declare, and a stored `Fs` value's `read` is
still `fs.read`.

The pattern for this exists. Decision 0534 (std/sqlite) gave
`sql.Driver`, `Db`, `Tx` and `Rows` an effect parameter, so the SQLite
driver's operations perform `fs` while the Postgres and in-memory ones
perform none (`Db[()]`). A type written without its effect argument is
an implicit effect variable (core 6.2), so most code did not change.

## Decision

`TokenCredential` takes an effect parameter for what its token requests
may do beyond the network:

```
pub interface TokenCredential[fx: Effects] {
  fn get_token(self, opts: TokenRequestOptions) -> AccessToken ! AuthErr uses (net.dial, clock, rand, fx)
}
```

- Every existing credential (client secret, certificate, assertion,
  workload identity, and managed identity without Arc) performs none:
  it is a `TokenCredential[()]`, and its code does not change.
- `policy.Policy`, `runtime.Pipeline`, `runtime.BearerTokenPolicy`,
  `TokenCache`, the storage and Key Vault challenge policies, and
  azidentity's chain take the same parameter, and pass it through.
- A client struct holds a `runtime.Pipeline`. Written without
  arguments, it becomes an implicit effect parameter of the client
  (core 6.2, "in a struct field"). A method on the client may perform
  it without naming it in `uses`, so none of the generated methods'
  `uses (net.dial, clock, rand)` clauses change.

### Call sites

A constructor's parameter `cred: azcore.TokenCredential`, written
without arguments, is an implicit effect variable. The generated code
does not change. A caller passing a credential that performs nothing
does not change either:

```
// before and after: unchanged
let cred = azidentity.new_client_secret_credential(tenant, client, secret, os.net, os.clock, os.rand)?
let c = azblob.new_client(os.net, os.clock, os.rand, url, cred)
c.download_stream(...)?          // uses (net.dial, clock, rand)
```

An interface's effect argument is not inferred from the value that
implements it (decision 0534's note). So a caller using a credential
that reads files names it once, where the credential becomes an
interface value:

```
// before (not possible: Arc's get_token performs fs.read)
// after
let cred: azcore.TokenCredential[fs.read] = azidentity.new_default_azure_credential(os.env, os.fs, os.net, os.clock, os.rand)?
let c = azblob.new_client(os.net, os.clock, os.rand, url, cred)
c.download_stream(...)?          // performs fs.read too, through cred
```

Here `c` is an `azblob.Client[fs.read]`. A function in the caller's
code that takes a client and writes `azblob.Client` (no arguments) has
an implicit effect variable, and keeps compiling. One whose type fixes
its effects (`fn(...) uses net.dial` capturing a client) writes
`azblob.Client[()]` or `azblob.Client[fs.read]`, and `xo fix` writes it
(core 6.2).

### DefaultAzureCredential and the chains

Go's DefaultAzureCredential includes ManagedIdentityCredential, which
picks Arc at run time: from `IDENTITY_ENDPOINT` and `IMDS_ENDPOINT`, or
from the agent's `himds` file existing (Linux `/opt/azcmagent/bin/himds`,
Windows `%ProgramData%\AzureConnectedMachineAgent\himds.exe`).

- ManagedIdentityCredential is a `TokenCredential[fs.read]` on every
  platform. Xo builds one program for all of them, and the source is
  known only at run time. It takes an `Fs` when built (the only new
  argument). An option names the token directory, so tests point it at
  a MemFs directory.
- DefaultAzureCredential, which contains it, is a
  `TokenCredential[fs.read]` on every platform.
- `ChainedTokenCredential[fx]` is as effectful as its sources: a chain
  without Arc is a `TokenCredential[()]`, and one with it is
  `[fs.read]`. That is subject to the prerequisite below.

### Prerequisite: an Xo native backend feature

A prototype of this shape type-checks on xo 26e706db9 (Xo Azure 1,
2026-11-06). It contains:

- `TokenCredential[fx]` and `Policy[fx]`;
- a generic `BearerTokenPolicy[fx]` holding the credential;
- `Pipeline[fx]` holding `List[Policy[fx]]`;
- a client struct with an implicit parameter;
- a pure and an `fs.read` credential, both driving the same client
  code.

It runs on `--backend=go`, but the native backends refuse it with
`XO1201: the method Bearer.apply of Bearer[fx] through an interface`
("support is planned"). Every pipeline policy holding a credential is
such a method, so this decision waits for that feature on the native
backends.

Until then, the parts that do not dispatch through an interface work
natively:

- a closure-based policy;
- a non-generic chain whose sources are `List[TokenCredential[fs.read]]`
  (a `[()]` credential is accepted there by subsumption);
- `Client[()]` in a caller's types.

A generic `ChainedTokenCredential[fx]` dispatched through
`TokenCredential` does not.

## Consequences

- Arc can be ported with MSAL Go's checks:
  - a 401 with `Basic realm=`;
  - a `.key` file in the platform's token directory;
  - at most 4096 bytes;
  - the second request with `Authorization: Basic <key>`;
  - v1.15.0's user-assigned confirmation.
- Callers of every other credential do not change.
- A program that uses DefaultAzureCredential or ManagedIdentityCredential
  names `fs.read` once, where the credential becomes an interface value.
  Those clients' operations perform `fs.read`, so `xo audit` shows the
  file read that Arc can do.
- 300 generated constructors and the hand-written core change in their
  types only. The generator emits `azcore.TokenCredential` unchanged.
- The work waits on the native backend feature (XO1201, planned). The
  lead would ask for it, with the prototype as its test.

## Alternatives

1. **A standalone `AzureArcCredential`** (the fallback). Its `get_token`
   is `uses (net.dial, clock, rand, fs.read)`, so it is not an
   `azcore.TokenCredential`. It cannot go into a client, a chain, or
   DefaultAzureCredential, so a caller cannot use it with any client.
   It is small, and it can ship now. DefaultAzureCredential on an Arc
   machine would then fail where Go's succeeds, and the CHANGELOG would
   say so.
2. **`fs.read` on the interface for everyone.** Every SDK operation
   would declare a file read it never performs. Rejected: `uses` would
   stop describing what a client does.
3. **Read the key without `fs`** (a key callback the caller supplies,
   pure or networked). The key file is local and named by the server.
   A callback with `fs.read` has the same problem, and one without it
   cannot read the file. Rejected.
4. **Skip Arc** (the state before 2026-11-06). The owner approved Arc,
   so this is listed only for completeness.
