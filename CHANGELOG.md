# Root module changes

Changes to the root module (`github.com/xo-lang/azure`: `azcore`,
`runtime`, `policy`, `cloud` and the other packages at the root), newest
first. Each module under it (`storage/azblob`, `data/azcosmos`, ...) keeps
its own CHANGELOG. Every module requires the root at v0.1.0; no root
version has been tagged since.

## Unreleased

batch/azbatch v0.1.0, Go's azbatch v0.1.0. The generator (`codegen`),
for it: a TypeSpec data plane module's `@client` block without a
language scope and its members' inline `@clientName` for Go;
`custom/<module>.toml` `param_names`, `header_names`,
`merge_update_variants` and `patch_twins`; `private_ops` on pagers;
typed response headers (`Int`, `Bool`, `Time`) and RFC 1123 header
parameters as `Time` (`runtime.parse_rfc1123_header`,
`runtime.rfc1123_header_text`, written in UTC as Go's); a binary
TypeSpec response's `content_type`; a JSON body's Content-Type from
the operation's one consumed type; `type: file` as binary; a doc's
IPv4 example outside the ranges check-public allows written in
192.0.2.0/24 (azbatch's `BatchNetworkSecurityGroupRule`). armstorage
v4: the three `FileShareProperties` downgrade times are
`azcore.DateTimeRFC7231`, as Go's `datetime.RFC7231` (were `Str`). No
other module changed.

messaging/azwebpubsub v0.1.0, Go's azwebpubsub v0.1.1. The generator
(`codegen`), for it: `custom/<module>.toml: [[replace]]` (a regular
expression and its replacement over the generated text, as Go's
autorest.md `where: $` directives), `Accept` with only the JSON types
when an autorest operation produces JSON and other types (Go's
`application/json, text/json` for generateToken), and an autorest data
plane module's empty-parameter errors in Go's casing
(`connectionID`). No other module changed.

`policy.Request.host`: the Host sent in place of the URL's (Go's
`Request.Raw().Host`), for azidentity's token proxy; needs xo 6797f91ba
or later (`http.Request.with_host`).

The generator (`codegen`), for messaging/eventgrid/azsystemevents:
`all_definitions` (a models only TypeSpec module keeps every
definition), `drop_models` (Go's hand written replacements),
`event_types` (Go's `system_events.go` constants, from each event's
data type doc), TypeSpec renames that are unscoped, spread into a
model, or for other emitters only (`not_go_fields`: undone for Go),
`field_types` for a field of any type, and Go's unexported types
(`internalACSRouterCommunicationError`) emitted UpperCamel without
`pub`. No other module changed.

The SSE test reads a streamed response as the FakeNet server flushes
it (the server's second event waits until the reader has returned the
first); needs xo 3b2e4b78d or later, whose FakeNet sends an
`http.stream` body flush by flush.

The generator (`codegen`), for ai/azopenai: `keep_definitions` (Go's
autorest.md filter of definitions by name), a hand written type for a
field of an `x-ms-external` type (`field_types` by `model.field`), and
a polymorphic type's base variant written with its discriminator null
when unset, as Go's base MarshalJSON writes it (armauthorization,
armnetwork and armstorage regenerated).

Server-sent events, as azcore v1.24.0:

- `streaming`: `SSEReader[T, fx]` (`new_sse_reader`, `next`,
  `last_event_id`, `close`) over a `Body` read as it arrives, with Go's
  parser (CRLF, LF and a lone CR, a BOM on the first line, comments,
  `event`, `data`, `id` and `retry`, a 1 MiB line limit), its decoder
  results (`Decoded.Event`, `Final`, `Stop`) and its reconnection (the
  server's `retry` or the reader's delay, the cursor passed to the
  connector). `SSEFrame`, `SSEHandler`, `SSEReaderOptions`, `SSEErr`,
  `StreamBody` and `bytes_body`.
- `policy.Request.stream` (a `policy.StreamSlot`): the transport sends
  such a request with `http.Client.open` and leaves a response below
  400 on the stream, as azcore's SkipBodyDownload; an error response is
  read whole. `runtime.streamed(req)` adds the slot.
- `runtime.sse_response`: Go's SSEResponse (a 204 is the end, a status
  outside the operation's is its ResponseError, a Content-Type other
  than `text/event-stream` is refused with Go's message).

`runtime.with_query`: a generated operation's URL with its query
parameters set on a query the joined URL already has, as Go's generated
`reqQP := req.Raw().URL.Query(); reqQP.Set(...)` does (the whole query
encoded again, keys sorted). Every generated module now builds its
request URLs with it: before, an endpoint with a query (or Container
Registry's upload Location, `...?_state=...`) got a second `?` for the
operation's parameters. A URL without a query is unchanged.

`azcore.DateTimeUTC`: a `date-time` read as `azcore.DateTime` reads it
(the offset kept in `offset`) and written in UTC, as Go's TypeSpec
emitter writes an ARM module's times (`populateTime` with `utc`).

Decision 0009 (TokenCredential's effect parameter; needs xo 86dd0ce25 or
later: fb952a75a runs an effect-generic struct's method through an
interface on the native backends, and 86dd0ce25 is xo decision 0540):

- `azcore.TokenCredential[fx]`, `policy.Policy[fx]`, `policy.Next[fx]`,
  `policy.ClientOptions[fx]`, `runtime.Pipeline[fx]`,
  `runtime.BearerTokenPolicy[fx]`, `runtime.TokenCache[fx]`,
  `runtime.Pager[T, fx]` and `runtime.Poller[T, fx]`: a credential
  whose token requests do more than the network (Azure Arc reads a key
  file) passes that through to the clients built with it. Every
  credential so far is a `TokenCredential[()]`, and a caller passing one
  changes nothing.
- Every client constructor, generated and hand-written, names one effect
  parameter (`new_x[fx: Effects](..., cred: azcore.TokenCredential[fx],
  opts: ClientOptions[fx] = ...) -> X[fx]`), so the credential's and the
  options' effects are one. A caller's own type that fixes a client's
  effects writes `Client[()]`.
- A policy is a plain struct whose `send` takes `next: policy.Next`
  (xo decision 0540: a parameter written without its effect argument
  satisfies `Policy[fx]`'s `next: Next[fx]`). The phantom effect
  parameter each policy carried before 0540 (`struct P[fx: Effects]`,
  23 types in 32 declarations) is gone. A caller's list of its own
  policies is still written `List[policy.Policy[()]]`: that is the type
  a pure client's options hold, and `List[policy.Policy]` would leave
  its effects open.

Go's azcore v1.23.0 to v1.24.0 (checked against the lines a Go program
prints with azcore v1.24.0, `arm/resourceid_vectors_test.xo`):

- `arm.ResourceID` and `arm.ResourceType` (`parse_resource_id`,
  `parse_resource_type`, `new_resource_type`, `is_parent_of`,
  `append_child`, `ROOT_RESOURCE_ID` and the subscription, resource
  group, tenant and provider types): Go's `arm.ParseResourceID` and
  `arm.ParseResourceType`, with Go's errors, new to this port. A
  `locations` segment in any case sets `location` (v1.23.3).
- `ResourceID.validate_resource_type_chain`: Go's
  `ValidateResourceTypeChain` (v1.24.0), the ID's whole type ancestry
  from the tenant down compared ignoring case, with Go's messages.
- `azcore.parse_date_time` reads a time's offset with std's
  `Time.rfc3339_offset` (xo 25bbebd9a or later) instead of its own
  parse; the results are unchanged.
- `ResponseError`'s text and `status_text` use std (xo 9eb0bf0a6 or
  later; required from here on): `json.indent` keeps a body's trailing
  white space as Go's does, so azcore no longer adds it back (on an
  older xo it would now be missing), and `status_text` is
  `http.status_text` (the same text for every code 0 to 999). The text
  is unchanged.

