#!/bin/sh
# Regenerates every module in codegen/services.toml and fails if the
# result differs from what is committed (decision 0002: generated code
# is committed and regenerating must leave it unchanged).
# Needs the specs: run codegen/fetch-specs.sh first.
# Usage: XO_CLI=/path/to/xo scripts/check-generated.sh
set -u
cd "$(dirname "$0")/.."
xo=${XO_CLI:-xo}
if [ ! -d codegen/.specs/.git ]; then
  echo "check-generated: codegen/.specs is missing: run codegen/fetch-specs.sh" >&2
  exit 2
fi
rows=$(awk -F'"' '
  /^\[\[service\]\]/ { if (dir != "") print dir, spec, tag, ver; dir = spec = tag = ver = "" }
  /^dir *=/ { dir = $2 } /^spec *=/ { spec = $2 } /^readme_tag *=/ { tag = $2 } /^version *=/ { ver = $2 }
  END { if (dir != "") print dir, spec, tag, ver }' codegen/services.toml)
fail=0
echo "$rows" | while read -r dir spec tag ver; do
  [ -n "$dir" ] || continue
  if [ -n "$(git status --porcelain -- "$dir")" ]; then
    echo "check-generated: $dir has uncommitted changes: commit or stash them first" >&2
    exit 1
  fi
  # Generated files only: tests are written by hand.
  git ls-files -- "$dir" | grep '\.xo$' | grep -v '_test\.xo$' | while read -r f; do rm -f "$f"; done
  if ! "$xo" run ./codegen/cmd/gen -- arm "$spec" "$tag" "$dir" "$ver" >/dev/null; then
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
