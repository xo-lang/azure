# azblob changes

## Unreleased

- `BlockBlobClient.set_expiry` and `AppendBlobClient.set_expiry`
  (`ExpiryType`: `Absolute`, `RelativeToNow`, `RelativeToCreation` in
  whole milliseconds truncated as Go's, `Never`, the default as Go's nil).
  Checked against Go v1.8.3 on a fake service (`expiryvectors_test.xo`,
  10 cases).

- `ServiceClient`: `new_list_containers_pager` (`ListContainersInclude`,
  `ContainerItemInfo`, `ContainerItemProperties`), `create_container`,
  `delete_container`, `restore_container`, `filter_blobs`,
  `get_statistics` (`GeoReplication`) and
  `get_user_delegation_credential` (`KeyInfo`; the account is the URL's
  first host label, and its key's times are read as Go's
  datetime.RFC3339, a time without a zone in UTC), and
  `ContainerClient.filter_blobs` (`FilterBlobItem`). Checked against Go
  v1.8.3 on a fake service (`servicecallsvectors_test.xo`, 18 cases;
  the delegation credentials checked by the SAS they sign).

- `ContainerClient.new_list_blobs_flat_pager` and
  `new_list_blobs_hierarchy_pager` (container.Client's, in Go's default
  XML response format; its Apache Arrow format is not ported), with
  `ListBlobsInclude`, `BlobItemInfo`, `BlobItemProperties` (all 46 of
  Go's BlobProperties) and `BlobPrefixInfo`. The XML is read as Go's
  encoding/xml reads it: an encoded name is decoded, metadata keys are
  lowercased, a bad number, bool, time or MD5 fails the page, an empty
  one is unset (a number or bool 0 or false), Go's zero time is unset,
  and repeated `<Blobs>` and `<Properties>` merge. Checked against Go
  v1.8.3 on a fake service (`listblobsvectors_test.xo`, 18 listings).

- Blob batch (container and service BatchBuilder and SubmitBatch):
  `new_batch_builder` on `ContainerClient` and `ServiceClient`,
  `ContainerBatchBuilder` and `ServiceBatchBuilder` (`delete`,
  `set_tier`; one operation per batch, as Go's), and `submit_batch`,
  which builds Go's multipart/mixed body (a `batch_` UUID boundary, each
  sub-request signed by the client's credential policy alone, none for a
  SAS client) and reads the answer per sub-request as
  `BatchResponseItem` (its container, blob, request ID and error).
  Checked against Go v1.8.3 on a fake service (`batchvectors_test.xo`,
  13 cases: a missing blob, a short answer, a failed batch, no boundary,
  no Content-Type, a 403, a SAS client).

- `BlobClient` (blob.Client): `set_tier`, `undelete`,
  `start_copy_from_url`, `abort_copy_from_url`, `copy_from_url` (which,
  as Go's, drops `source_if_tags`), `create_snapshot`,
  `set_immutability_policy`, `delete_immutability_policy`,
  `set_legal_hold`, `get_account_info` and `get_sas_url` (a snapshot not
  in Go's `SNAPSHOT_TIME_FORMAT` is kept on the URL but not signed, as
  Go's), with the `REHYDRATE_PRIORITY_` constants. Checked against Go
  v1.8.3 on a fake service (`blobcallsvectors_test.xo`, 21 calls and 6
  SAS URLs).

- `AppendBlobClient` (appendblob.Client): `create`, `append_block`,
  `append_block_from_url` (source conditions, source key, range, copy
  source authorization, file request intent) and `seal` (which, as Go's,
  sends neither `x-ms-if-tags` nor the max size), its four constructors
  and `ContainerClient.new_append_blob_client`. Checked against Go
  v1.8.3 on a fake service (`appendvectors_test.xo`, 13 cases).
- `PageBlobClient` (pageblob.Client): `create`, `upload_pages`,
  `upload_pages_from_url`, `clear_pages`, the page range and page range
  diff pagers, `resize`, `update_sequence_number` and
  `start_copy_incremental`, its four constructors and
  `ContainerClient.new_page_blob_client`. Checked against Go v1.8.3 on a
  fake service (`pagevectors_test.xo`, 22 cases, two pagers of two
  pages).
- `BlockBlobClient.stage_block_from_url`, `upload_blob_from_url` and
  `get_block_list` (blockblob.Client.StageBlockFromURL,
  UploadBlobFromURL and GetBlockList), with `BlockListInfo`,
  `BlockInfo`, the `BLOCK_LIST_TYPE_` and `BLOB_COPY_SOURCE_TAGS_`
  constants and `SourceModifiedAccessConditions.source_if_tags` (sent
  only by `upload_blob_from_url`, as Go sends it). Checked against Go
  v1.8.3 on a fake service (`blocklistvectors_test.xo`, 16 cases: an
  empty body is an empty list, an empty `<Size>` is 0, a name is not
  trimmed).
- `parse_url` and `URLParts` (blob.ParseURL, sas.URLParts and its
  String as `to_url`), and `with_snapshot` and `with_version_id` on the
  blob, append blob, page blob and block blob clients. Checked against
  Go v1.8.3 on 92 URLs (`urlvectors_test.xo`, `withvectors_test.xo`).
- sas: `new_query_parameters` (sas.NewQueryParameters, the SAS keys
  taken out of a query), `QueryParameters.signed_delegated_user_tenant_id`,
  `start_format` and `expiry_format`; `encode` writes `st` and `se` in
  the layout they were read with and a user delegation key's six fields
  even when empty (Go's zero time as `0001-01-01T00:00:00Z`), as Go's
  Encode does.
- `AppendPositionAccessConditions`, `SourceModifiedAccessConditions`,
  `SourceCPKInfo`, `SequenceNumberAccessConditions`, `PAGE_BYTES`, the
  premium page blob tiers, the sequence number actions and
  `FILE_REQUEST_INTENT_BACKUP`.

## v0.1.0

The first tagged release: every module of github.com/xo-lang/azure is
tagged v0.1.0 at one commit.

Moved to the root module's azcore, unchanged: `exported.parse_go_url`,
`GoUrl` and its `to_str`, `go_query`, `go_escape_path`, `go_quote`,
`is_unreserved`, `has_byte` and `all_bytes` are `azcore.parse_go_url`,
... (so a data plane module reads URLs as Go's without depending on
storage). `exported.is_ip_endpoint` stays.

Tests only, no change to the module:

- The DownloadFile cases open the existing file as Go's program does
  (written first, then `Fs.open_rw`, Go's `os.OpenFile` with `O_RDWR`)
  instead of writing the old contents through a `create` handle.
- A new case from the same Go program: a blob that changes partway,
  downloaded over a longer file, leaves the file's later bytes as they
  were (`01234567 content here`), as Go's.

The tests need xo c8d1eb2f2 (`Fs.open_rw`) or later.

### Before the first release

Milestones of the port, never tagged; their numbers are not module
versions.

#### v0.12.0 (untagged milestone)

New: the block blob client and file transfers, as azblob v1.8.3's.

- `BlockBlobClient` (from a token, a Shared Key, no credential or a
  connection string, or `ContainerClient.new_block_blob_client`):
  `upload`, `stage_block`, `commit_block_list`, `upload_buffer` and
  `upload_file`, with Go's options and responses. Data of at most
  `MAX_UPLOAD_BLOB_BYTES` (256 MiB) goes in one Upload whatever the
  block size; more goes in blocks (the block size, or the size over
  `MAX_BLOCKS` and at least 4 MiB) with Go's block IDs (the base64 of a
  version 4 UUID), staged in order until one fails, then committed.
  The commit sends no access conditions and each block only the lease,
  as Go's.
- `BlobClient.download_file`: Go's DownloadFile, the blocks
  `download_buffer` asks for written into the file where they belong
  (`File.write_at`), then the file truncated to the bytes downloaded
  when its size differs. A failure leaves the blocks already written and
  does not truncate, as Go's.
- `TransferErr` is either one's error: the service's (`Call`) or the
  file's (`File`).
- Checked against Go on a fake service (`uploadvectors_test.xo`): every
  option of Upload, StageBlock and CommitBlockList, a denied upload,
  UploadBuffer, UploadFile small, empty and of 256 MiB and 5 bytes (65
  blocks), and seven DownloadFile cases (blocks, a range, an empty
  blob, a blob that changes between blocks, an offset past the end, a
  file longer than the blob and one the same size).
- Blocks go one at a time; Go's `Concurrency` is accepted and changes
  nothing. Each request body is held in memory (one block, or up to 256
  MiB for one Upload). Not ported: `Progress` and
  `TransactionalValidation`.

#### v0.11.0 (untagged milestone)

Behavior fix (URLs change): the `Client` calls and the list pagers
write the query as Go's generated request code does. The client URL's
query (a SAS) is parsed, the operation's parameters are set over it,
and the whole query is encoded sorted by key with a space as `%20`.
Before, the operation's parameters went first in their own order with
the SAS appended as written, and the next list page appended `marker`
to the end, so `?comp=block&blockid=YQ%3D%3D&sv=...&sig=...` went out
where Go sends `?blockid=YQ%3D%3D&comp=block&sig=...&sv=...`, and a
marker with a space was `+` where Go writes `%20`.

- Checked against azblob v1.8.3: both pages of the container and flat
  blob list pagers and a StageBlock, without and with a SAS
  (`listvectors_test.xo`). The calls built on `core.xo` already wrote
  the query this way.
- azqueue already did (its two list pages with a SAS checked against
  azqueue v1.0.1 in its `client_test.xo`).

#### v0.10.0 (untagged milestone)

Behavior fix: a response header that repeats is read as Go's
`resp.Header.Get` reads it, its first field. Before, the fields were
joined with `, `, so a repeated header read as `a, zz` and a repeated
number, date or boolean did not parse.

- Every response header the clients read, and each `x-ms-meta-*` and
  `x-ms-or-*` entry (Go's `Header.Get(hh)` on each name).
- The error code a call returns comes from azcore's reading (the root
  module): `x-ms-error-code`'s first field, and an empty first field
  reads the body's code, as Go's.
- Checked against Go azblob v1.8.3 (`repeated_headers_test.xo`), and
  each Go vector test reruns with every response header field repeated
  (a second field "zz"), which leaves Go's output unchanged.

#### v0.9.0 (untagged milestone)

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

#### v0.8.0 (untagged milestone)

- `exported.all_bytes`, `has_byte` and `is_unreserved` are public, for
  azdatalake's Go path escaping. azfile's sas time and IP helpers and
  azdatalake's quoting, escaping and IP-host helpers now call azblob's
  instead of keeping copies (they were the same code; no behavior
  change).

#### v0.7.0 (untagged milestone)

- `new_shared_key_credential`: a key that is not base64 reads
  `decode account key: ...`, Go's text in every storage module.
- `sas`: the SAS time layouts (`TIME_FORMAT*`), `parse_time`,
  `parse_layout`, `format_time_layout`, `ip` and `ip_range`, as Go's
  storage sas packages read and write a SAS, shared by azqueue.
- `exported.parse_go_url`, `GoUrl.to_str`, `go_escape_path`,
  `is_ip_endpoint` and `go_quote`: URLs read and written as Go's
  net/url does for storage URLs, shared by azqueue.

#### v0.6.0 (untagged milestone)

- `exported.new_storage_challenge_policy` and
  `exported.parse_storage_challenge`: Go's storage challenge policy (a
  401 bearer challenge naming a `resource_id` gets a token for that
  resource, kept for later calls), exported for azqueue and
  azdatalake. Every token client uses it, as in Go.
- `new_client` now reads `ClientOptions.audience` and
  `insecure_allow_credential_with_http`, as Go's azblob.NewClient
  passes them on to service.NewClient; it asked for Storage's scope
  before.

#### v0.5.0 (untagged milestone)

- `BlobClient.download_stream_with_response`: the download and the
  response it was read from (a 304's too), for a client that reads
  more of its headers (azdatalake's file download reads its encryption
  context and ACL from it).

#### v0.4.0 (untagged milestone)

- `BlobClient.get_properties_with_response`: the properties and the
  response they were read from, for a client that reads more of its
  headers (azdatalake's paths read their owner and ACL from it).

#### v0.3.0 (untagged milestone)

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

#### v0.2.0 (untagged milestone)

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

#### v0.1.0 (untagged milestone)

The first port, of Go azblob v1.6.1.
