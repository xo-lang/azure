# azidentity/cache

A persistent token cache for azidentity's credentials, kept in the
user's secret store: Go's `github.com/Azure/azure-sdk-for-go/sdk/azidentity/cache`
v0.4.0. A community port for the Xo language. Not affiliated with or
endorsed by Microsoft. Microsoft and Azure are trademarks of the
Microsoft group of companies.

```xo
use github.com/xo-lang/azure/azidentity
use github.com/xo-lang/azure/azidentity/cache

fn main(os: Os) {
  let caps = cache.Caps{fs: os.fs, env: os.env, secrets: os.secrets, clock: os.clock, rand: os.rand}
  let c = cache.new(caps) ?? e => fault(e)
  let opts = azidentity.Options{cache: Some(c)}
  // pass opts to a credential's constructor
}
```

Where the cache lives:

| OS | store |
|---|---|
| macOS | the login keychain: a generic password, service `msal.cache`, account `MSALCache` |
| Windows | `%LOCALAPPDATA%/.IdentityService/msal.cache`, protected with DPAPI for the current user |
| Linux | `$XDG_CACHE_HOME/.IdentityService/msal.cache` (else `~/.cache/...`), compact JWE with a key in the kernel's persistent user keyring |

`Options{name}` separates caches. Requests with continuous access
evaluation use `NAME.cae`. There is no unencrypted fallback: `new`
fails where the store doesn't work (in a container without keyctl, for
example). The cache uses MSAL's shared schema, so other MSAL programs
for the same user can read it.

Needs an xo release with std's secret stores (xo decision 0584).
