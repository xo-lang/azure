# azdatalake changes

## v0.6.0

- `datalakeerror`: Go azdatalake v1.7.1's error codes, `has_code` and
  its error messages. Each of Go's azdatalake packages now has its Xo
  form; what is not ported within them is listed in the README.

## v0.5.0

SAS, at Go azdatalake v1.7.1 parity on captured vectors.

- The `sas` package: `DatalakeSignatureValues` (file system, directory
  and file SAS, with the account key or a user delegation key) and
  `AccountSignatureValues`, over azblob's signer.
- `get_sas_url` on the service, file system, directory and file
  clients; `ServiceClient.get_user_delegation_credential` (`KeyInfo`);
  `parse_url` and `URLParts`.

## v0.4.0

Leases, at Go azdatalake v1.7.1 parity on captured vectors.

- `FileSystemLeaseClient` and `PathLeaseClient` (a directory's or a
  file's): acquire, break, change, release and renew, with Go's
  condition mapping and DFS error codes.

## v0.3.0

File data, at Go azdatalake v1.7.1 parity on captured vectors.

- `FileClient.append_data`, `flush_data`, `upload_buffer`,
  `download_stream` and `download_buffer`, with Go's lease actions
  (`LEASE_ACTION_*`), `MAX_APPEND_BYTES` and `MAX_FILE_SIZE`.
- Needs azblob v0.5.0 (`download_stream_with_response`).

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
