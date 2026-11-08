# 0013: Distributed tracing (azcore's tracing, then tracing/azotel)

Status: Step 1 (azcore's tracing layer) Accepted; step 2
(tracing/azotel over a std span API) Deferred (owner, 2026-11-07,
through the lead; drafted by Xo Azure 1 when porting tracing/azotel
v0.4.0 found nothing to adapt).

## Context

Go's `tracing/azotel` v0.4.0 is 123 lines that turn an OpenTelemetry
`trace.TracerProvider` into azcore's `tracing.Provider`: each azcore
span becomes an OpenTelemetry span, with its kind, attributes, events
and status converted. It needs two things this repo and Xo do not have.

1. **azcore's tracing layer** (azcore v1.24.0, `tracing/`, `runtime`'s
   `StartSpan` and `httpTracePolicy`, `core.go`):
   - `tracing.Provider` (one `Tracer` per module and version), `Tracer`
     (`Start`, `Enabled`, `SpanFromContext`, tracer-wide attributes),
     `Span` (`End`, `SetAttributes`, `AddEvent`, `SetStatus`),
     `Attribute`, `SpanKind` (internal, server, client, producer,
     consumer) and `SpanStatus` (unset, error, ok).
   - `ClientOptions.TracingProvider`; every client method opens an
     internal span named `<Client>.<Method>` and ends it with the error
     (status error, `<type>:\n<message>`); a span already open for a
     client or internal operation suppresses a nested one (through the
     context).
   - The HTTP trace policy: a client span per try named `HTTP <METHOD>`
     with `http.method`, `http.url` (its query redacted by azcore's
     sanitizer, v1.24.0), `net.peer.name`, `http.user_agent`,
     `az.client_request_id`, then `http.status_code`,
     `az.service_request_id`, and status error for a status of 400 or
     above or a transport error. `az.namespace` (the resource provider)
     is a tracer attribute.
   This port has none of it: no provider option, no spans, no policy.
2. **An OpenTelemetry-shaped span API in Xo.** std/trace (decision
   0325) records a span as a request id, a name, a start and a duration
   (and an HTTP status for `request` spans), and std/otlp (decision
   0539) exports those. There are no attributes, kinds, events, status
   descriptions, or parent and child spans other than `request` and
   its children, and no tracer provider to hand to a library.

Xo has no `context.Context`. The port's clients take no context, so the
active span cannot travel the way Go's does.

## Decision (proposed)

Two steps, the first independent of std:

1. **azcore's tracing layer, in Go's shape**, as part of the core
   ([0003](0003-core.md)):
   - `tracing.Provider`, `Tracer`, `Span`, `Attribute` (value an enum
     of Int, Float, Bool and Str, as azotel's conversion sees them),
     `SpanKind` and `SpanStatus`, all plain values over closures with no
     effects (a tracer records into memory; exporting is the program's
     own step, as with std/otlp's `Exporter`).
   - `policy.ClientOptions.tracing_provider` (none by default: no spans,
     no cost), the HTTP trace policy in the pipeline at Go's place, and
     `runtime.start_span(name, tracer, request)` used by every client
     method, hand written and generated.
   - The active span travels in the request: `policy.Request.values`
     (Amendment 1's never-sent map) carries the active span's kind, so
     the nested-span rule and the HTTP span's parent work without a
     context. The generator emits the `start_span` call per operation
     with Go's name.
   - Checked against Go with a recording `tracing.Provider` in a Go
     program over fakes: every span's name, kind, attributes, events,
     status and nesting, per client, byte for byte.
   - Additive: a new optional field and a new module; no existing
     signature changes. The generated modules change only by the
     `start_span` call, through the generator (one regeneration).
2. **tracing/azotel over an OpenTelemetry span API in std**, asked of
   the Xo lead: std/trace gaining spans with a trace id, span and parent
   ids, a kind, attributes, events and a status with a description, and
   std/otlp exporting them. azotel then maps azcore's spans onto it as
   Go's maps them onto OpenTelemetry (`semconv` schema URL v1.17.0, the
   kind and status tables, `%v` for any other attribute value).
   Until std has it, azotel is not ported; an interim mapping onto
   std/trace's `Ring` would keep only names and durations, and is not
   proposed.

## Step 1 as built (2026-11-08)

- `tracing` (a package of the root module) holds Go's
  tracing package; `runtime/tracing.xo` holds `start_span`, the HTTP
  trace policy, ARM's namespace policy and Go's URL sanitizer
  (`allowed_query_params`; any other query value is `REDACTED`).
- Every generated method opens Go's `<Client>.<Method>` span (BeginX for
  a long-running one), every generated pager its
  `Pager[<Response>].NextPage` span, and every generated poller its
  `Poller[<Response>].PollUntilDone`, `.Poll` and `.Result` spans, a
  nested one suppressed as Go suppresses it.
- Which errors a method's span records follows Go's generated code per
  module, derived by codegen/gorows into the `span_errors` row: "all"
  (255 modules: status and decode errors too) or "send" (57, Go's older
  generators, armstorage 4.3.0 among them: only a request's create and
  send errors). A module whose Go has no spans (azopenai, azsystemevents,
  armservicefabricmesh, armworkloadmonitor and three more) has no row
  value and opens none.
- Checked: armstorage's tracing_test.xo replays a Go program's eight
  calls (azcore v1.24.0, a recording provider over a fake transport):
  162 lines, the same but for the differences below. And every span and
  pager name the generator writes was compared with the names in Go's
  source of the pinned version: 14,456 names in 312 modules, 95 differ,
  all in the 31 modules whose client or method names already differ from
  Go's pinned version (armdashboard's `DashboardsClient.Get` is Go's
  `ManagedDashboardsClient.Get`, `SapApplication...` is Go's
  `SAPApplication...`), or a method Go keeps private. The span names
  follow this port's own names there, until those modules' names do.
