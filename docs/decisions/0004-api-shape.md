# 0004: API shape

Status: Accepted (owner, 2026-11-05; proposed by Xo Azure 1, 2026-11-05)

## Context

Owner decision 4: mirror azure-sdk-for-go in Xo style (clients per
service, options structs, pagers, pollers), so Go users find it
familiar. The AWS SDK for Xo did the same for aws-sdk-go-v2 (its decision
0004), and its choices worked.

## Decision

| Go (armstorage) | Xo |
|---|---|
| `armstorage.NewAccountsClient(subID, cred, opts)` | `armstorage.new_accounts_client(net, clock, rand, sub_id, cred, opts)` |
| `client.Get(ctx, rg, name, &AccountsClientGetPropertiesOptions{})` | `client.get_properties(rg, name, AccountsClientGetPropertiesOptions{})` |
| `client.NewListPager(nil)` with `More()` / `NextPage(ctx)` | `client.new_list_pager(...)` with `more()` / `next_page()` |
| `client.BeginCreate(...)` and `poller.PollUntilDone(ctx, nil)` | `client.begin_create(...)` and `poller.poll_until_done()` |
| `*string` fields (`to.Ptr("x")`) | `Str?` fields (`Some("x")`) |
| extensible enums (`type SKUName string` with constants) | a `SKUName` newtype over `Str` with constants and `values()` |
| closed enums | an `enum` with an `Unknown(Str)` variant |
| discriminated models (`AccountPropertiesClassification` interface) | an `enum` with one variant per subtype and `Unknown(json.Value)` |
| `*azcore.ResponseError` | `azcore.ResponseError`, inside each operation's error enum |
| `ctx context.Context` | none: Xo's scope carries cancellation and deadlines |

- Names are snake_case from Go's exported names (`GetProperties` is
  `get_properties`), so a Go example translates line by line.
  Collisions with Xo keywords get Go's own fallbacks, then a suffix.
- Responses are `<Client><Op>Response` structs holding the model, as in
  Go, so headers (ETag, request IDs) sit beside it.
- Each operation's error is an enum: `Response(azcore.ResponseError)` for
  an HTTP error, `Auth(AuthErr)`, `Transport(http.ClientErr)`,
  `InvalidInput(Str)`, and `Deserialize(Str)`. A caller matches on the
  error code without string parsing:
  `Err(E.Response(r)) if r.error_code == "ResourceNotFound"`.
- Capabilities (`Net`, `Clock`, `Rand`) are passed in, never global, so a
  test passes fakes.

## Consequences

- Go users read the Xo API with the Go docs open.
- The snake_case translation is mechanical, so the generator, the docs
  and Go's examples stay in step.

## Alternatives

- An Xo first API (one client per service with nested groups): more
  idiomatic perhaps, but it loses the familiarity the owner asked for.

## Amendment 1

Status: Accepted (owner, 2026-11-05, through the Xo Lead; proposed by Xo
Azure 1, 2026-11-05)

- **One error type for all operations**, `azcore.CallErr`
  (`Response(ResponseError)`, `Send(...)`, `InvalidInput(Str)`,
  `Decode(Str)`), not an enum per operation. Every operation's
  variants were the same, so per operation enums only multiplied
  types (95 more in armresources). Matching stays as planned:
  `Err(azcore.CallErr.Response(e)) if e.error_code == "ResourceGroupNotFound"`.
- **x-ms-enum enums are all newtypes over `Str`** with constants and
  `possible_<x>_values()`, closed ones too. A closed enum in the spec
  still gains values over api-versions; Go's types are strings for
  both, so this keeps code that compares against a new value working.

## Amendment 2

Status: Proposed (Xo Azure 1, 2026-11-05, for the owner through the Xo
Lead)

- **Explicit null in PATCH bodies is typed.** A model that only PATCH
  bodies reach (Go's update models: `VirtualMachineUpdate`,
  `TagsObject`) has `json.Patch[T]` fields: `Absent` (the default)
  leaves the key out, `Null` sends `null`, which JSON merge patch reads
  as "remove", and `Value(v)` sends the value (azure 2e0bba5).
- **Patch twins** carry nulls below the top level. A shared model that
  such a model, or another twin, holds directly (not in a list or a
  map, which merge patch replaces whole; not a polymorphic type's
  member) gets a twin `<Name>Patch` with `json.Patch` fields, and the
  model gains `patch()`, which makes its twin (set fields become
  values, the rest `Absent`). So
  `VirtualMachineUpdate{properties: Value(VirtualMachinePropertiesPatch{diagnostics_profile: Null})}`
  sends `{"properties":{"diagnosticsProfile":null}}` (azure e22f4c9).
  This is API surface Go does not have.
- **Why not Go's way.** Go's `azcore.NullValue[T]()` returns a sentinel
  pointer of the field's own type (one per type, kept in a map), and the
  JSON encoder compares pointers to write `null`. Xo has no pointer
  identity for values: a `T?` is `None` or `Some(v)`, and a sentinel
  `Some(v)` cannot be told apart from a real `v`. Patch[T] spells the
  third state in the type instead, so a null is checked at compile time
  and found by `xo doc`. A list of JSON paths to null (an option on
  each PATCH method) was the other choice, rejected: paths are strings,
  a typo silently sends nothing, and agents cannot discover them.
- **Counts** at e22f4c9: twins in armcompute 149 (VirtualMachineUpdate's
  properties reach the whole VM tree), armstorage 18, azcertificates
  10, azkeys 3, armkeyvault 3, armresources 2, azsecrets 1, armnetwork
  0, armauthorization 0; `<Name>Patch` clashes with no spec name.
  Models that a response reaches keep `T?`, so reading is unchanged.
