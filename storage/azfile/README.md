# azfile

Azure Files for Xo, a port of Go's `sdk/storage/azfile` v1.7.1 (REST API
version 2026-06-06).

What it does:

- `ServiceClient` and `ShareClient`, with Entra ID tokens (the Storage
  scope or `ClientOptions.audience`), the account key (azblob's
  `SharedKeyCredential` and policy, which is azfile's signer too), no
  credential (a SAS in the URL), or a connection string (`AccountName`
  with `DefaultEndpointsProtocol` and `EndpointSuffix`, or
  `FileEndpoint`; `AccountKey` or `SharedAccessSignature`).
- The service's properties (hour and minute metrics, CORS, SMB
  multichannel and encryption in transit, NFS encryption in transit),
  the share list pager (metadata, snapshots and deleted shares), a user
  delegation credential, and creating, deleting and restoring shares.
- A share's create (tier, protocols, quota, root squash, paid bursting,
  provisioned IOPS and bandwidth), delete (with snapshots, leased ones
  too), properties, snapshots, metadata, statistics, stored access
  policies and share-level permissions (SDDL); `with_snapshot`.
- `DirectoryClient` (from a share, a parent, a URL or a connection
  string): create, delete, properties, metadata, rename (to a path in
  the same share, a `?query` after it replacing the SAS), the files and
  directories pager (timestamps, ETags, attributes, permission keys,
  extended info) and handles (list, force close). SMB properties (NTFS
  attributes, times), NFS properties (mode, owner, group; sent instead
  of SMB ones and permissions when set) and permissions (SDDL or a key)
  as Go formats them: a directory's attributes get `|Directory`, and a
  permission key other than `inherit` or `preserve` sends the format
  as `Sddl`.
- `FileClient` (from a directory, a URL or a connection string): create
  (SMB or NFS properties, permissions, HTTP headers, Content-MD5),
  delete, properties (a HEAD: HTTP headers, copy, lease and link
  state), set HTTP headers, resize, metadata, start and abort copy (SMB
  info with `source` values, or NFS copy modes), rename (with source and
  destination leases), handles, and hard and symbolic links (NFS
  shares). A file's create sends both a permission and a key when given
  and defaults the format to `Sddl` for a permission alone; a symbolic
  link sends its metadata only with NFS properties; the link calls send
  no trailing dot header. Each response reads the headers Go's handler
  for that call reads.
- The file's data: `upload_range` (with a transactional MD5 and a last
  written mode), `clear_range`, `upload_range_from_url` (source
  authorization and CRC64 checks), `get_range_list`, `download_stream`
  and the chunked `download_buffer` and `upload_buffer`. Ranges format as
  Go's (`bytes=10-14`, `bytes=3-` to the end), and a count of 0 from a
  URL sends Go's empty destination range.
- Leases: `new_share_lease_client` (acquire for 15 to 60 seconds or -1,
  break with a period, change, release, renew, each on a snapshot too)
  and `new_file_lease_client` (acquire, always infinite, break, change,
  release). With no ID given the client proposes a random UUID, as Go's
  does; `change` updates the client's `lease_id` once it succeeds. A
  break's `lease_id` is a condition, not the client's ID, as in Go.
- `ClientOptions.file_request_intent` (`backup`) on the share calls,
  not the service's, as Go's generated clients send it; the trailing dot
  options on directory calls.
- `fileerror`: the error codes and `has_code`.
- `sas`: account SAS for the File service (`rwdlc`, `sco`), share and
  file SAS (`rcwdl`, `rcwd`) signed with the account key or a user
  delegation key (the delegated user's tenant as `skdutid`), and
  `new_query_parameters`, which reads a SAS out of a query as Go does: the
  first value of each key matched without case, each time in the first
  of Go's four layouts that reads it (and written back in it), each
  address as Go's net.ParseIP keeps it. `get_sas_url` on the service,
  share and file clients signs with the client's key and appends the
  SAS as Go does (an account URL gets a trailing slash; a query and a
  fragment are kept). A share snapshot is not signed: the File service's
  string to sign has no snapshot field (only Blob's has one since
  2018-11-09), so a snapshot URL keeps its `sharesnapshot` beside the
  SAS, as Go writes it.
- `parse_url` splits a file service URL as Go's sas.ParseURL does
  (url.Parse's rules and errors; on an IP host, as IsIPEndpointStyle
  sees one, the first segment is the account, as Azurite's), with its
  SAS in `sas`, and `to_url` writes it back as url.URL does
  (`urlvectors_test.xo`).

Each request is Go's byte for byte: the test replays a Go program's
calls against the same fake service and compares every request
(method, URL, headers with the Shared Key signature, body) and a dump
of every field Go read back.

Where it differs from Go v1.7.1:

- A caller's `x-ms-date` is kept. Go's signer looks the header up by its
  lowercase name in a canonicalized header map, so it never sees one and
  always signs its own clock's date.
- Options are Xo's: optional values are `T?` with `None` for Go's nil,
  enums are string constants, a lease condition is a `lease_id`
  parameter, and responses keep the request ID and version in
  `.response`.
- A path is escaped segment by segment when `to_url` writes it; Go's
  url.URL also leaves `$&+,;=:@` unescaped.
- A response header that does not parse (a time, a number, a bool) reads
  as `None`; Go's generated client returns an error.
- Create has no optional body (Go's `OptionalBody` and `ContentLength`);
  data goes through the range calls.
- A download's body is read whole (Go returns a stream with a retry
  reader); `download_buffer` returns the bytes instead of filling a
  buffer, and it and `upload_buffer` send their chunks one at a time
  (Go's run in parallel; each request is the same). `UploadFile`,
  `UploadStream`, `DownloadFile` and progress callbacks are not ported:
  `upload_buffer` and `download_buffer` cover them. Go's unused
  `UploadRangeFromURLOptions.SourceContentCRC64` field is left out.
- Lease `Break` is `break_lease` (`break` is a keyword). A lease client
  always holds an ID, so Go's "leaseID cannot be nil" errors cannot
  occur.
- SAS permissions and resource types are letters (put in the
  service's order; an unknown one is Go's parse error), not Go's flag
  structs, and an IP range is a string. `sign_with_user_delegation`
  takes a credential, so Go's nil credential error cannot occur.
- `new_query_parameters` reads keys in the query's order: when `st` and
  `skt` (or `se` and `ske`) are in different layouts, the last one read
  sets the layout both are written in. Go reads them in map order, so
  its choice varies from run to run. A time outside the range of
  Xo's Time reads as no time, where Go keeps it.
- Go names that are Xo keywords: the lease clients' `Break` is
  `break_lease`.
