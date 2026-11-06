# azappconfig

Azure App Configuration for Xo, a port of Go's
`sdk/data/azappconfig/v2` v2.3.0 (REST API version 2026-04-01): the
settings and snapshots of one configuration store.

What it does:

- `new_client(net, clock, rand, endpoint, cred, options)`, authorized
  by Entra ID tokens for the endpoint's audience (the domain from its
  last `azconfig` or `appconfig` label, the staging domain's, else
  `https://appconfig.azure.com`), or the cloud's when the options set
  China's, Government's or a cloud with a `SERVICE_NAME` entry.
- `new_client_from_connection_string(net, clock, rand, cs, options)`
  (`Endpoint=...;Id=...;Secret=...`): each request signed with
  HMAC-SHA256, as Go's `internal/auth`.
- Settings: `add_setting`, `get_setting`, `set_setting`,
  `delete_setting`, `set_read_only`, with ETag conditions
  (`only_if_unchanged`, `only_if_changed`).
- Pagers: `new_list_settings_pager` and `new_check_settings_pager`
  (HEAD; each with a match condition per page, a 304 page empty),
  `new_list_revisions_pager`, `new_list_snapshots_pager` and
  `new_list_settings_for_snapshot_pager`. A next link the service gives
  relative to the store is resolved, and the settings pagers read it
  from the `Link` header. A failed page ends the pager.
- Snapshots: `begin_create_snapshot` (a `runtime.Poller`, resumable
  from its token), `get_snapshot`, `archive_snapshot`,
  `recover_snapshot`.
- Sync tokens: each response's `Sync-Token` is cached (the newest per
  id) and sent with the next requests; `set_sync_token` adds one.
- The query is normalized before signing (names lower cased, sorted),
  and an Entra ID audience error (`AADSTS500011`) is explained, as Go's
  policies do.

The test replays a Go program's calls, every public one, on the same
scripted responses and compares each request (method, URL, headers,
body), the token scopes asked for, and what each call returned, line
for line. The HMAC signature of each of a second program's requests is
checked byte for byte, with the clock set to the date Go signed it at.

Where it differs from Go v2.3.0:

- A response without a `Sync-Token` header has `sync_token` "" (Go
  dereferences a nil pointer and panics, except in the check pager).
- `set_sync_token` keeps every id; the `Sync-Token` request header
  lists them sorted by id (Go's order is its map's, random).
- The options' cloud defaults to `cloud.AZURE_PUBLIC`, which counts as
  no cloud set, as Go's zero `Cloud`: the endpoint gives the audience.
  Setting Go's `cloud.AzurePublic` explicitly gives
  `https://appconfig.azure.com` for every endpoint; here, give the
  public cloud a `SERVICE_NAME` entry for that.
- `accept_date_time` is written in UTC (a `Time` has no zone; Go's
  keeps the time's own offset).
- A bad endpoint and a body that does not decode are errors with Xo's
  wording (Go's url.Parse and encoding/json name theirs).
- Every request has an `x-ms-client-request-id` (decision 0003).

As Go's, kept for parity:

- The list and revisions pagers send `SettingSelector.accept_date_time`
  as the `After` page token, not `Accept-Datetime` (the check pager
  sends `Accept-Datetime`).
- A selector without `fields` sends an empty `$Select`.
- `begin_create_snapshot`'s result has each filter empty: Go decodes
  the snapshot into its public type, whose SettingFilter has no JSON
  names.
- `GetSettingResponse.last_modified` is the setting's.
