# Notice

xo-lang/azure, Copyright (c) 2026 Joseph Spurrier, MIT License (LICENSE).

This project ports code, behavior and tests from the following works,
each under the MIT License, Copyright (c) Microsoft Corporation:

- github.com/Azure/azure-sdk-for-go: `sdk/azcore` (cloud, policy,
  runtime: the pipeline, retry, telemetry and request ID policies,
  ResponseError), and later `sdk/azidentity` and the data plane
  packages. Each ported file names its source in a header comment.
- github.com/Azure/azure-rest-api-specs: the service specifications
  the generator reads (decision 0002), at the commit in
  `codegen/specs.lock`.

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
