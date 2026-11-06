# azdatalake

Azure Data Lake Storage Gen2 for Xo, a port of Go's
`sdk/storage/azdatalake` v1.7.1 (over azblob v1.8.3, REST API version
2026-12-06). In progress: the service, file system, directory and file
clients' path, ACL and file data calls are ported; leases and SAS
follow.

What it does:

- `ServiceClient` and `FileSystemClient`, with Entra ID tokens, the
  account key (azblob's `SharedKeyCredential`), no credential (a SAS in
  the URL) or a connection string. A client takes the dfs or the blob
  URL and keeps both (`dfs_url`, `blob_url`), as Go's `GetURLs` maps them
  (the first `.dfs.` and `.blob.` swapped).
- The service's properties, and creating and deleting file systems.
- A file system's create (access, metadata, default encryption scope),
  delete, properties, metadata and access policy. Each is azblob's
  container call on the blob URL, with Go's options mapping: no ETag
  condition is sent, a delete or an access policy sends the lease and
  the two dates, set_metadata the lease and If-Modified-Since.
- The list pagers: file systems (`new_list_file_systems_pager`, with
  metadata, deleted and system ones), paths (`new_list_paths_pager`,
  the dfs list, recursive or not, with a continuation), and directory
  and soft-deleted paths (`new_list_directory_paths_pager`,
  `new_list_deleted_paths_pager`). As Go's, they go through azdatalake's
  own pipeline: the file system and hierarchy lists on the blob URL, the
  path list on the dfs URL, each with azdatalake's REST API version
  (2026-06-06, where azblob's calls send 2026-12-06).
- `DirectoryClient` and `FileClient`, with the same four constructors,
  or from a file system (`new_directory_client`, `new_file_client`), a
  directory (`new_file_client`, `new_subdirectory_client`) or a
  connection string. Each path's dfs calls go through azdatalake's
  pipeline: create (permissions, umask, owner, group, ACL, a proposed
  lease, a file's expiry and encryption context), delete (a directory's
  follows each continuation until it is gone), rename (a create in
  legacy mode; the destination URL rebuilt as Go's `sas.URLParts` writes
  it, SAS parameters re-encoded), get and set access control, system
  properties, and a file's expiry, ACL update and ACL removal. Its other
  calls are azblob's on the blob URL: properties (with the owner, group,
  permissions, ACL, resource type and encryption context read from the
  same response), metadata, HTTP headers and tags.
- The recursive ACL changes (`set_`, `update_` and
  `remove_access_control_recursive`) page as Go's helper does: while the
  service returns a continuation and `max_batches` allows, adding up
  each page's counts and failed entries in order, and, without
  `continue_on_failure`, stopping with no error after the first page
  with failures. A failed request returns the totals so far with the
  error (`AccessControlRecursiveErr`).
- A file's data calls: `append_data` and `flush_data` on the dfs URL
  (Go's defaults: a flush always sends `close` and
  `retainUncommittedData`, false when unset), `upload_buffer` (appends
  of `chunk_size`, 100 MiB by default, then a flush at the length; with
  an encryption context it creates the file first and deletes it if an
  append fails), and `download_stream` and `download_buffer`, azblob's
  on the blob URL, with a download's encryption context and ACL read
  from the same response.
- A dfs response header that does not parse (a bool, a number, a date)
  fails the call, as Go's generated handlers do, with Go's error text.
- Every error code as Go's `ConvertToDFSError` renames it (`blob` to
  `path`, `container` to `filesystem`: `ContainerNotFound` is
  `FileSystemNotFound`).

Where it differs from Go v1.7.1:

- One package: Go's `service` and `filesystem` packages' names get
  their noun (`CreateFileSystemOptions`, `FileSystemPropertiesResponse`,
  `SetFileSystemMetadataOptions`).
- As in Go, a file system's blob calls ask for the default storage
  token scope even with `ClientOptions.audience` set: Go gives its
  container client the pipeline options only.
- `ListHierarchyPathsOptions` is the options of both hierarchy lists
  (Go has `ListDirectoryPathsOptions` and `ListDeletedPathsOptions`,
  the same three fields), and every pager is a `DfsPager`, which maps
  each error as Go's do.
- As Go's decoder does, a listed file system's metadata names are
  lowercased, and a path's `contentLength` and `isDirectory` (JSON
  strings) that do not parse are 0 and false.
- The path options and responses Go's `directory` and `file` packages
  share get the noun `Path` (`DeletePathOptions`, `CreatePathResponse`,
  `PathPropertiesResponse`); Go's `GetAccessControlResponse` is
  `AccessControlResponse`, its `SetAccessControlResponse` and a file's
  `SetExpiryResponse` are `PathETagResponse`, and one directory
  `AccessControlRecursiveOptions` stands for Go's three (the same four
  fields). `set_http_headers` takes the conditions, not an options
  struct of one field.
- As in Go, a recursive ACL change's totals do not say where it stopped
  (upstream draft 24), and a directory's delete follows continuations
  while a file's returns its one.
- A recursive ACL page without one of its three counts is an error with
  the totals so far; Go panics there (upstream draft 25).
- As in Go, an expiry with a time but no type sends an empty
  `x-ms-expiry-option` (upstream draft 26).
- A dfs date header that does not parse gives Go's error text up to the
  layout (`parsing time "x" as "Mon, 02 Jan 2006 15:04:05 MST"`), not
  the part after it that names the element.
- Rename rebuilds a source URL's SAS as Go does, except that a query Go
  parses only in part (a bad escape, a `;`) is dropped whole here.
- The file data calls take and return bytes, as azblob's and azfile's
  do: `download_buffer` returns the bytes rather than filling a buffer,
  and `upload_buffer` and `download_buffer` send their chunks one at a
  time in order (Go's run in parallel, so after a failed chunk Go may
  already have sent later ones; the requests are the same). `UploadFile`,
  `UploadStream`, `DownloadFile`, progress callbacks, concurrency, the
  retry reader and transactional validation (CRC64, structured
  messages) are not ported. A download's body is read whole, as in
  azblob.
- As in Go, `upload_buffer` of an empty buffer is an error: its one
  empty append fails. A negative `chunk_size` is an error here (Go
  would try to make that many chunks).
- A flush leaves out `HTTPHeaders.content_language`, as Go's does (its
  TODO for Azure/azure-sdk-for-go#27522). Go's `CPKScopeInfo` on a
  download is left out: its blob download drops it.
- Not ported yet: leases, `GetUserDelegationCredential`, `GetSASURL`,
  `ParseURL` and `datalakeerror`.
- Go names that are Xo keywords: a failed ACL entry's `Type` is
  `entry_type`.

Changes: [CHANGELOG.md](CHANGELOG.md).
