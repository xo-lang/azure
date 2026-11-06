#!/bin/sh
# Fetch the azure-rest-api-specs files the generator reads (decision
# 0002) into codegen/.specs/<commit>/ (ignored by git): one partial,
# sparse clone per commit, of the spec folders services.toml names. A
# row's `commit` pins it (a TypeSpec module at Go's tsp-location
# commit); other rows use specs.lock's.
# Usage: codegen/fetch-specs.sh
set -eu
here=$(cd "$(dirname "$0")" && pwd)
repo=https://github.com/Azure/azure-rest-api-specs.git
default=$(awk '$1 == "commit" { print $2 }' "$here/specs.lock")
# One line per row: commit, then the folders it needs.
rows=$(awk -F'"' -v def="$default" '
  function flush() { if (spec != "") { c = (commit != "") ? commit : def; print c, spec, api } spec = api = commit = "" }
  /^\[\[service\]\]/ { flush() }
  /^spec *=/ { spec = $2 } /^commit *=/ { commit = $2 }
  /^openapi *=/ { n = split($2, p, "/"); api = p[1]; for (i = 2; i < n; i++) api = api "/" p[i] }
  END { flush() }' "$here/services.toml")
for commit in $(echo "$rows" | awk '{ print $1 }' | sort -u); do
  dst="$here/.specs/$commit"
  dirs=$( (echo specification/common-types; echo "$rows" | awk -v c="$commit" '$1 == c { print $2; if ($3 != "") print $3 }') | sort -u)
  if [ ! -d "$dst/.git" ]; then
    mkdir -p "$dst"
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
done
