# aztables

Azure Tables for Xo (Azure Storage tables and Azure Cosmos DB for
Table), a port of Go's `sdk/data/aztables` v1.4.1 (REST API version
2019-02-02).

What it does:

- `ServiceClient` and `Client`, with Entra ID tokens (the Cosmos
  audience for a Cosmos endpoint, Storage's otherwise), the account key
  (SharedKeyLite), no credential (a SAS in the URL), or a connection
  string. `new_client*` take a table URL and split it as Go's parseURL
  does (Azurite's `127.0.0.1:10002/devstoreaccount1/t1` included).
- Tables: create, delete, and the list pager (`NextTableName`).
- The service's properties (logging, metrics, CORS) and statistics.
- Entities as JSON text: add, get (with `$format`), update (merge or
  replace, If-Match `*` unless given), upsert, delete, and the list
  pager (`NextPartitionKey` and `NextRowKey`, `$filter`, `$select`,
  `$top`).
- A table's stored access policies.
- Transactions: `submit_transaction` with add, update and insert
  (merge or replace) and delete actions in one changeset.
- Cosmos endpoints (`.table.cosmos.`, `.table.cosmosdb.`, or localhost
  with 8902): a PATCH goes as a POST with `X-HTTP-Method: MERGE`, in a
  batch too.
- Table SAS (with a key range), account SAS for the Table service,
  `get_table_sas_url` and `get_account_sas_url`; the error codes and
  `has_error_code`.

Each request is Go's byte for byte: the test replays a Go program's 28
requests against the same fake service and compares the method, host,
path and query as sent, headers with the SharedKeyLite signature, and
the body (the batch's multipart body with its boundaries numbered), and
what is read back.

Where it differs from Go v1.4.1:

- An entity's integers keep every digit. Go decodes an entity into
  `map[string]any`, so every number is a float64 and `9007199254740993`
  is sent as `9007199254740992`. Keys are still sorted and `<`, `>`,
  `&`, U+2028 and U+2029 escaped, as Go's re-encoding writes them.
- A table SAS sends its key range. Go signs `spk`, `srk`, `epk` and
  `erk` but leaves them out of the query, so the service cannot verify
  the signature (Azure/azure-sdk-for-go#27957).
- `get_table_sas_url` puts a `/` before the table name (Go writes
  `https://acct.table.core.windows.nett1`, Azure/azure-sdk-for-go#27958).
- A key with a `'` is doubled in a transaction too, as the single
  entity calls double it (Go leaves it as it is in a batch, which ends
  the key literal early).
- A connection string with a SharedAccessSignature uses the
  `TableEndpoint` (or protocol and suffix) it names; Go always uses
  `https://<account>.table.core.windows.net` for a SAS.
- `UpdateEntityOptions` and `UpsertEntityOptions` default to merge. In
  Go a zero options struct has an empty mode, which is "invalid
  EntityUpdateMode"; `update_mode: ""` is the same error here.
- An unknown transaction action type is an error (Go dereferences a nil
  request).
- Times are instants: a SAS time is always UTC (Go writes a time in
  another zone in that zone with a `Z` appended).
- Kept as Go sends them: each batch part's `DataServiceVersion` and
  `x-ms-version` lines go with empty values (Go reads keys it set
  without canonicalizing them through `Header.Get`); the service takes
  them.
- Options are Xo's: optional values are `T?`, `$select` is
  `select_fields` (`select` is a keyword), permissions are structs with
  `display()` or letter strings, and errors are `azcore.CallErr`
  (`InvalidInput` for what Go returns as plain errors).
- Go names that are Xo keywords: the options' `Select` is
  `select_fields`.
