# azdatalake

Azure Data Lake Storage Gen2 for Xo, a port of Go's
`sdk/storage/azdatalake` v1.7.1 (over azblob v1.8.3, REST API version
2026-12-06). In progress: the service and file system clients come
first; paths, ACLs, file data, leases and SAS follow.

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
- Not ported yet: `GetUserDelegationCredential`, `GetSASURL`, the
  directory, file and path clients, ACLs, leases, `ParseURL` and
  `datalakeerror`.
- Go names that are Xo keywords: none in what is ported.

Changes: [CHANGELOG.md](CHANGELOG.md).
