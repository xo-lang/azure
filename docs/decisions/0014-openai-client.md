# 0014: Azure OpenAI's client lives in xo-lang/openai

Status: Accepted (owner, 2026-11-09, through the lead).

`ai/azopenai` ports Go's `sdk/ai/azopenai` v0.9.0: Azure's request and
response types only. Go sends those requests with OpenAI's own library,
`github.com/openai/openai-go/v3`, and its `azure` package (endpoint,
`api-version`, API key and TokenCredential authentication).

That library is ported in its own repository, `github.com/xo-lang/openai`
(Apache License 2.0, as openai-go is), by its decision 0001: a subset of
openai-go v3.98.0 (the client and options, chat completions with
streaming, embeddings, and the `azure` package).

For this repository:

- `xo-lang/openai`'s `azure` package requires this repository's root
  module (azcore's TokenCredential, bearer token policy and pipeline),
  as Go's requires azcore. It does not require azidentity; a caller
  passes any credential.
- `ai/azopenai`, its own module, will require `xo-lang/openai` once
  that has a release, for the helpers Go builds on the client. The
  module graph has no cycle.
- `ai/azopenai`'s README says where the client is.
