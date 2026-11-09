# 0015: The developer-tool credentials

Status: Accepted (owner, 2026-11-09, through the lead). Supersedes the
"Still out" line of decision 0003 for AzureCLICredential,
AzureDeveloperCLICredential and AzurePowerShellCredential; brokered
sign-in (WAM) stays out.

## Context

Decision 0003 left the three credentials that run another program out
of the port. azidentity v1.15.0 has them in DefaultAzureCredential's
chain (after the managed identity) and behind `AZURE_TOKEN_CREDENTIALS=dev`,
and they are how most developers sign in on their own machine. The
port refuses `dev` and the three names today.

Xo can now run programs portably: `Proc.run` and `Proc.cmd` (std 3.7
and 3.8, native and Go backends, Windows quoting as Go's), attenuation
with `Proc.only`, and a FakeProc for tests.

## Decision

1. **Port the three credentials from azidentity v1.15.0** as Go writes
   them: the same command lines (`az account get-access-token -o json
   --resource ...`, `azd auth token -o json --no-prompt --scope ...`,
   PowerShell's script), run as Go runs them (`/bin/sh -c COMMAND` in
   `/bin`; on Windows `cmd.exe /c COMMAND` in `%SYSTEMROOT%`), the same
   10 second timeout, the same scope, subscription and tenant checks,
   the same claims handling, and the same errors (exit status 127 or
   `is not recognized` is unavailable, `executable not found on path`;
   azd's JSON error lines; PowerShell's `Connect-AzAccount` and missing
   Az.Accounts texts).
2. **Effects.** Each credential takes a `Proc` and adds `uses proc` to
   its TokenCredential (decision 0009's effect parameter). Callers may
   pass `proc.only(["/bin/sh"])` (or `cmd.exe`) to bound it.
3. **The default chain.** `new_default_azure_credential` keeps its
   signature and keeps refusing `dev` and the three names, since adding
   them would make every caller grant `proc`. A second constructor,
   `new_default_azure_credential_with_dev(..., proc)`, is Go's full
   chain: the three credentials after the managed identity, `dev` and
   their names accepted, and their errors made unavailable inside the
   chain as Go's `unavailableIfInDAC`.
4. **Testing.** Tests never run the real `az`, `azd` or `pwsh`. The
   port's tests use FakeProc. The Go oracle (vectors) runs azidentity
   v1.15.0 with a temporary directory of fake executables first on
   `PATH` (shell scripts that print the arguments they got and a fixed
   answer), under `env -i`, never with the owner's `PATH` or sign-ins;
   it records each command line, the token or error, and the expiry.
5. **No real sign-in.** Nothing in this repository runs against a real
   tenant; the credentials' behavior with real tools is Go's, checked by
   the vectors' command lines.

## Consequences

- Three more files in azidentity, and a FakeProc dependency in its
  tests.
- decision 0003's "Still out" line points here.
- `AZURE_TOKEN_CREDENTIALS=dev` works through the new constructor only;
  the error from the old one names it.
