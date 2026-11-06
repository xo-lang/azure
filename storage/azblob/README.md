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
  two or more entries its SAS varies from run to run.
- Not ported yet: `ClientOptions.ExpectContinueBehavior` (Go sends
  `Expect: 100-continue` for a minute after a 429, 500 or 503). It comes
  with Go's default once Xo's std can send that header.
- Not ported yet: Go's container, blob, block blob, append blob, page
  blob and lease clients, batch, and the parallel and checksummed
  transfers.

Changes: [CHANGELOG.md](CHANGELOG.md).
