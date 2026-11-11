# codegen

The generator (decision 0002): `xo run ./codegen/cmd/gen -- <module dir>`
writes the module that `services.toml` describes, from the specs that
`codegen/fetch-specs.sh` fetches into `codegen/.specs/<commit>/`.
`scripts/check-generated.sh` (part of `scripts/gate.sh`) regenerates
every module and fails on any difference.

## Go's names, as autorest.go and TypeSpec's Go emitter make them

Each rule below was found by diffing a generated module's names with
Go's (armresources v4.0.0, armstorage v4.3.0, armcompute v9.0.0,
armnetwork v12.1.0, armkeyvault v2.1.0, armauthorization v2.2.0,
azsecrets v1.5.1, azkeys v1.5.0, azcertificates v1.5.0: every method, model, enum, interface, options and
response type equal, except armkeyvault's `Secret`, which is
`SecretModel` by the last rule).

- Acronyms in capitals as autorest.go's CommonAcronyms list writes them
  (`ByID`, `SKUs`, `VPN`, `SSL`, `AAD`, `IPSec`, `IPv6`), per word.
- modelerfour's word splitting for type names: a letter after digits
  starts a word (`VirtualHubRouteTableV2s` is `...V2S`, `P2sVpn` is
  `P2SVPN`), and a word repeated back to back is said once
  (`RoleInstanceInstanceView` is `RoleInstanceView`).
- Operations without a group are on the package's default group, named
  after the first input file's title (`NetworkManagementClient` is
  `ManagementClient`); a data-plane module keeps them on `Client`.
  Group names are case-folded (`configurationPolicyGroups` and
  `ConfigurationPolicyGroups` are one client).
- A definition-level `x-ms-client-name` renames the type; on an inline
  schema it only names the property.
- A definition with a `discriminator` is Go's `<Base>Classification`
  interface wherever it is referenced: an enum with a variant per
  subtype (every definition that descends from it, by its
  `x-ms-discriminator-value`) and the base for any other value, with
  `derive Json(via: json.Value)`. Each subtype's own JSON (through a
  private twin of its fields) writes its discriminator value always,
  whatever the field holds, alone or through the enum, as Go's subtype
  MarshalJSON does. The base writes its field only when set (Go's
  `populate`), or always, null when unset, in a module whose custom
  TOML has `null_base_discriminator = true` (the older generators'
  `objectMap["kind"] = b.Kind`: azopenai v0.9.0, armauthorization
  v2.2.0).
- An enum's constants, and its `possible_<type>_values()`, are sorted
  by Go constant name, case and all, as Go's `Possible<Type>Values`.
- Two x-ms-enums of one name are one type with every value of both, as
  modelerfour merges them (armstorage's `ProvisioningState`: the
  account's three values and the task assignment's eight); the first's
  documentation stays.
- A constant name that starts with a number says the number in words,
  as autorest's fixLeadingNumber (`2020-11-01` is
  `TWO_THOUSAND_TWENTY_11_01`, Go's `TwoThousandTwenty1101`); a value of
  symbols only is named as autorest names it (`*` is `ASTERISK`).
- An inline schema's type is named after the definition key it sits
  under, not the definition's `x-ms-client-name` (armcompute's
  `OperationValueDisplay`).
- An integer x-ms-enum is a newtype of Int whose constants are named in
  words (`FIREWALL_POLICY_IDPS_SIGNATURE_SEVERITY_ONE`), as Go's int32.