Not ported from v1.24.0 (this port has no logging or tracing policies):
the log sanitizer and tracing attribute changes. The `streaming` SSE
reader is planned as its own change.

Go's zero time (year 1, which services send for "unset"; Xo's `Time`
covers 1677 to 2262 by design, ADR 0364) is recognized in one place:

- `azcore.is_go_zero_time`, `is_go_zero_time_rfc3339` and
  `is_go_zero_time_rfc1123` match its text (any all-zero fraction, `Z`
  or a zero offset or none; an HTTP date with any weekday and `GMT` or
  `UTC`), and `azcore.GO_ZERO_TIME_RFC3339` writes it. azqueue's own
  copies, azservicebus admin's text match and azdatalake's literal now
  use them.
- **Behavior change** (`messaging/azservicebus/admin`): an entity time
  of `0001-01-01T00:00:00Z` (or with a zero fraction or offset) is
  None, as `0001-01-01T00:00:00` was. It was a parse error; Go reads it
  as its zero time.

`security/keyvault/azsecrets` follows Go's azsecrets v1.5.1 (was
v1.4.0), checked against the lines a Go program prints with v1.5.1
(`govectors_test.xo`):

- API version `2026-04-01` (was `7.6`), from the spec at
  azure-rest-api-specs 569464e8c8b0 (`specification/keyvault/data-plane/Secrets`).
