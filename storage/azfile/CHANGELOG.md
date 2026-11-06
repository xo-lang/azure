# azfile changes

## v0.2.0

Behavior fix: `parse_url` and `URLParts.to_url` are Go's
sas.ParseURL and URLParts.String, checked on 77 URLs and 12 built
parts from a Go program on azfile v1.7.1 (`urlvectors_test.xo`).

- An IP host is the one Go's shared.IsIPEndpointStyle sees (the
  host, its port removed, parsed as net.ParseIP). Before, any host
  with a `:` (such as `a:b:c`) or four dotted numbers (such as
  `192.0.2.300`) was taken as an IP, so its first path segment was read
  as the account name.
- A URL is read as Go's url.Parse reads it, errors included: ports
  must be digits, a bracketed host must be IPv6, a host's bytes and
  escapes follow Go's rules, user info is checked, control bytes are
  refused, a fragment's escapes are checked, and an error names the
  URL without its fragment.
- Only the path's first `/` is dropped (`//s1//f` has no share name),
  as in Go.
- The path is written as url.URL writes one: `$&+,;=:@` are kept,
  where each segment was escaped with `url.path_escape` before.
- The query is read as Go's URL.Query: a pair with a `;` or a bad
  escape is dropped and the rest kept, where one bad pair dropped them
  all, and more than 10000 pairs read as none.
- `URLParts.scheme` and `host` default to `""`, as Go's zero values.
