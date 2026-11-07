# azopenai changes

## Unreleased

A subtype encoded on its own (`OnYourDataAPIKeyAuthenticationOptions`,
an `AzureSearchChatExtensionConfiguration`, ...) writes its
discriminator value as Go's does, and a base type alone writes its
`type` as null when unset, as Go's does.

## v0.1.0

First release: a port of Go's `sdk/ai/azopenai` v0.9.0 Azure types (the
models of REST API version 2025-01-01-preview), without its openai-go
types.
