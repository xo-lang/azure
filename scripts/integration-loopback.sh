#!/bin/sh
# Runs the tests that need real sockets on the loopback host (FakeNet does
# no TLS): azidentity's Service Fabric client against a self signed TLS
# endpoint the test opens on 127.0.0.1. No other host is reached.
# Usage: XO_CLI=/path/to/xo scripts/integration-loopback.sh
set -u
cd "$(dirname "$0")/.."
xo=${XO_CLI:-xo}
(cd azidentity && "$xo" test --real --run=loopback .)
status=$?
[ $status -eq 0 ] && echo "integration-loopback: ok"
exit $status
