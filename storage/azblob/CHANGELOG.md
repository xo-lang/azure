# azblob changes

## v0.9.0

- `exported.parse_go_url` reads a URL as Go's url.Parse does, errors
  included: a port must be digits; a bracketed host must be an IPv6
  address (Go's netip error text), with its zone after `%25`; a
  host's raw bytes must be ones Go keeps (`invalid character " " in
  host name`); user info before the last `@` is checked
  (`net/url: invalid userinfo`) and dropped; control bytes are
  refused; a fragment's escapes are checked; `///x` with no scheme has
  no host; and an error names the URL without its fragment.
- `exported.go_query`: a query read as Go's URL.Query reads one. A
  pair with a `;` or a bad escape is left out and the rest kept, and
  more than 10000 pairs read as none (std's `url.parse_query` returns
  only the error).
- `exported.go_quote` writes control bytes as Go's strconv.Quote does
  (`\a`, `\b`, `\f`, `\v`, `\xNN`), checked on every ASCII byte.

## v0.8.0

- `exported.all_bytes`, `has_byte` and `is_unreserved` are public, for
  azdatalake's Go path escaping. azfile's sas time and IP helpers and
  azdatalake's quoting, escaping and IP-host helpers now call azblob's
  instead of keeping copies (they were the same code; no behavior
  change).

## v0.7.0

- `new_shared_key_credential`: a key that is not base64 reads
  `decode account key: ...`, Go's text in every storage module.
- `sas`: the SAS time layouts (`TIME_FORMAT*`), `parse_time`,
  `parse_layout`, `format_time_layout`, `ip` and `ip_range`, as Go's
  storage sas packages read and write a SAS, shared by azqueue.
- `exported.parse_go_url`, `GoUrl.to_str`, `go_escape_path`,
  `is_ip_endpoint` and `go_quote`: URLs read and written as Go's
  net/url does for storage URLs, shared by azqueue.

## v0.6.0

- `exported.new_storage_challenge_policy` and
  `exported.parse_storage_challenge`: Go's storage challenge policy (a
  401 bearer challenge naming a `resource_id` gets a token for that
  resource, kept for later calls), exported for azqueue and
  azdatalake. Every token client uses it, as in Go.
- `new_client` now reads `ClientOptions.audience` and
  `insecure_allow_credential_with_http`, as Go's azblob.NewClient
  passes them on to service.NewClient; it asked for Storage's scope
  before.

## v0.5.0

- `BlobClient.download_stream_with_response`: the download and the
  response it was read from (a 304's too), for a client that reads
  more of its headers (azdatalake's file download reads its encryption
  context and ACL from it).

## v0.4.0

- `BlobClient.get_properties_with_response`: the properties and the
  response they were read from, for a client that reads more of its
  headers (azdatalake's paths read their owner and ACL from it).

## v0.3.0

Adds Go v1.8.3's service, container, blob and lease clients for what
azdatalake needs. `Client` and its calls are unchanged.

- `ServiceClient`, `ContainerClient`, `BlobClient`, `BlobLeaseClient`
  and `ContainerLeaseClient`, with Go's constructors (token, Shared Key,
  no credential, connection string).
- `ClientOptions.audience` (default `""`: the storage scope) and
  `insecure_allow_credential_with_http` (Go's azcore option, default
  false), read by the Go-shaped clients.
- Blob `download_stream` (ranges, conditions, a customer key, 304 as a
  response) and `download_buffer` (Go's ETag lock across blocks). A
  hash header that is absent is None, as Go leaves it nil.
- Each call's request and response match Go's on captured vectors.

## v0.2.0

Moves the port from Go azblob v1.6.1 to v1.8.3.

- Every request sends `x-ms-version: 2026-12-06` (was 2025-05-05), and
  `sas.VERSION` signs that version.
- `sas`: user delegation SAS sign the delegated user's tenant
  (`skdutid`, from `UserDelegationKey.signed_delegated_user_tenant_id`)
  and `signed_delegated_user_object_id` (`sduoid`), and take signed
  request headers and query parameters (`srh`, `srq`). A blob version
  SAS signs the version ID in the timestamp slot (Go 1.8.2's fix). A
  directory's depth ignores outer slashes (`a/b/` is 2, `/` is 0).
- `sas`: an unknown permission letter's error prints the rune as a
  number (`invalid permission character: '113'`), as Go's does.
- `UserDelegationKey.signed_delegated_user_tenant_id` (default `""`).
- The signing vectors are captured from v1.8.3.

## v0.1.0

The first port, of Go azblob v1.6.1.
