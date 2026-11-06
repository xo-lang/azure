# azadmin

Managed HSM administration for Xo, a port of Go's
`sdk/security/keyvault/azadmin` v1.5.0 (REST API version 2025-07-01).
Go's module has three packages; here each is its own module:

- `backup` (`github.com/xo-lang/azure/security/keyvault/azadmin/backup`):
  full backups and pre-backup checks to a Storage blob container, and
  full, pre and selective key restores from one. Each is a
  long-running operation: `begin_*` returns a `runtime.Poller`.
- `rbac`: role definitions and role assignments (create, get, delete,
  and a pager of each at a `RoleScope`).
- `settings`: the account settings (get one, list, update).

Each has `new_client(net, clock, rand, vault_url, cred, opts)`,
authorized by Key Vault's challenge policy (the first request goes
without a token or body, and the 401's `WWW-Authenticate` gives the
tenant and resource), with `ClientOptions.disable_challenge_resource_verification`
as Go's. The operations, options, responses and models are generated
from the TypeSpec-built OpenAPI files Go's are, with Go's names
(`codegen/services.toml`); `custom_client.xo` holds the clients and
backup's `ErrorInfo`, written by hand as Go's.

The backups use azcore's async poller. The restores use Go's
restorePoller (`backup/internal/pollers`), here
`runtime.new_status_poller`: it polls the `Azure-AsyncOperation` URL as
sent (an absolute URL is required), each poll must have a body with a
`status`, and the result is the last poll's body, with no final GET.
Resume tokens are Go's byte for byte, so a token moves between a Go and
an Xo program.

Each request is Go's byte for byte: each package's test replays a Go
program's calls against the same fake Managed HSM and compares the
method, URL, headers and body of each request, the polls, the resume
tokens and what is read back (`govectors_test.xo`).

Where it differs from Go v1.5.0:

- Three modules for Go's one: `MODULE` is the package's name
  (`backup`, `rbac`, `settings`), so the `User-Agent` starts
  `xo-lang-azure-backup/v0.1.0` where Go's starts
  `azsdk-go-azadmin/v1.5.0` (decision 0003 names the SDK).
- backup's `ErrorInfo` encodes as the error object it read; Go's
  marshals as `{"Code": ...}`, its one exported field. Its `code` and
  `display()` are Go's `Code` and `Error()`.
- Every request has an `x-ms-client-request-id` (decision 0003).
