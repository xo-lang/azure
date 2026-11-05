# 0008: Continuous integration

Status: Accepted (owner, 2026-11-05; proposed by Xo Azure 1, 2026-11-05): the workflow is enabled only once the repository is public, so a private repository uses no Actions minutes

## Context

The AWS SDK for Xo runs one weekly GitHub Actions workflow (its decision
0008): the newest Xo release, a model update, every check, then merge and
tag on green, or a pull request and an issue on red. It has worked; the
same fits here. The repository is private for now, so Actions minutes
count against the organization's quota.

## Decision

- `.github/workflows/specs.yml`, weekly and on demand (`dry_run` input):
  install the newest Xo release, move `codegen/specs.lock` to
  azure-rest-api-specs' newest commit and `codegen/services.toml` to
  azure-sdk-for-go's newest release state, regenerate, then run the gate,
  the "regenerates unchanged" check, the recordings replay, Azurite and
  the Cosmos emulator as service containers, and `check-public.sh` plus
  gitleaks over the full history.
- Green: commit to main and tag each changed module. Red: a pull request
  with the change and an issue with the failing step's log.
- **No Azure in CI:** no secrets, no Azure login action, and the network
  guard of decision 0005.
- The workflow is pushed only once the repository is public or the owner
  accepts the private minutes it costs.

## Consequences

- The SDK follows Azure's weekly spec changes without manual work.

## Alternatives

- Generate on every spec commit: hundreds of runs a week for little gain.
