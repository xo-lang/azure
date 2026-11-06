# Root module changes

Changes to the root module (`github.com/xo-lang/azure`: `azcore`,
`runtime`, `policy`, `cloud` and the other packages at the root), newest
first. Each module under it (`storage/azblob`, `data/azcosmos`, ...) keeps
its own CHANGELOG. Every module requires the root at v0.1.0; no root
version has been tagged since.

## Unreleased

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

`azcore.DateTime` writes a time read with a non-zero offset as the
same instant in UTC, where Go keeps the offset (a known difference,
documented on the type; Xo's Time has no offset).

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
