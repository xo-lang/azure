# 0007: License, attribution and repository hygiene

Status: Proposed (Xo Azure 1, 2026-11-05)

## Context

The repository is private and empty, and is made public later only on the
owner's word. It will port code and tests from azure-sdk-for-go and read
the service specifications in azure-rest-api-specs; both are MIT licensed
(Copyright (c) Microsoft Corporation). The AWS SDK for Xo is Apache-2.0
because the AWS models it reads are Apache-2.0; that reason does not
carry over.

## Decision

- **License: MIT** for the whole repository, the license of everything it
  draws on, so ported code keeps one license and needs no relicensing
  notes. `LICENSE` holds the MIT text for this project; `NOTICE.md` lists
  what was ported or adapted (azure-sdk-for-go paths and commits,
  azure-rest-api-specs at a pinned commit) with Microsoft's MIT copyright
  line, as MIT requires.
- **Generated code** carries a header naming its source spec file and the
  pinned azure-rest-api-specs commit. The specs themselves are not
  committed; `codegen/specs.lock` pins the commit and the generator
  fetches it (decision 0002).
- **README, first lines:** "A community Azure SDK for the Xo language. Not
  affiliated with or endorsed by Microsoft. Microsoft and Azure are
  trademarks of the Microsoft group of companies." No Microsoft or Azure
  logos anywhere, no "official" wording, and module paths under
  `github.com/xo-lang/azure` only.
- **No sensitive data** in any tracked file or commit: no subscription,
  tenant or client IDs, storage account names, keys, SAS tokens,
  connection strings, IP addresses (tests use RFC 5737 documentation
  addresses), the owner's hostnames, emails other than the commit author,
  or paths under `/Users`. Nothing from the xo repository's local notes,
  the lead's notes, or the owner's configuration.
- **Placeholders that are public by design** are allowed only as exact
  values with a citation in `scripts/check-public.sh`: Azurite's well
  known development account and key, the Cosmos DB emulator's key, and
  the all-zero GUID and `00000000-0000-0000-0000-000000000000` style
  examples in Microsoft's specs. Everything else that looks like a GUID,
  key or token fails the check.
- **Checks before every push:** `scripts/check-public.sh` (GUIDs, keys,
  `AccountKey=`, `SharedAccessSignature`, `sig=`, home paths, IPs,
  emails) and `gitleaks git` over the full history with the publishing
  tools' `gitleaks.toml` plus a repo `scripts/gitleaks-extra.toml`. Each
  writes to a file and its exit status is checked; a finding is fixed
  before the push. CI runs both on every run (decision 0008).
- **Commits:** no attribution lines, no em dashes in any file or message,
  pushed history is never rewritten.

## Consequences

- A user can vendor any file with one license notice.
- Every new public-by-design value needs a citation before it is allowed,
  which keeps the allowlist short.

## Alternatives

- Apache-2.0, matching the AWS SDK for Xo: the MIT code it ports would
  still need its own notices, for no gain.
- Committing the specs (as some generators do): the specification
  repository is very large; a pinned commit and a fetch keep the
  repository small and the inputs reproducible.
