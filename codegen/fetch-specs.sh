#!/bin/sh
# Fetch the azure-rest-api-specs files the generator reads (decision
# 0002) into codegen/.specs (ignored by git): a partial, sparse clone at
# the commit in specs.lock, of the spec folders services.toml names.
# Usage: codegen/fetch-specs.sh
set -eu
here=$(cd "$(dirname "$0")" && pwd)
dst="$here/.specs"
repo=https://github.com/Azure/azure-rest-api-specs.git
commit=$(awk '$1 == "commit" { print $2 }' "$here/specs.lock")
dirs=$( (echo specification/common-types; awk -F'"' '/^spec *=/ { print $2 }' "$here/services.toml") | sort -u)
if [ ! -d "$dst/.git" ]; then
  git init -q "$dst"
  git -C "$dst" remote add origin "$repo"
  git -C "$dst" config extensions.partialClone origin
fi
git -C "$dst" sparse-checkout set --no-cone $(for d in $dirs; do printf '/%s/ ' "$d"; done)
if [ "$(git -C "$dst" rev-parse HEAD 2>/dev/null || true)" != "$commit" ]; then
  git -C "$dst" fetch -q --depth 1 --filter=blob:none origin "$commit"
  git -C "$dst" checkout -q --detach FETCH_HEAD
fi
echo "ok: $(echo "$dirs" | wc -l | tr -d ' ') spec folders at $commit"