- Known differences from Go: a tracer is named by this module's name and
  version (`armstorage v0.1.0`), not Go's module path; every HTTP span
  has `az.client_request_id`, since this SDK sends
  `x-ms-client-request-id` by default ([0003](0003-core.md)); a
  transport error's method span names `*url.Error`, the type Go's own
  transport returns; and a span starts from no parent, Xo having no
  context to carry one in.

## The hand written data plane clients (2026-11-08)

Go's own data plane modules decide which spans there are, so each was
read at the pinned version.

- **No spans in Go, none here**: azblob 1.8.3, azdatalake 1.7.1, azfile
  1.7.2, azqueue/v2 2.1.2, azservicebus 1.11.0, azeventhubs/v2 2.0.2,
  azeventgrid 1.0.0, aznamespaces 1.0.0, azopenai 0.9.0 and azwebpubsub
  0.1.1 call no `runtime.StartSpan` and give no pager or poller a
  tracer. Their pipelines have the HTTP trace policy, and an HTTP span
  starts only under a method span, so they record nothing, as Go's.
- **Spans as Go's**, each checked against a Go program over a fake
  transport with a recording provider (the module's
  `tracevectors_test.xo`, replayed by `tracing_test.xo`):
  - aztables 1.4.1 (namespace `Microsoft.Tables`): 15 methods and 2
    pagers, 256 lines.
  - azappconfig/v2 2.3.0 (`Microsoft.AppConfig`): 9 methods, 5 pagers
    and the snapshot poller, 262 lines. The generated layer takes the
    span through `Client.with_values`: a pipeline whose first policy
    puts the values on each request (`runtime.Pipeline.with_values`).
  - monitor: azquery 1.2.0 (3 logs methods, 1 metrics method, 2 pagers;
    72 lines), query/azlogs 1.2.0 (3 methods; 38), query/azmetrics 1.3.0
    (1; 11) and ingestion/azlogs 1.1.0 (1; 23). No namespace, as Go's.
  - azcosmos 1.5.0 (`Microsoft.DocumentDB`): Go's own `<operation> <id>`
    spans of kind Client with the database attributes
    (otel_constants.go), and each response's request charge and status
    code set on them; 781 lines. Go's internal pipeline (the account
    read) traces with the caller's tracer, so both pipelines here share
    one (`PipelineOptions.tracer`); Go's partition key range cache reads
    with its own context, so those reads are in no span here either. Go
    shares that cache, and the container cache, between clients of one
    endpoint; the cases that read them use hosts of their own.
- A hand written method uses `runtime.traced` (Go's StartSpan and its
  deferred endSpan(err)); its error status names `*errors.errorString`
  for an invalid input with the message alone (`go_desc`).
- The recorder (`tracerec_test.xo`) is one file, the same in each of
  these modules.
- Differences found and fixed on the way: azcosmos's error code is now
  the status line, as Go's `NewResponseErrorWithErrorCode(resp,
  resp.Status)` sets it (the port had kept the service's code); and
  `tracing.Value.display` prints a whole float as Go's `%v` (`0`).
- Differences that stay:
  - An invalid input's error text starts `invalid input: ` (aztables'
    "you cannot set more than five (5) access policies at a time",
    azquery's and query/azlogs' "parameter workspaceID cannot be
    empty"): `azcore.CallErr.display` names the kind of every error,
    and changing it would change every client's error text. The span's
    status has Go's text, the message alone.
  - aztables' entity that is not JSON fails with std/json's message
    (`at $: invalid JSON: EOF`), not encoding/json's (`unexpected end of
    JSON input`), in the error and in the AddEntity span's status (whose
    type, `*json.SyntaxError`, is Go's). Matching it would mean
    reproducing encoding/json's messages for every syntax error.
  - azcosmos sets the request charge as a float32; `tracing.Value` has
    one float, 64 bits, so the recorder prints `float64`. OpenTelemetry
    exports both as a double.

## Alternatives

- **Keep tracing out.** Every client keeps working; no spans exist.
  Applications that trace their own work see the Azure calls only as
  time inside their spans.
- **An OpenTelemetry model inside this repo** (spans, ids, OTLP over
  std/protobuf): no std change, but a second span model beside
  std/trace and std/otlp, which decision 0539 made the one export path.

## Consequences

- Step 1 adds a policy and a span per call only when a provider is
  set; without one, requests are unchanged byte for byte.
- `http.url` in a span is redacted as this port's response errors
  already redact a URL (`redacted_url`), so a SAS signature never
  reaches a span.
- Step 2 waits on std; step 1 does not wait on it and gives
  applications a recording provider of their own meanwhile.
