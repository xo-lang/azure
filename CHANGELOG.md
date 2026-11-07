# Root module changes

Changes to the root module (`github.com/xo-lang/azure`: `azcore`,
`runtime`, `policy`, `cloud` and the other packages at the root), newest
first. Each module under it (`storage/azblob`, `data/azcosmos`, ...) keeps
its own CHANGELOG. Every module requires the root at v0.1.0; no root
version has been tagged since.

## Unreleased

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

Not ported from v1.24.0 (this port has no logging or tracing policies):
the log sanitizer and tracing attribute changes. The `streaming` SSE
reader is planned as its own change.

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
