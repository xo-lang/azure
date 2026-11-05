# 0001: Architecture and module layout

Status: Proposed (Xo Azure 1, 2026-11-05)

## Context

The owner asked for a native Xo SDK for Azure built the way the AWS SDK
for Xo was: services generated from Microsoft's specifications, the core
written by hand, the API shaped after github.com/Azure/azure-sdk-for-go so
Go users find it familiar (owner decisions 1, 3, 4, 2026-11-05).

azure-sdk-for-go has 325 management modules
(`sdk/resourcemanager/<group>/arm<name>`) and about 40 others: azcore,
azidentity, and the data planes (`sdk/storage/azblob`,
`sdk/security/keyvault/azsecrets`, `sdk/data/azcosmos`,
`sdk/messaging/azservicebus`, ...). Each is its own Go module with its
own tags.

## Decision

### Modules

Paths follow azure-sdk-for-go without its `sdk/` prefix, so a Go user
finds each package where they expect it. Each module has its own `xo.mod`
and tags `<dir>/vX.Y.Z` (spec/core.md 4.2).

| Module (directory) | Package | Go counterpart | Content |
|---|---|---|---|
| `.` (`github.com/xo-lang/azure`) | `azcore`, `policy`, `runtime`, `cloud`, `arm`, `poller`, `pager`, `streaming`, `to` (sub packages) | azcore | the pipeline, policies, errors, clouds, pollers, pagers, ARM extras (decision 0003) |
| `azidentity` | `azidentity` | azidentity | the Entra ID credentials (decision 0003) |
| `resourcemanager/<group>/arm<name>` | `arm<name>` | the same path | one generated module per management package, 325 today |
| `storage/azblob`, `storage/azqueue`, `data/aztables` | `azblob`, ... | the same paths | Storage data planes: generated operations, hand written Shared Key and SAS |
| `security/keyvault/azsecrets`, `azkeys`, `azcertificates` | the same | the same | Key Vault data planes |
| `data/azcosmos` | `azcosmos` | the same | Cosmos DB, hand written (its Go SDK is) |
| `messaging/azservicebus`, `messaging/azeventhubs` | the same | the same | AMQP 1.0, after Xo has an AMQP module (decision 0006) |

The core is one module, as the AWS SDK's root is, because its packages
change together and are always used together. azidentity is separate, as
in Go, because it is the one most often replaced (a program may bring its
own `TokenCredential`), and it is where most security fixes land, so its
releases should not move the core's.

### Package names

The package is the directory's last segment (`armstorage`). The generator
checks every name against Xo's keywords and predeclared names (XO0602;
the list the AWS generator keeps) and fails on a collision or on two
modules mapping to one name; no Go name collides today (`armtype` would
not exist, but the rule is there).

### Versions and releases

Each module is tagged on its own, a minor or patch past its newest tag
when it changes, as the AWS SDK's weekly run does (decision 0008). A
module's major version follows its Go counterpart's when the Go module
breaks its API (`armstorage/v3`): the path gains `/vN` as in Go.

### Effects

Every operation `uses (net.dial, clock, rand)`: the network, the clock
for retries, token expiry and polling, random for retry jitter and request
IDs. Reading files (a workload identity token, a certificate) happens
when a credential is built (`uses fs.read`), never inside an operation,
as in the AWS SDK (its decision 0003, amended).

## Consequences

- About 335 modules; the CI tags only those that change.
- A Go user can translate `armstorage.NewAccountsClient` to
  `armstorage.new_accounts_client` and find the rest the same way.

## Alternatives

- One module for everything: one tag, but every user downloads all 325
  management packages and every change releases all of them.
- Grouping management packages by service folder (one module per spec
  folder): fewer modules, but it departs from Go's layout, which is the
  point of the API shape (owner decision 4).
