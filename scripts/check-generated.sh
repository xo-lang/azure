#!/bin/sh
# Regenerates every module in codegen/services.toml and fails if the
# result differs from what is committed (decision 0002: generated code
# is committed and regenerating must leave it unchanged).
# Needs the specs: run codegen/fetch-specs.sh first.
# Usage: XO_CLI=/path/to/xo scripts/check-generated.sh
set -u
cd "$(dirname "$0")/.."
xo=${XO_CLI:-xo}
if [ ! -d codegen/.specs ]; then
  echo "check-generated: codegen/.specs is missing: run codegen/fetch-specs.sh" >&2
  exit 2
fi
dirs=$(awk -F'"' '/^dir *=/ { print $2 }' codegen/services.toml)
fail=0
echo "$dirs" | while read -r dir; do
  [ -n "$dir" ] || continue
  if [ -n "$(git status --porcelain -- "$dir")" ]; then
    echo "check-generated: $dir has uncommitted changes: commit or stash them first" >&2
    exit 1
  fi
  # Generated files only (marked DO NOT EDIT): tests and custom_client.xo
  # are written by hand.
  git ls-files -- "$dir" | grep '\.xo$' | while read -r f; do
    if grep -q '^// DO NOT EDIT\.$' "$f"; then rm -f "$f"; fi
  done
  if ! "$xo" run ./codegen/cmd/gen -- "$dir" >/dev/null; then
    echo "check-generated: the generator failed for $dir" >&2
    exit 1
  fi
  if [ -n "$(git status --porcelain -- "$dir")" ]; then
    echo "check-generated: $dir differs from its regeneration:" >&2
    git status --short -- "$dir" >&2
    git diff --stat -- "$dir" >&2
    exit 1
  fi
  echo "ok: $dir"
done || fail=1
[ $fail -eq 0 ] && echo "check-generated: ok" || echo "check-generated: FAILED"
exit $fail