- `GetSecretOptions.out_content_type` (the `outContentType` query) and
  `ContentType` with `CONTENT_TYPE_PEM` and `CONTENT_TYPE_PFX`.
- `previous_version` on `Secret` and `DeletedSecret`.
- **Behavior change**: `purge_deleted_secret` sends no `Accept`
  (v1.4.0's emitter sent it on every operation), and a space in the
  query is `%20`, not `+`, as v1.5.1's emitter writes it.

Go's CHANGELOG for v1.5.1 says the API version can be selected
(`serviceVersion`); in Go's code that is `azcore.ClientOptions.APIVersion`,
here `ClientOptions.client.api_version`, which sends it as Go does (a
vector with `2025-07-01`).

**Breaking**: `resourcemanager/keyvault/armkeyvault` matches Go's
armkeyvault/v2 v2.1.0, which Go now generates from TypeSpec (API
version 2026-05-15; Microsoft.KeyVault/KeyVault at the commit of Go's
tsp-location.yaml). Checked against Go's module: all 48 operations'
requests, every method's parameters in order, all 93 models' JSON keys,
every type name (`Secret` is `SecretModel`, as before) and all 28
enums with their values and order equal; its Go-backed vectors
re-recorded from v2.1.0. As in Go, `get_deleted` and
`begin_purge_deleted` take the name before the location. The Xo module
path is unchanged (decision 0001).

**Breaking**, armstorage, armcompute, armnetwork and armkeyvault, as Go
v4.3.0, v9.0.0, v12.1.0 and v2.1.0: their `date-time` fields are
`azcore.DateTimeUTC`, written in UTC; a PUT's or PATCH's optional body
is a parameter of the method (armstorage's `TableClient.create` and
`update`, `BlobContainersClient.create_or_update_immutability_policy`;
armnetwork's `IpamPoolsClient.update`,
`StaticCidrsClient.create`, `VerifierWorkspacesClient.update`);
`DeletedAccountsClient.get` takes the name before the location, and
`PrivateLinkServicesClient.begin_check_private_link_service_visibility_by_resource_group`
the location before the resource group. Every method's parameters were
compared with Go's in order. The generator: `utc_date_times` in
services.toml, `param_order` in custom TOML.

**Breaking**: `resourcemanager/resources/armresources` matches Go's
armresources/v4 v4.0.0, which Go now generates from TypeSpec (API
version 2025-04-01; Microsoft.Resources/resources at the commit of Go's
tsp-location.yaml). As in Go, the deployments are no longer in it:
`DeploymentsClient` and `DeploymentOperationsClient` are gone (Go moved
them to armdeployments, which the Xo repository does not have yet).
Checked against Go's module: all 40 operations' requests, all 44
models' JSON keys, every type name and all 12 enums with their values
and order equal; its Go-backed vectors re-recorded from v4.0.0. The Xo
module path is unchanged (decision 0001).

The generator reads tspconfig.yaml's typespec-go `head-as-boolean`: a
HEAD operation's response is `success`, false on 404, as Go's.

**Breaking**: `resourcemanager/network/armnetwork` matches Go's
armnetwork/v12 v12.1.0, which Go now generates from TypeSpec (API
version 2026-03-01 in 20 feature files, the scale set network
interfaces and public IP addresses at 2018-10-01;
Microsoft.Network/Network at the commit of Go's tsp-location.yaml).
Checked against Go's module: all 838 operations' requests, all 1131
models' JSON keys, every type name and all 303 enums with their values
and order equal; its Go-backed vectors re-recorded from v12.1.0. The
`Error` model is gone, as in Go; the operations with no group stay on
`ManagementClient` (now by `@@clientLocation`); the firewall policy's
explicit proxy is `explicitProxy` on the wire. The Xo module path is
unchanged (decision 0001).

The generator, for ARM modules from TypeSpec (`codegen/README.md` has
the rules): one model per name across a module's files; integer enums
from `type: number`; `@@clientLocation` for Go; Go's unused
`<Op>ParameterBody` models.

**Breaking**: `resourcemanager/compute/armcompute` matches Go's
armcompute/v9 v9.0.0, which Go now generates from TypeSpec (API version
2026-04-01; disks at 2026-03-02, galleries at 2026-03-03, resource SKUs
at 2021-07-01; Microsoft.Compute/Compute at the commit of Go's
tsp-location.yaml). Checked against Go's module: all 310 operations'
requests, all 538 models' JSON keys, every type name and all 173 enums
with their values and order equal; its Go-backed vectors re-recorded
from v9.0.0. The Xo module path is unchanged (decision 0001).

The generator, for ARM modules from TypeSpec (`codegen/README.md` has
the rules): `openapi_more` for a module from several specs; every
`.tsp` file under the spec read; namespace-qualified renames per
emitted file; an `@added` operation named by its interface; a path's
fixed query keys sent; the poller's final state only from
`@useFinalStateVia`. armstorage's pollers change with that last rule:
TaskAssignments create, update and stopAssignment use
`azure-async-operation` and the other 27 long-running operations no
longer name `location`, as Go v4.3.0.

**Breaking**: `resourcemanager/storage/armstorage` matches Go's
armstorage/v4 v4.3.0, which Go now generates from TypeSpec (API version
2026-09-01; Microsoft.Storage/Storage at the commit of Go's
tsp-location.yaml). Checked against Go's module: all 139 operations'
requests, all 299 models' JSON keys, every type name and all 108 enums
with their values and order equal; its Go-backed vectors re-recorded
from v4.3.0. The Xo module path is unchanged (nothing is tagged,
decision 0001).

The generator, for ARM modules from TypeSpec (`codegen/README.md` has
the rules): only reachable types; library definitions named by their
TypeSpec name; repeated words kept; model-level `@@alternateType`;
`subscriptionID` in the empty-parameter error; Accept only with a 2xx
body; `%20` in queries; decorator scope lists (`"go, java"`). A GUID in
a spec's documentation is written as the all-zero GUID. Of the
other modules only azappconfig's generated layer changes: its error
types are `ErrorModel` and `InnerError` (were
`AzureCoreFoundationsError` and `AzureCoreFoundationsInnerError`),
Go's `Error` and `InnerError` by the `Model` rule.

`runtime.new_next_link_pager`: a pager whose next requests are azcore's
NewRequestForNextLink (the link's query re-encoded with a space as
`%20`, a relative link joined to the endpoint, a link that does not
parse failing the pager), as TypeSpec's Go emitter pages.

**Breaking**: three ARM modules follow Go's next major (the Xo module
paths are unchanged: no module has been tagged, decision 0001):

- `resourcemanager/storage/armstorage` matches Go's armstorage/v2
  v2.0.0 (readme tag package-2025-01, API version 2025-01-01).
- `resourcemanager/compute/armcompute` matches Go's armcompute/v7
  v7.3.0 (package-2025-03-03; 2025-04-01, disks 2025-01-02). As Go's
  build.go asks, only the types operations reach are generated, and
  `VirtualMachines.begin_delete`'s poller ends at the Location header
  (the spec's `final-state-via: location`).
- `resourcemanager/network/armnetwork` matches Go's armnetwork/v9
  v9.0.0 (package-2025-05-01, 2025-05-01).
- Each was checked against Go's module: every operation's request (the
  method, path, query and headers each sends) and every type, enum
  value and enum order equal (the documented `ErrorModel` aside); each
  module's Go-backed vectors re-recorded from the Go majors.

The generator, for these regenerations (no other module changes):

- The last 4 enum differences with Go are gone: two x-ms-enums of one
  name are one type (`ProvisioningState`), a constant that starts with
  a number says it in words (`NETWORK_API_VERSION_TWO_THOUSAND_TWENTY_11_01`,
  Go's `TwoThousandTwenty1101`), and `*` is `ASTERISK`
  (`SECURITY_RULE_PROTOCOL_ASTERISK`, was `EMPTY`), sorted by that name.
- readme.go.md directives: `where:` paths into a definition's
  properties, `delete $["k"]` statements, and a `delete` under
  `where: $.definitions` dropping a definition.
- An inline schema is named after its definition's key, not the
  definition's `x-ms-client-name` (`OperationValueDisplay`).
- `codegen/custom/armcompute.toml`: `reachable_only` for Go's
  `-removeUnreferencedTypes`. Its other flag,
  `-alwaysSetBodyParamRequired`, changes nothing in v7.3.0: an optional
  body stays in the options struct in Go's code, as here.

The generator (`codegen`), every generated module regenerated:

- **Behavior change**: an enum's constants and its
  `possible_<type>_values()` are in Go's order, sorted by Go constant
  name as autorest.go and the TypeSpec Go emitter sort them (was the
  spec's order). Checked against Go's `Possible<Type>Values` for each
  generated module: 566 of 570 enums match name for name and in order;
  the other 4 are older naming and value set differences
  (armnetwork's `SecurityRuleProtocol` `*` is `EMPTY` where Go has
  `Asterisk`, `NetworkAPIVersion`, and two `ProvisioningState` enums
  whose values differ from Go's).
- `@@clientName(Namespace.op, ...)`: a target qualified by one of the
  project's namespaces is read without it (azsecrets v1.5.1's
  `KeyVault.updateSecret` is `UpdateSecretProperties`), where it was
  read as a model field.
- `query_pct20` in `codegen/custom/<module>.toml`: the query's spaces
  as `%20` (azsecrets, and azappconfig's generated client, whose query
  normalization writes the query again as Go's does).

Go's azcore v1.21.1 to v1.23.0 (each checked against the lines a Go
program prints with azcore v1.23.0, `runtime/azcore123vectors_test.xo`):

- **Behavior change**: `ResponseError.display` is Go's
  `ResponseError.Error` text: separator lines, `RESPONSE <code>: <code>
  <status text>` (net/http's StatusText, where Go prints the reason
  phrase on the wire), `ERROR CODE UNAVAILABLE` without a colon, and a
  JSON body indented with its trailing white space kept. The request
  line has the scheme, host and escaped path only: the query (a SAS
  signature among it), user info and fragment are left out (v1.21.1).
- `runtime.join_paths`: a root's query goes after the segment's own
  query with `&`, and no slash is added before a segment that is only a
  query (v1.21.1).
- `runtime.Pager` (and azcosmos's query pager, which Go builds on it):
  a failed fetch is terminal, `more` false and every later `next_page`
  the same error with no request sent (v1.23.0).
- `runtime.new_request_for_next_link` and `runtime.has_scheme`: Go's
  NewRequestForNextLink (v1.23.0), the link's query encoded with `%20`
  for a space and a relative link joined to the endpoint.
- `azcore.DateTimeRFC7231` (`rfc7231_text`, `parse_rfc7231`): Go's
  `datetime.RFC7231` (v1.22.0), written in GMT, read case
  insensitively with any zone abbreviation at offset 0 and the weekday
  not checked against the date, as Go's time.Parse reads them. Go's
  UnmarshalText (an empty text is no value) is not ported.

Added, for `messaging/eventgrid/azeventgrid` (checked against Go's
azcore v1.23.0 by a Go program's JSON texts and requests):

- `azcore.KeyCredential` and `azcore.SASCredential`
  (`new_key_credential`, `new_sas_credential`, `update`, `get`): a key
  shared by every copy and replaced in place.
- `runtime.KeyCredentialPolicy` and `runtime.SASCredentialPolicy`: the
  credential in a header (a key with an optional prefix), only over
  HTTPS unless allowed (Go's `authorized requests are not permitted for
  non-TLS protected (https) endpoints`, not retried).
- `azcore/messaging`: `CloudEvent`, `CloudEventData` (`Bytes` is sent
  as `data_base64`, `Value` as `data`), `CloudEventOptions` and
  `new_cloud_event`, written and read as Go's (extensions replace a
  standard attribute but `subject` and `time`; a read `data` is kept as
  its JSON text; the required attributes checked with Go's messages).
  A decode error's text is prefixed `at $: ` by the JSON reader.

**Behavior fix** in every generated module (ARM, Key Vault and
azappconfig's generated layer; regenerated): an empty 2xx response
body decodes as Go's UnmarshalAsJSON leaves it, the zero value (a
model with no fields set, an empty list or map, `""`, a JSON null),
instead of the decode error `the response has no body`. Only a
polymorphic result (armnetwork's `AdminRulesClient`
`BaseAdminRuleClassification`) keeps the error, having no zero value
here; Go's is a nil interface.

The generator writes Go's response handling more closely, for the
packages generated with `reachable_only` (the TypeSpec ones: Key
Vault's azsecrets, azkeys, azcertificates and azadmin, and
azappconfig's generated layer; also armkeyvault), and the Accept fix
for every package. Checked by comparing each generated request with
Go's code, by azappconfig's Go vectors, and by the existing tests of
each regenerated module:

- Accept is the operation's `produces` (without
  `application/json`), comma joined, as Go sends it; armcompute's
  `CloudServiceRoleInstancesClient.get_remote_desktop_file` now sends
  `application/x-rdp`, as Go's.
- A response's documented headers are fields of its response type
  (`etag`, `sync_token`, `link`, `request_id`, ...; an integer header
  that does not parse is Go's `strconv.ParseInt` error): armkeyvault's
  `PrivateEndpointConnectionsClient.put` and
  `MhsmPrivateEndpointConnectionsClient.put` responses gain
  `azure_async_operation` and `retry_after`, as Go's.
- A list of enum values in the query is comma joined, a
  `collectionFormat: multi` array is one parameter per value, and a
  HEAD operation's response has no `success` field.
- `runtime.header_value(resp, name)`: a header, None when missing or
  empty (Go's `if val := resp.Header.Get(...); val != ""`).

`runtime.Poller` follows azcore's async, op, loc, body and nop pollers
step for step (behavior fix; **breaking** where noted). Checked by a Go
program that drives azcore v1.21.0's runtime.NewPoller through 31
cases (`runtime/pollvectors_test.xo`: every request, Done, resume
token, poll and result), and by one Go request, response, page and
poller per module for armresources, armstorage, armcompute,
armnetwork, armkeyvault, azkeys, azsecrets and azcertificates
(`govectors_test.xo` in each):

- The first state comes from the first response as azcore reads it: an
  `Azure-AsyncOperation` or `Location` operation starts in the body's
  `properties.provisioningState` (a PUT whose 201 body already says
  `Succeeded` is done without polling), an `Operation-Location` one in
  its `status`; a PUT or PATCH answered 202 without a polling URL keeps
  polling its own URL.
- **Breaking:** a DELETE or POST answered 202 without a polling URL is
  the error `response is missing polling URL`, and a relative polling
  URL is `invalid polling URL <url>` (both were taken as done, or
  resolved against the request).
- A status poll accepts 200, 201, 202 and 204, and a status without a
  body or a `status` is azcore's error. A `Location` poll that fails is
  the operation's failure, its response the result's error, not an
  error of the poll; 408, 429 and 5xx leave it running.
- The result comes from where azcore takes it: final-state-via
  `location` first for an `Operation-Location` operation, which GETs
  before it reports a failure; an `Azure-AsyncOperation` DELETE gives
  its last status body; a 204 or an empty body is the zero result; any
  of 200, 201, 202 or 204 on the final GET is decoded. A result asked
  of an unfinished poller is `poller is in a non-terminal state`.

**Breaking:** `azcore.DateTime` keeps the offset it read and writes it
back, as Go's time.Time does (`2026-01-02T04:04:05+01:00` round-trips;
it was written as the same instant in UTC). It is now a struct,
`DateTime{time: Time, offset: Duration = 0s}`, instead of a newtype of
Time:

- `d.0` is `d.time`; `azcore.DateTime(t)` is `azcore.utc_date_time(t)`
  (or `DateTime{time: t}`), which writes `Z`.
- `==` compares the offset too, as Go's `==` on a time.Time compares
  its location; compare `.time` for the instant.
- A zero offset (`+00:00`, `-00:00`) is written `Z`, and a space may
  stand for the `T` (`2026-01-02 03:04:05`), as Go's generated
  dateTimeRFC3339 reads it.
- Checked against Go's armkeyvault v1.5.0 on 12 texts
  (`azcore/datetime_test.xo`), and the armkeyvault vector's
  `lastModifiedAt` is `+01:00` again.

Every generated operation builds its request as Go's code does
(behavior fix; requests and some errors change). Checked statically
against each `*CreateRequest` of the pinned Go modules (1415
operations, ARM and Key Vault: method, path, which path parameters are
checked and escaped, query keys, headers, body, path joining), and by
a Go program's requests for armauthorization v2.2.0
(`govectors_test.xo`, 34 lines: scopes with and without a leading
slash, a raw `$filter`, nextLink pages, empty-parameter errors):

- ARM paths are joined with `runtime.join_paths` (azcore's JoinPaths)
  too: a scope or ID with a leading slash (`/subscriptions/...`) no
  longer makes `//` in the URL.
- A reserved (`x-ms-skip-url-encoding`) query parameter goes after the
  encoded query as it is, as Go's unencodedParams: `$filter=principalId
  eq 'x'` is sent raw, where it was escaped and sorted in.
- A path parameter is checked for empty only where Go checks it: a
  string it escapes, not a reserved one (`scope`, `roleAssignmentName`)
  or a number (`updateDomain`). The error names Go's parameter
  (`parameter client.subscriptionID cannot be empty`, `vmName`,
  `instanceID`, `typeParam`), where it named the wire name.
- `Accept` is sent when a response (the error one too) has a schema,
  as autorest.go does; an operation without one (armstorage's
  `AccountsClient.Delete`) sends none. TypeSpec modules send it when the
  success response has a body (azsecrets v1.4.0 on every operation).
- A path that carries a query to tell operations apart
  (`/{roleId}?disambiguation_dummy`, armcompute's `?$expand=Properties`)
  is Go's path without it.
- An enum of one value with `modelAsString: true` stays a parameter of
  its type, as in Go (armstorage's `blob_inventory_policy_name`,
  `management_policy_name`, `migration_name`: **breaking**, the methods
  take the parameter again); one with `modelAsString: false` is a
  constant in every module (armnetwork's `singletonResource`, now
  `swap`, and no longer a parameter: **breaking**).
- azkeys and azcertificates drop `maxresults` from their List options,
  as Go's do (**breaking** for a caller that set it).

Poller resume tokens are azcore's byte for byte. **Breaking:** a
resume token written by an earlier Xo version no longer resumes (its
`type` names the package); start the operation again or take a new
token. Checked against tokens a Go program made with azcore v1.21.0
for each poller kind (`tokenvectors_test.xo`) and against azadmin's:

- The token's `type` is the Go type's name, without its package
  (`ResourceGroupsClientDeleteResponse`), and `*Pager[<import
  path>.<name>]` for a paged operation, as azcore's getTokenTypeName
  writes it. Before it was `<package>.<name>`, so a Go token did not
  resume in Xo, and an Xo token from before this change does not
  resume now.
- An async or op poller's fields have no `type` of their own (Go
  tells them apart by `asyncURL` and `oplocURL`); op's have
  `resultPath`. Loc and body tokens keep `type`. `<`, `>` and `&` are
  escaped as Go's json.Marshal escapes them.
- Resuming picks the kind as azcore's NewPollerFromResumeToken does
  (async, body, loc, op), and a bad token fails with azcore's messages
  (`cannot resume from this poller token. token is for type X, not Y`,
  `missing type value`, `missing token value`, `unhandled poller token
  ...`). A finished poller's resume_token is `poller is in a terminal
  state`.

Generated request bodies and pages are Go's (behavior fix; requests
change for every generated module):

- A model's JSON keys are sorted, as Go's MarshalJSON writes them (it
  fills a map, which json.Marshal writes sorted). Before they were in
  the spec's order. A polymorphic model's discriminator goes in its
  sorted place too.
- A body is `runtime.marshal_json` (azcore's MarshalAsJSON): `<`, `>`
  and `&` in strings are `\u003c`, `\u003e` and `\u0026`, as Go's
  json.Marshal writes them; `json.encode` leaves them as they are.
- `runtime.new_pager` asks for the next page with a bare GET of its
  nextLink, as azcore's FetcherForNextLink does: the first request's
  headers (`Accept`) are not sent again.
- A data plane (TypeSpec) module joins the path as Go's code does,
  with the new `runtime.join_paths` (azcore's JoinPaths, checked on 7
  Go rows): `/{scope}/...` with scope `/keys` is `/keys/...`, not
  `//keys/...`. A reserved parameter (`scope`) is not checked for
  empty, and an empty-parameter error names a quoted TypeSpec name as
  Go does (`settingName` for `setting-name`).

New modules and the runtime and codegen they need:

- `security/keyvault/azadmin/backup`, `rbac` and `settings`: a port of
  Go's `sdk/security/keyvault/azadmin` v1.5.0, generated, with hand
  written clients (README there). Each request, poll, token and result
  is checked against a Go program's.
- `runtime`: a `Status` poller kind (`new_status_poller`,
  `resume_status_poller`), a port of azadmin's restorePoller: it polls
  the `Azure-AsyncOperation` URL as sent, each poll needs a body with
  a status, and the result is the last poll's body.
- codegen: TypeSpec `@client` interfaces (an operation's Go client and
  name), `@@alternateType` and inline `@alternateType` for Go, and
  `custom/<module>.toml: status_pollers`. azcertificates keeps
  `CertificateOperation.error` an ErrorInfo, as Go's transforms.go
  does, against its client.tsp's `@@alternateType` to string.

The api-version policy writes the query as azcore's apiVersionPolicy
does (behavior fix; URLs change). With `ClientOptions.api_version` set,
`runtime.ApiVersionPolicy` now parses the query as Go's `URL.Query()`,
sets `api-version`, and encodes the whole query again, sorted by key
with each value query-escaped (`url.Values.Encode`). Before, it removed
an `api-version` pair and appended the new one, leaving the others as
they were, so `?z=1&api-version=old&a=x+y` went out as
`?z=1&a=x+y&api-version=new` where Go sends
`?a=x+y&api-version=new&z=1`. As Go's, a pair with a `;` or a bad
escape is dropped. Every client that takes the option is affected
(ARM, Key Vault, azmetrics and the others); without the option nothing
changes.

- `runtime`: `set_query_sorted`, checked against azcore v1.18.1 on 36
  URLs and versions (`apiversion_vectors_test.xo`): existing
  parameters, a repeated key, escapes, empty values, a bad escape, a
  `;`, and a version that needs escaping. `set_query` (which keeps the order) is kept.
- `monitor/query/azmetrics` drops its own copy of this rule and uses
  the policy; its requests are unchanged.
- `runtime.new_marker_pager` sets the next page's marker the same way
  (`set_query_sorted`), where it appended the marker after the other
  parameters. No module uses it now (azblob's pagers build their own
  query, with a space as `%20`).

Response headers that repeat are read as azcore reads them (behavior
fix, azure 0742aaa):

- `runtime`: the retry policy's `Retry-After` is azcore's
  `shared.RetryAfter`. It reads the first field of `retry-after-ms`,
  `x-ms-retry-after-ms` and `Retry-After`, in that order. A positive
  integer counts in that header's unit, an HTTP date counts only if it
  is in the future, and anything else moves on to the next header
  (checked on 18 Go cases).
- `runtime`: the pollers read `Location`, `Azure-AsyncOperation` and
  `Operation-Location` by their first field, as Go's `Header.Get`. An
  empty first field counts as no header. The bearer policy's challenge
  parser reads each `WWW-Authenticate` field on its own.
- `azcore`: a response error's code is the first field of
  `x-ms-error-code`. An empty first field reads the code from the body,
  as Go's.

Before, the fields of a repeated header were joined with `, `.
