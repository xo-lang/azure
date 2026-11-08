# 0013: Distributed tracing (azcore's tracing, then tracing/azotel)

Status: Proposed (drafted by Xo Azure 1, 2026-11-07, when porting
tracing/azotel v0.4.0 found nothing to adapt; waits on the owner,
through the lead).

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
