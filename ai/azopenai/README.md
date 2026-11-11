# azopenai

Azure OpenAI's extensions to the OpenAI API, for Xo: a port of Go's
`sdk/ai/azopenai` v0.9.0. Go's module has no client of its own: it is
used with OpenAI's Go library (openai-go v3), which sends the requests.
Its Xo port, with the `azure` package, is github.com/xo-lang/openai
v0.1.0 (released 2026-11-11; decision 0014):
`xo get github.com/xo-lang/openai@v0.1.0 github.com/xo-lang/openai/azure@v0.1.0`.
This port has the Azure parts, which work on the JSON of those requests
and responses:

- The models of Azure OpenAI On Your Data (`AzureSearchChatExtension
  Configuration`, `AzureCosmosDB...`, `Elasticsearch...`, `MongoDB...`
  and `Pinecone...`, their parameters, authentication options and
  vectorization sources), the chat enhancements (grounding, OCR), the
  message context (citations, intent, retrieved documents) and the
  content filter results. Each polymorphic type is an enum
  (`AzureChatExtensionConfigurationClassification`, ...) with a variant
  per subtype and the base for any other value, written with its
  discriminator as Go writes it.
- `with_data_sources(body, sources)` and `with_enhancements(body,
  config)`: Go's WithDataSources and WithEnhancements, setting
  `data_sources` or `enhancements` on a request body.
- `prompt_filter_results(completion)`, `content_filter_results(choice)`
  and `message_context(message)`: Go's PromptFilterResults,
  ContentFilterResults and Context, read from a response's objects (a
  chat completion or chunk or a legacy completion, a choice, a message
  or delta).
- `extract_content_filter_error(status, body)`: Go's
  ExtractContentFilterError, the `ContentFilterError` of a 400 whose
  error code is `content_filter`, with the prompt's filter results. The
  envelope is read as Go's encoding/json reads it (member names in any
  case, a later duplicate merged into an earlier one, null leaving a
  member as it was); a member of the wrong type, or text that is not
  JSON, is None.

The models are generated from the 2025-01-01-preview OpenAPI file that
OpenAI.Inference's TypeSpec emits, at Go's tsp-location commit, keeping
the definitions Go's `autorest.md` keeps (`codegen/custom/azopenai.toml`).
`MongoDBChatExtensionParametersEmbeddingDependency`, the helpers and the
error are written by hand.

The test runs every case through a Go program built against azopenai
v0.9.0 and openai-go v3.2.0 (the request options sent to a local
server) and compares each output: the spec's chat completion examples
(their requests' data sources, their responses' contexts and filter
results), and cases written by hand for the polymorphic types, Go's
decoding rules and the error envelope.

Where it differs from Go v0.9.0:

- openai-go's types (`ChatCompletion`, `ChatCompletionChunk`,
  `Completion` and their choices and messages, which Go's
  `azopenai.ChatCompletion` and the others convert) are not here: the
  helpers take their JSON, and a request option is a function of the
  request body.
- `ContentFilterError` carries the response's status and the
  envelope's message, `prompt`, `status` and inner code; Go's wraps
  openai-go's `*openai.Error` and displays as it does.
- Go's `Error` model is `ErrorModel` (`Error` is Xo's prelude type).
- Go's int32 and float32 fields are `Int` and `Float`: a value outside
  int32 is read, where Go's decode fails, and a float is kept at full
  precision.
- A subtype struct encoded alone writes its own discriminator field
  (Go's writes its constant); encoded through its Classification enum,
  as a model's fields are, it writes Go's.
- Go reads a null where a struct is expected (a null array element, a
  null body) as the zero struct; here it is a decode error (as an
  Option, None). Go's accessors panic on a null member; these return
  None.
- `MongoDBChatExtensionParametersEmbeddingDependency` reads as Go's: an
  object is `Unread`, written back as `null` (Go's type keeps nothing it
  reads).
