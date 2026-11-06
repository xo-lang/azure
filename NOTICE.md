# Notice

xo-lang/azure, Copyright (c) 2026 Joseph Spurrier, MIT License (LICENSE).

This project ports code, behavior and tests from the following works,
each under the MIT License, Copyright (c) Microsoft Corporation:

- github.com/Azure/azure-sdk-for-go: `sdk/azcore` (cloud, policy, arm,
  runtime: the pipeline, retry, telemetry, request ID and bearer token
  policies, pagers, pollers, ResponseError, TokenCredential),
  `sdk/azidentity` (client secret, client certificate, workload
  identity, managed identity, environment, chained and default
  credentials, with MSAL's token requests), `sdk/storage/azblob`
  (the Blob client's container, blob, block and list calls, hand
  written ahead of the generator; Shared Key, the user delegation
  credential, and the `sas` package:
  account, service and user delegation SAS; signing vectors captured
  from its code in `storage/azblob/exported/testdata` and
  `storage/azblob/sas/testdata`), `sdk/security/keyvault/internal` (the Key Vault challenge policy and
  its tests, ParseID), `sdk/security/keyvault/azsecrets`, `azkeys` and `azcertificates`
  (their hand written clients, options and ID types, and
  azcertificates' ErrorInfo; the rest is generated), `sdk/messaging/azservicebus`
  v1.11.0 (the Client, Sender, MessageBatch, Receiver and message
  settlement, Message and ReceivedMessage and their AMQP mapping, the
  connection string parser and SAS signer, and the `$management`
  requests of `internal/mgmt.go`, hand written over std/amqp; the
  signing vector checked against its algorithm), and later the other data plane packages. Each ported file names its source in a header comment.
  The generator (`codegen/`) follows the names and shapes of Go's
  generated `sdk/resourcemanager` modules (autorest.go's naming:
  initialisms, the package name dropped from type names, `Client` for
  the package's own group), so the Xo modules match them.
- github.com/Azure/autorest.go: the acronym list of
  `packages/naming.go/src/mappings.ts` (CommonAcronyms), ported to
  `codegen/gen/names.xo` so generated names are cased as Go's.
- github.com/Azure/azure-rest-api-specs: the service specifications
  the generator reads (decision 0002), at the commit in
  `codegen/specs.lock` or a module's own row in `codegen/services.toml`. The generated modules under `resourcemanager/`
  carry their descriptions as documentation comments.

The MIT License of those works:

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
