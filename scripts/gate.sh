#!/bin/sh
# Tests every package directory holding .xo files, from its module.
# Usage: XO_CLI=/path/to/xo scripts/gate.sh [package dirs...]
set -u
cd "$(dirname "$0")/.."
xo=${XO_CLI:-xo}
fail=0
if [ $# -gt 0 ]; then dirs="$*"; else dirs=$(git ls-files -co --exclude-standard '*.xo' | xargs -n1 dirname | sort -u); fi
for d in $dirs; do
  mod=$d
  while [ "$mod" != . ] && [ ! -f "$mod/xo.mod" ]; do mod=$(dirname "$mod"); done
  if [ "$mod" = "$d" ]; then rel=.; else rel=${d#"$mod"/}; fi
  echo "== $d"
  (cd "$mod" && "$xo" test "./$rel") || fail=1
done
# The full gate also checks that regenerating changes nothing, when the
# specs are fetched (codegen/fetch-specs.sh).
if [ $# -eq 0 ]; then
  if [ -d codegen/.specs ]; then
    XO_CLI=$xo scripts/check-generated.sh || fail=1
  else
    echo "gate: check-generated skipped: run codegen/fetch-specs.sh"
  fi
fi
[ $fail -eq 0 ] && echo "gate: ok" || echo "gate: FAILED"
exit $fail
