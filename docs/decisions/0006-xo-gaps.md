# 0006: Xo gaps

Status: Accepted (owner, 2026-11-05; proposed by Xo Azure 1, 2026-11-05)

## Context

Items the Azure SDK needs from the Xo language, toolchain or std, each
for the lead to route to the xo repository's owners, with the workaround
the SDK uses meanwhile. Checked against spec/core.md and spec/std.md at
Xo main 820d19c50 (2026-11-05).

## Decision

1. **std/amqp (AMQP 1.0).** Service Bus and Event Hubs speak AMQP 1.0
   over TLS (port 5671), with SASL (PLAIN, ANONYMOUS) and claims-based
   security (CBS: a `$cbs` link carrying SAS or Entra tokens). Go uses
   github.com/Azure/go-amqp (MIT). Needed: connections, sessions,
   sender and receiver links, flow control, settlement modes,
   dispositions, message encoding (the AMQP type system). Workaround:
   none; the two modules wait.
2. **PKCS#12 (.pfx) in std.** azidentity reads certificates as PEM or
   PKCS#12 (`AZURE_CLIENT_CERTIFICATE_PATH`, often a `.pfx` with a
   password). Go uses golang.org/x/crypto/pkcs12 (BSD). Needed:
   `x509.parse_pkcs12(data, password) -> (List[Certificate], PrivateKey)`.
   Workaround: PEM only, with a message saying to convert with openssl.
3. **std/jwt: extra header fields.** `jwt.sign` writes a fixed header
   (`alg`, `kid`, `typ`); an Entra client assertion needs `x5t#S256`
   (and optionally `x5c`). Needed: a `headers: Map[Str, json.Value]`
   argument. Workaround: build the compact JWS by hand with
   `crypto.sign_pss`.
4. **A stored closure that keeps its effects.** As in the AWS SDK
   (its xo-feedback): a credential cannot hold a "read this file" or
   "run this command" closure, so Azure Arc's key file and any token
   file are handled by background tasks serving channels. Needed: a way
   for a value to carry a closure whose effects were granted when it was
   made. Workaround: the background task pattern.
5. **Int to hex formatting** (`n.to_hex()` or `${n:x}`): small, but
   both SDKs write their own (chunk sizes, request IDs). Workaround: a
   helper.

## Consequences

Items 1 and 2 decide when Service Bus, Event Hubs and `.pfx`
certificates can ship; the others only cost code.

## Alternatives

- AMQP through `use go` bindings to go-amqp: works only on the Go
  backend, not native, which defeats a native SDK.
