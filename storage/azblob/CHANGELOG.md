# azblob changes

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