- An object definition with no properties, parent or map values is
  `json.Value` (Go's `any`).
- A pageable long-running operation (x-ms-pageable and
  x-ms-long-running-operation, armnetwork's `GetActiveSessions`) returns
  `runtime.Poller[runtime.Pager[T]]`, as Go's `Poller[*Pager[T]]`: the
  final response is the first page, then the pager GETs each nextLink.
- A model that only PATCH bodies reach (no response, no other body:
  `VirtualMachineUpdate`, `TagsObject`) has `json.Patch[T]` fields, so
  `json.Patch.Null` sends an explicit `null`, Go's `azcore.NullValue`;
  `json.Patch.Absent` (the default) leaves the key out. A model a
  response also reaches (`VirtualMachineProperties` under
  `VirtualMachineUpdate.properties`) keeps `T?`; a PATCH body holds its
  patch twin instead (`VirtualMachinePropertiesPatch`, json.Patch
  fields, and on through the models it holds directly), with
  `patch()` on the model to make one. Go has no twins (its NullValue
  is a sentinel of the field's own type), so the name is `<Name>Patch`.
  A model in a list or a map is not twinned (merge patch replaces those
  whole), nor is a polymorphic type's member.
- Each operation's api-version is its own file's (`API_VERSION` when it
  is the package's); an api-version enum is not a type.
- The package name dropped from the front of model and group names
  (`ResourcesMoveInfo` is `MoveInfo`, `StorageAccounts` is `Accounts`),
  but not from x-ms-enum names (`StorageAccountExpand`), and `Client`
  for the group named as the package.
- Two definitions of one name: the same structure (ignoring
  documentation, `$ref`s compared by the type they resolve to) is one
  type; a different one is `<Name>AutoGenerated` (then `...2`).
- allOf parents and `default` (error) response schemas are emitted;
  `x-ms-external` definitions are not; autorest modules emit every
  definition of their input files; TypeSpec ones, and autorest ones
  whose build.go passes `-removeUnreferencedTypes` (armkeyvault,
  armcompute), only
  what operations reach, without allOf parents of their own
  (`custom/<module>.toml: reachable_only`).
- An enum of one value with `modelAsString: false` is a plain string;
  `seal_single_value_enums` (a row's autorest.md
  `seal-single-value-enum-by-default`) adds those that leave it unset, and a required parameter
  of that kind is a constant (`blobServices/default`).
- readme.go.md's operation renames are applied: `rename-operation`
  (`OperationResults_Get` to `AssetTrackOperationResults_Get`,
  armmediaservices), and a `where: $.paths.*[?(@.operationId.startsWith("X_"))]`
  transform that sets `$["operationId"]` to its `.replace("X_", "Y_")`
  (armvideoanalyzer's `PrivateEndpointConnectionsOperationResults_`).
- `where-operation: OP` with `$.parameters[N] = {...}` replaces that
  operation's N-th parameter. In an autorest module a subscriptionId
  written in the operation itself (not a `$ref` to the file's
  parameters) is a method parameter, as modelerfour places an inline
  parameter (armmobilenetwork's `GetBySubscription(ctx, versionName,
  subscriptionID, ...)`); TypeSpec modules keep it on the client, as
  Go's emitter does.
- readme.go.md directives that assign values under `$.definitions.X`
  are applied (armstorage's `CorsRuleAllowedMethodsItem`), scoped by
  `from:`, with `where:` paths into a definition and `delete $["k"]`
  statements (a `delete` under `where: $.definitions` drops the
  definition: armcompute's `Expand`), and so are `rename-model` and `where-model` +
  `rename-property` (which renames the wire key too); others are printed
  as not applied. readme.md's directives in blocks without a condition
  or for the row's tag apply first (armnetwork's
  `SecurityPerimeterResource`), unreported when they cannot.
- `custom/<module>.toml: models` gives modelerfour's path-hashed names
  for inline schemas (`Components1Jq1T4I...`) and Go transforms' type
  renames (`DeletedKeyBundle` is `DeletedKey`); `drop_values` deletes
  enum values Go's transforms delete (`SignatureAlgorithmRSNULL`); a
  `field_types` key may name one model's field (`"certificate.id"`).
- TypeSpec modules take Go's `@@clientName`/`@clientName` renames from
  the .tsp files, and `custom/<module>.toml` mirrors Go's own
  post-generation transforms. A decorator applies when its scope names
  Go (`"go"`, `"go, java"`, `"csharp,go"`) or only negates others; a
  dotted target under `Azure.` or `TypeSpec.` is a library type
  (`Azure.ResourceManager.CommonTypes.Encryption` is `ArmEncryption` in
  armstorage), any other `Model.Property` a field.
- An ARM module from TypeSpec (an `openapi` row, armstorage v4) is
  written as TypeSpec's Go emitter writes it: only the types operations
  reach; a namespace-qualified definition key named by its last segment
  (`Azure.ResourceManager.CommonTypes.KeyEncryptionKeyIdentity`); a
  repeated word kept (`BlobServicePropertiesProperties`); a library
  model that `@@alternateType` replaces with the project's model used in
  its place (armstorage's `UserAssignedIdentity`); a client parameter's
  empty-value error naming it bare (`subscriptionID`); Accept only when
  a 2xx response has a body; the query's spaces as `%20`; and each next
  page from `runtime.new_next_link_pager` (azcore's
  NewRequestForNextLink: the link's query re-encoded with `%20`).
- Such a module may span several specs: `openapi_more` lists the other
  OpenAPI files Go's module is generated from (armcompute v9: DiskRP,
  GalleryRP, skus), and every `.tsp` file under the spec directory is
  read, examples excluded. A namespace-qualified rename applies only to
  the definitions of the file its namespace is emitted to (the main.tsp
  namespace and tspconfig's `output-file`), so two namespaces' `Disk`
  stay apart; a library rename also matches the common-types file's
  short name (`OperationValue`). An operation `@added` in a later
  version whose `@operationId` differs from its interface and name is
  named by the interface and name, as Go is (armcompute's
  `SharedGalleryInvites`). A path's query keys that no parameter sets
  are sent as written (`?api-version=...&$expand=...`, api-version
  aside). The poller's final state is only what `@useFinalStateVia`
  (or `@Azure.Core.useFinalStateVia`) gives; the OpenAPI
  `final-state-via` the TypeSpec compiler writes is not used, as Go's
  emitter does not.
- In such a module one name is one model: a definition repeated in an
  older API version's file (armnetwork v12's 2018-10-01
  vmssNetwork.json `NetworkInterface`) is the model already read, not a
  `...AutoGenerated` second type. An enum of `type: number` whose values
  are whole numbers is an integer enum (Go's int32), its values named
  as number words when the spec names them by their value
  (`FIREWALL_POLICY_IDPS_SIGNATURE_DIRECTION_FIVE`).
  `@@clientLocation(Iface.op, "ManagementClient", "go")` puts an
  operation on that client (armnetwork's `CheckDNSNameAvailability`),
  and an interface target on that interface's client; the operation
  keeps its operationId's name. An action whose request is an inline
  `{ @bodyRoot x: T; }` also gets Go's unused `<Op>ParameterBody` model
  (`StopCircuitLinkFailoverTestParameterBody`).
- The project's tspconfig.yaml options for `@azure-tools/typespec-go`
  apply as readme.go.md's did: `head-as-boolean: true` makes a HEAD
  operation's response `success`, true on 2xx and false on 404
  (armresources v4's `ResourceGroupsClient.CheckExistence`), and
  `stutter: <name>` is the name dropped from the front of type names
  and the group that becomes plain `Client`, in place of the package's
  (armdeployments v3's `stutter: resources` keeps `DeploymentsClient`).
- `@@override(Iface.op, customOp, "go")`: Go's method takes the custom
  operation's path parameters in the order it declares them
  (armcosmos v4's `GetSQLRoleDefinition(ctx, roleDefinitionID,
  resourceGroupName, accountName)`); the operation is found by its
  `@operationId`, or by the group an unscoped
  `@@clientLocation(Iface.op, Group)` moves it to. A custom file's
  `[param_order]` wins.
- A model whose schema, or an allOf parent, has `additionalProperties:
  {}` beside its properties gets Go's AdditionalProperties:
  `additional_properties: Map[Str, json.Value]?`, the keys no field
  names, kept on decode and written inline on encode, keys sorted
  (armcosmos v4's ServiceResourceProperties and its four subtypes).
- A model field whose schema is a one-value enum sealed to a string
  (Go's CONSTANT field, a `Str?` here) is written as Go writes it: its
  constant always when the schema requires it, else its constant when
  set, whatever the field holds (armstorage's
  `AccountCheckNameAvailabilityParameters.type`, armcompute's
  `Usage.unit`, armcosmos's `databaseAccountOfferType`). Decoding keeps
  the value as sent.
- `utc_date_times` in a services.toml row: Go's module writes its
  `date-time` fields in UTC (the TypeSpec Go emitter's `populateTime`
  with `utc`: armstorage v4, armcompute v9, armnetwork v12, armkeyvault
  v2; armresources v4 came from an older emitter that keeps the
  offset), so they are `azcore.DateTimeUTC`, which reads as
  `azcore.DateTime` and writes UTC.
- `struct_order_json` in a services.toml row: Go's models have no
  MarshalJSON, so encoding/json writes them in struct order: REQUIRED
  fields, then the others, then READ-ONLY ones, each by Go name. With
  `json_marshal_models` (gorows, for a Go module of autorest.go's
  `zz_generated_` era: armmachinelearningservices 1.0.1) only the models
  not in that list are; the listed ones are in wire-name order, as
  their MarshalJSON's populate calls are.
- `span_errors` in a services.toml row (codegen/gorows, decision 0013):
  each method opens Go's `<Client>.<Method>` span, each pager and
  poller Go's own; "all" records every error a method returns in its
  span, as Go's generated code that sets `err` before returning; "send"
  only a request's create and send errors (Go's older generators return
  a status or decode error without setting `err`: armstorage 4.3.0). No
  value: Go's module has no spans, and neither does ours. gorows reads
  a module's root package only; the azadmin rows (backup, rbac,
  settings) carry the value of their own Go packages by hand.
- A PUT's or PATCH's optional body is a parameter of the method, as Go's
  TypeSpec emitter takes it (armstorage's `TableClient.Create`); an
  action's optional body stays in the options.
- `custom/<module>.toml: param_order` gives an operation's path
  parameters in Go's order where Go's emitter orders them otherwise
  than the path (armkeyvault's `VaultsClient.GetDeleted(vaultName,
  location)`; the order comes from how the TypeSpec templates compose
  the parameters, which the OpenAPI file does not keep). Every method's
  required parameters were compared with Go's in order.
- Documentation keeps the spec's text, except that a GUID in it (a
  spec's example id, armstorage v4's `Ex: ...`) is written as the
  all-zero GUID: the repository holds no ids.
- Two definitions of one name are compared by shape; in a module that
  keeps only reachable types, an allOf parent is compared by its own
  shape, so comparing does not emit it.
- A TypeSpec module's `@client({...}, "go") interface X { name is
  NS.Group.op; }` blocks name its Go operations: only the operations
  listed are generated, under those names, on one `Client` (azadmin's
  rbac). `@@alternateType(Model.prop, type, "go")` and an inline
  `@alternateType(type, "go")` on a parameter give Go's type; a
  `field_types` entry wins over it where Go's transforms undo it
  (azcertificates' `CertificateOperation.error`).
- A TypeSpec data plane module (azbatch): a `@client` block with no
  language scope counts for Go, its members name operations by their
  namespace-free target, and a member's stacked inline `@clientName`
  takes the Go-scoped one. `custom/<module>.toml: param_names` and
  `header_names` give Go's casing of a parameter and of a response
  header's field (`OCPDate`, `ocp_batch_file_is_directory`);
  `merge_update_variants` makes an OpenAPI `...Update` or `...Patch`
  variant its base type, as Go's emitter does; `patch_twins = false`
  sends a PATCH body as plain JSON. Response headers are typed as Go
  reads them (`Int`, `Bool` by strconv.ParseBool, `Time` by RFC 1123),
  RFC 1123 and 7231 header parameters are `Time` written in UTC as
  Go's `t.Format(time.RFC1123)`, a `date-time-rfc7231` field is
  `azcore.DateTimeRFC7231` (Go's `datetime.RFC7231`), a binary
  response gets Go's `content_type`, and a JSON body's Content-Type is
  the operation's one consumed type (`application/json;
  odata=minimalmetadata`). `private_ops` applies to pagers too.
- TypeSpec's `@@clientLocation(Iface.op::parameters.p, Iface.op)`
  (unscoped or for Go) moves a client parameter onto that operation's
  method, as Go's emitter does (armsubscriptions' `Client.Get(ctx,
  subscriptionID, ...)`; a client none of whose operations keep the
  parameter takes none).
- `custom/<module>.toml: status_pollers` names the operations whose
  poller is Go's hand written restorePoller (`runtime.new_status_poller`).
- A model's fields are declared sorted by wire name, the order Go's
  MarshalJSON writes them; a body is `runtime.marshal_json` (HTML
  escaped, as json.Marshal). A data plane module joins its paths with
  `runtime.join_paths`, checks no reserved path parameter for empty,
  and names a quoted TypeSpec parameter (`setting-name`) as Go does
  (`settingName`). A poller's resume token type is the Go type's name,
  or `*Pager[<Go import path>.<name>]` for a paged operation.
- Requests follow autorest.go and TypeSpec's emitter: paths joined by
  `runtime.join_paths`, a reserved query parameter appended raw, a path
  parameter checked for empty only when Go checks it (a string it
  escapes) and named as Go names it (`client.subscriptionID`,
  `vmName`), `Accept` only when a response has a schema
  (`custom/<module>.toml: accept_always` for an emitter that always
  sends it), a query's spaces as `%20` where Go's emitter writes them so
  (`query_pct20`), and a path's disambiguating query dropped. An enum of one
  value is a constant when `modelAsString` is false, or unset in a
  module that seals them.
- An autorest data plane module from one swagger file
  (`services.toml: swagger`, as Go's autorest.md `input-file`; the
  spec's readme and its directives are not read) takes Go's
  autorest.md directives as JSON patches (`custom/<module>.toml:
  [[patch]]` with `pointer`, `op` set, delete, push or copy, and
  `value` as JSON text; a patch that touches no file is reported).
  Its clients are named per group (`Client` for the package's own,
  `BlobClient`, ...), with responses carrying their headers. Also:
  `remove_unreferenced` (Go's `remove-unreferenced-types`, or its
  build.go's `-removeUnreferencedTypes` as for armmsi), `[ops]`
  renames, `body_fields` (the field of a binary response,
  `ManifestData`), `next_link_transform` (a pager whose next link is
  the `Link` header, joined to the endpoint after the named hand
  written function extracts it), and `private_ops` and `private_types`
  (Go's lower case ones, emitted as `raw_<name>` and `Raw<Name>` so a
  hand written public wrapper keeps Go's name). `[[replace]]` with
  `pattern` (a regular expression) and `with` rewrites the generated
  text, as Go's autorest.md `where: $` directives rewrite Go's
  (azwebpubsub's `ClientSendToAllOptions` to `SendToAllOptions`). An
  operation that produces JSON and other types accepts only its JSON
  ones, and a path parameter's empty-value error names it in
  autorest.go's casing (`connectionID`). `keep_definitions`
  keeps only the definitions whose name is one of its prefixes and
  more, before the patches (azopenai's autorest.md keeps
  `^(OnYour|Azure|...).+$`); with no paths the module is models only.
- `custom/<module>.toml: field_types` names a field's type by
  `model.field` (or `field` alone, for a string field in every model);
  a field of an `x-ms-external` type (otherwise `json.Value`) takes a
  hand written type only by `model.field` (azopenai's
  `MongoDBChatExtensionParametersEmbeddingDependency`).
- A `formData` body is sent `application/x-www-form-urlencoded`; a
  `format: binary` or `file` body is `Bytes`, with a `content_type`
  parameter when the operation consumes several types; a binary
  response is the response's `Bytes` field. Every declared status not
  marked `x-ms-error-response` is a success (Container Registry's
  deletes declare 404), as in autorest.go. An operation that produces
  only a binary type sends no `Accept` for its error schema alone.
- Query parameters are set with `runtime.with_query`, so a query the
  joined URL already has is kept, as Go's `URL.Query()` keeps it.
  api-version is one of them even when the spec marks it
  `x-ms-skip-url-encoding` (armstorsimple8000series): autorest.go sets
  it through `reqQP.Set` whatever the extension says.
- A name Xo predeclares gets `Model` (`Secret` is `SecretModel`); a
  response's field keeps Go's embedded name (`.secret`).
- A Go type with a lower case name (a TypeSpec `@@clientName` to
  `internal...`) is the module's own: UpperCamel, without `pub`.
- `custom/<module>.toml: all_definitions` keeps every definition of a
  TypeSpec module (azsystemevents is models only), `drop_models` drops
  the ones Go writes by hand, and `event_types` writes
  `system_events.xo`: a `TYPE_...` constant per event, from each data
  type's doc as Go's generate step reads it (`Name - doc ... Type.Event`).
- TypeSpec renames: a scoped `@@clientName` for Go applies; an
  unscoped one applies unless Go has its own; one scoped to other
  languages only is undone when the OpenAPI file carries it as
  `x-ms-client-name`; a rename of a spread model applies to each model
  it is spread into.
- A Go name whose snake_case form is an Xo keyword or predeclared value
  (`gen/names.xo` KEYWORDS) gets a trailing `_`: in the generated modules
  `type_`, `select_`, `target_`, `interface_`, `match_` and `as_`
  (`Type` is `type_`).
