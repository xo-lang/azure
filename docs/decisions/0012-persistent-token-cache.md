# 0012: A persistent token cache (azidentity/cache)

Status: Option 1, step a (an optional store in MSAL's cache schema)
Accepted and done (2026-11-09, at the credential: see the correction
under 1a); step b (the per-OS protected file) Deferred (owner,
2026-11-07, through the lead; drafted by Xo Azure 1 at the Xo Lead's
request).

## Context

[0003](0003-core.md) keeps one in-memory token cache per credential and
lists "a single combined token cache file on disk (as MSAL's persistent
cache)" as a rejected alternative: it would need file effects in every
credential. Its Amendment 1 made that in-memory cache public
(`runtime.TokenCache`). The azidentity port leaves out Go's persistent
`Cache` option and the separate `azidentity/cache` module (Go v0.4.0),
together with the user flows that are its main reason to exist.

What Go does, read from azidentity v1.15.0, azidentity/cache v0.4.0 and
MSAL Go v1.10.1 (the versions the port tracks):

- A credential given `Cache` hands MSAL a `cache.ExportReplace`. Before
  each lookup MSAL calls `Replace` (read the stored cache into memory),
  after each token response `Export` (write the whole cache back). The
  stored form is MSAL's shared cache schema, one JSON object of
  `AccessToken`, `RefreshToken`, `IdToken`, `Account` and `AppMetadata`
  entries keyed as MSAL keys them, the same schema MSAL .NET, Python and
  Java read, so a cache can be shared with other MSAL programs on the
  machine.
- Confidential credentials (secret, certificate, assertion) store access
  tokens only. The user flows (device code, interactive browser,
  username and password) also store refresh tokens, ID tokens and the
  account, which is what lets `AuthenticationRecord` and
  `AcquireTokenSilent` sign a user in again in a new process.
- azidentity/cache stores that JSON under
  `<dir>/.IdentityService/<name>` (default name `msal.cache`, and a
  second cache `<name>.cae` for CAE requests), `<dir>` being the home
  directory on macOS, `XDG_CACHE_HOME` or `~/.cache` on Linux and
  LocalAppData on Windows, with `<name>.lockfile` beside it for
  cross-process access, protected per OS:
  macOS in the login keychain (account `MSALCache`, service `<name>`),
  Windows encrypted with DPAPI for the current user, Linux encrypted as
  compact JWE (`alg` `dir`, `enc` `A128CBC-HS256`) with a random key kept
  in the kernel's user keyring (keyctl), so the cache is unreadable after
  a reboot. `Options.Name` separates caches; there is no unencrypted
  fallback.

Xo today has the file lock (std's `fs_lock`) and HMAC, but no AES, no
keychain access, no DPAPI and no keyctl.

## Decision (proposed)

Three options, in the order the drafter recommends:

1. **Port it in two steps, behind its own module `azidentity/cache`.**
   a. A credential's options get an optional store, as Go's `Cache`
      option on azidentity's options (`Options.cache: Cache[fx]?`, a
      `Cache` made by `new_cache` from a factory of `TokenStore[fx]`s:
      `replace(hint) -> Str` and `export(hint, Str)`, one store for CAE
      requests and one for the rest, each made on first use), its
      effect parameter as in [0009](0009-token-credential-effects.md),
      so only a credential given a store performs the store's effects
      (`fs.read`/`fs.write` for a file). MSAL's protocol around it: the
      store is read (`Replace`) before each lookup, except for a
      request with claims, and read again, merged and written
      (`Export`) after each token response; the partition hint is
      `<client>_<tenant>_AppTokenCache` for an app, the account's home
      id (or "" before there is one) for a user. Entries are written in
      MSAL's schema: access tokens for confidential credentials;
      refresh tokens, ID tokens and accounts too for the user flows.
      Entries this module doesn't write (other clients', other MSAL
      programs', unknown fields and sections) are kept as they came.
      Checked against a Go program that runs MSAL with an in-memory
      `ExportReplace` and prints each Replace and Export.

      Correction (2026-11-09): this step first named
      `runtime.TokenCache` as the store's home. That was the wrong
      home: the bearer token policy's cache is keyed by scopes and
      claims and has no client, tenant or account, all of which MSAL's
      schema and its partition hints need, so the store sits at the
      credential, where Go puts it.
   b. `azidentity/cache.new(name)` gives the per-OS store above. It
      waits on std: AES-CBC with HMAC-SHA256 (JWE A128CBC-HS256), a
      Linux keyctl binding, the macOS keychain (Security framework) and
      Windows DPAPI, each a std or native addition through the Xo lead.
      Until then the module offers only a store the caller supplies.
2. **Keep it out** (0003 as it stands) until the user flows are in. For
   confidential credentials the persistent cache only saves one token
   request per process start; the access token lifetime is the same.
3. **A plain file store without OS protection.** Rejected by the
   drafter: Go never writes the cache unencrypted, and a readable token
   file is a weaker default than Go's.

## Consequences

- Option 1a adds an effect parameter to `Options` and to each
  credential that takes a cache (as Go: client secret, certificate,
  assertion, workload identity, Azure Pipelines, device code,
  interactive browser, username and password; not on-behalf-of or
  managed identity). The store is optional and defaults to none, so a
  credential without one performs no new effect; a caller naming the
  types writes `[()]` for none.
- A shared cache file read by other MSAL programs makes the schema a
  compatibility surface: a field written differently from MSAL can break
  another program on the same machine, so 1a's vectors compare each
  exported cache whole (with its object keys sorted, since Go writes
  its maps in no fixed order) and each stored cache's byte length.
- The user flows' remainder (gap list, "Waiting on MSAL behaviour")
  depends on this decision for refresh tokens and accounts surviving a
  restart; their in-process behaviour does not.
