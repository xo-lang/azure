# azdatalake changes

## v0.2.0

Paths and ACLs, at Go azdatalake v1.7.1 parity on captured vectors.

- `DirectoryClient` and `FileClient`: constructors (token, Shared Key,
  no credential, connection string, and from a file system or a
  directory), create, delete, properties, rename, access control,
  system properties, metadata, HTTP headers and tags; a file's expiry
  and its ACL update and removal.
- The recursive ACL changes on a directory, with Go's paging,
  continue-on-failure stop and failed-entry totals.
- `ServiceClient` and `FileSystemClient` keep how to make a blob client
  with their credential, for the paths they make.

## v0.1.0

The first port, of Go azdatalake v1.7.1: the service and file system
clients' calls that go to azblob, and the file system, path, directory
path and deleted path list pagers on azdatalake's own pipeline, checked
against Go's requests and responses on captured vectors.
