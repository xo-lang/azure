# azcontainerregistry

Azure Container Registry's data plane clients, for Xo: a port of Go's
`sdk/containers/azcontainerregistry` v0.2.3 (REST API version
2021-07-01).

What it does:

- `Client` (`new_client(net, clock, rand, endpoint, credential,
  options)`): repositories, tags and manifests. Pagers over
  repositories (`new_list_repositories_pager`), tags and manifests
  follow the registry's `Link` header. Properties are read and updated
  (`get_repository_properties`, `update_tag_properties`, ...), and
  repositories, tags and manifests deleted (a 404 is a success, as in
  Go). `get_manifest` and `upload_manifest` move a manifest's bytes.
- `BlobClient` (`new_blob_client`): blobs and their uploads.
  `start_upload`, then `upload_chunk(location, chunk, calculator,
  options)` for each chunk (with `range_start` and `range_end`, sent as
  `Content-Range`), then `complete_upload(location, calculator)`, which
  sends the SHA-256 digest of what was uploaded. A chunk that fails
  leaves the calculator's digest as it was. Also `get_blob`,
  `get_chunk`, `check_blob_exists`, `check_chunk_exists`, `delete_blob`,
  `mount_blob`, `get_upload_status` and `cancel_upload`.
- `AuthenticationClient`: the registry's token exchange.
- Authorization by the registry's challenge, as Go's policy: a request
  with no token is sent without its body, the 401 names the service and
  scope, an Entra ID token (scope `<audience>/.default`, by default
  `https://containerregistry.azure.net/.default`) is exchanged for a
  registry refresh token and that for an access token for the scope,
  and the request is sent again. The refresh token is cached until its
  JWT's `exp` (fetched again within 5 minutes of it, at most every 30
  seconds); the last access token is tried first on the next request. A
  credential of `None` asks for access tokens anonymously.
- `DigestValidationReader` and `validate_digest` check downloaded
  content against its `sha256:` digest; `BlobDigestCalculator` computes
  an upload's.
- The cloud's configuration names the audience: `cloud.AZURE_PUBLIC`,
  `AZURE_CHINA` and `AZURE_GOVERNMENT` work as they are (Go adds the
  registry to them at init), and a custom configuration needs a
  `SERVICE_NAME` entry with an audience, else the constructors fail with
  Go's message.

The operations and models are generated from the 2021-07-01 swagger at
Go's commit, with the directives of Go's `autorest.md` applied as JSON
patches (`codegen/custom/azcontainerregistry.toml`). The constructors,
the challenge policy, the chunk upload and the digest helpers are
written by hand.

The test replays a Go program's calls against the same fake registry
(which challenges every request without the access token for its
scope) and compares each request (method, URL, headers, body), each
Entra ID token asked for and each result, line for line. The refresh
token's window and backoff, which Go reads from `time.Now`, are tested
here on the fake clock.

Where it differs from Go v0.2.3:

- Bodies are whole `Bytes`: a manifest or chunk to upload, and a
  downloaded manifest, blob or chunk (Go's `io.ReadSeekCloser` and
  `io.ReadCloser`). `DigestValidationReader.read(data, eof)` takes the
  content as it comes; `validate_digest(digest, data)` checks it whole.
- A digest error is a `DigestErr` (`MismatchedHash`,
  `DigestAlgNotSupported`; Go's `ErrMismatchedHash` and
  `ErrDigestAlgNotSupported`).
- A service error from the token exchange is the call's
  `CallErr.Send(SendErr.FinalResponse(response))` (Go returns the token
  client's `ResponseError` from the policy); a credential's error is
  `SendErr.Auth`. A token response without its token is an `Auth`
  error, and a `Link` header without `>` reads to its end (Go panics on
  both).
- The generated `uploadChunk` and `completeUpload` (lower case in Go)
  are `raw_upload_chunk` and `raw_complete_upload`, with
  `RawBlobClientUploadChunkOptions`, so the public `upload_chunk` and
  `complete_upload` keep Go's names.
- The chunk parameter of `get_chunk` and `check_chunk_exists` is
  `range` (Go's `rangeParam`).
- Every request has an `x-ms-client-request-id` (decision 0003).
