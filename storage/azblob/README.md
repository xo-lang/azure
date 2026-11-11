# azblob

Azure Blob Storage for Xo, a port of parts of Go's `sdk/storage/azblob`
v1.8.3 (REST API version 2026-12-06).

What it does:

- `Client`: containers (create, delete, list), whole blob upload and
  download, blob properties and metadata, delete, block staging with a
  commit list and the block list, and the container and blob list
  pagers. Hand written ahead of the generator; its calls are a
  convenience shape, not yet Go's container, blob and block blob
  clients.
- Go's clients, beside `Client` (which keeps its shape):
  `ServiceClient` (properties, account info, account SAS URL),
  `ContainerClient` (create, delete, restore, properties, metadata,
  access policy, account info, SAS URL), `BlobClient` (properties, HTTP
  headers, metadata, tags, delete, `download_stream`,
  `download_buffer`, `download_file`), `BlockBlobClient` (`upload`,
  `stage_block`, `commit_block_list`, `upload_buffer`, `upload_file`),
  `AppendBlobClient` (`create`, `append_block`, `append_block_from_url`,
  `seal`; the other blob calls through `blob_client()`),
  and `BlobLeaseClient` and `ContainerLeaseClient`
  (acquire, break, change, release, renew). Each is built from a token,
  a Shared Key, no credential, or a connection string, as Go's are, and
  every request and response is checked byte for byte against Go
  v1.8.3 on a fake service.
- `exported`: Shared Key (`SharedKeyCredential` and its policy, checked
  against Go's signer on captured vectors) and the user delegation
  credential.
- `sas`: account, service (container, blob, snapshot, version,
  directory) and user delegation SAS, every case checked against Go's
  `sas` package (`sas/testdata/sas_vectors.json`).

Where it differs from Go v1.8.3:

- `BlobSignatureValues.signed_request_headers` and
  `signed_request_query_parameters` (`srh`, `srq`) are lists, signed in
  the caller's order. Go takes maps and signs them in map order, so with
  two or more entries its SAS varies from run to run
  (Azure/azure-sdk-for-go#27964).
- Not ported yet: `ClientOptions.ExpectContinueBehavior` (Go sends
  `Expect: 100-continue` for a minute after a 429, 500 or 503). It comes
  with Go's default once Xo's std can send that header.
- `set_tags` writes the tags in key order; Go writes its map in map
  order, so with two or more tags its body varies from run to run.
- `download_buffer` returns the bytes rather than filling a caller's
  buffer, and asks for its blocks one at a time in order (Go asks five
  at a time). Its requests are Go's.
- `upload_buffer` and `upload_file` stage their blocks one at a time in
  order (Go runs `Concurrency` at once; the option is accepted), and
  hold each request's body in memory: one block, or the whole data for
  one Upload (up to 256 MiB). `download_file` writes its blocks the same
  way. `Progress` and `TransactionalValidation` are not ported.
- A download reads its whole body, so there is no retry reader: a
  failed read is a failed send, which the retry policy repeats.
- Go's `DownloadStreamResponse.ObjectReplicationRules` list is never
  filled (its parser looks for `or-` after the prefix is gone,
  Azure/azure-sdk-for-go#27966);
  `object_replication_rules` here is the map of `x-ms-or-*` headers,
  as Go's generated response holds them. A download has no smart
  access tier, as Go's public download response has no field for it
  (Azure/azure-sdk-for-go#27965).
- Container calls take `ContainerConditions` (the two dates), the ones
  Go's options pass on; container `set_metadata` sends only
  If-Modified-Since, as Go's does.
- Not ported yet: `blob.ParseURL` and `URLParts`, `with_snapshot` and
  `with_version_id`, a blob SAS URL, structured message (transactional CRC64) downloads,
  the container and blob pagers on the new clients, the block blob
  client's other calls (`get_block_list`, `upload_stream`,
  `upload_blob_from_url`, `stage_block_from_url`, ...), the page blob
  client, batch, and checksummed uploads and appends
  (`TransactionalValidation`, `SourceContentValidation`). The append
  blob client's forwarders to the blob calls (`delete`, `set_tags`,
  ...) are reached through `blob_client()`.
- Go names that are Xo keywords: none in what is ported (the lease
  calls are Go's `AcquireLease` to `RenewLease`, so `break_lease` is
  Go's own name).

Changes: [CHANGELOG.md](CHANGELOG.md).
