#!/bin/bash
# Runs storage/azblob/integration against Azurite in Docker (decision
# 0005, layer 4): Azurite listens on 127.0.0.1 only, with its public
# development account, and checks the Shared Key and SAS signatures.
# The container is removed by its ID afterwards.
# Usage: XO_CLI=/path/to/xo scripts/integration-azurite.sh
set -u
cd "$(dirname "$0")/.."
xo=${XO_CLI:-xo}
image=${AZURITE_IMAGE:-mcr.microsoft.com/azure-storage/azurite:3.35.0}
port=${AZURITE_PORT:-20000}
up=${DOCKER_UP:-$HOME/xo-lead/agents/docker-up.sh}
"$up" || exit 1
id=""
cleanup() {
  if [ -n "$id" ]; then docker rm -f "$id" >/dev/null 2>&1; id=""; fi
  "$up" stop
}
trap cleanup EXIT
trap 'exit 143' TERM
trap 'exit 130' INT
id=$(docker run -d -p "127.0.0.1:$port:10000" "$image" azurite-blob --blobHost 0.0.0.0 --blobPort 10000 --skipApiVersionCheck --loose)
[ -n "$id" ] || exit 1
i=0
while [ $i -lt 60 ] && ! curl -s -o /dev/null "http://127.0.0.1:$port/devstoreaccount1?comp=list"; do sleep 1; i=$((i + 1)); done
export XO_AZURE_TEST_BLOB="http://127.0.0.1:$port/devstoreaccount1"
(cd storage/azblob && "$xo" test --real ./integration)
status=$?
[ $status -eq 0 ] && echo "integration-azurite: ok"
exit $status
