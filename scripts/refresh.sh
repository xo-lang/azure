#!/bin/sh
# Refresh every generated ARM module to Go's latest release (decision
# 0011): one command, then generator fixes, never edits to a module.
#
#   XO_CLI=/path/to/xo scripts/refresh.sh [--verify] [module dir ...]
#
# --verify regenerates and checks every module given (or every ARM
# module), not only those whose row changed: the batched differentials
# against Go.
#
# 1. Finds each Go ARM module's latest release (its highest major with a
#    release; the module paths are the coverage report's ARM rows, or
#    the dirs given) and downloads it into the Go module cache (the Go
#    proxy; never Azure).
# 2. Derives each services.toml row from Go's own pin
#    (codegen/gorows: tsp-location.yaml or autorest.md, and the
#    api-versions and request paths of Go's clients), and rewrites the
#    rows that changed.
# 3. Fetches the pinned specs (codegen/fetch-specs.sh) and regenerates
#    every module whose row changed (codegen/cmd/gen).
# 4. For each regenerated module, writes Go's vector program from Go's
#    source (codegen/govec), runs it (a fake transport, no network),
#    writes govectors_test.xo from its output (codegen/cmd/vectors) and
#    runs the module's tests.
# 5. Rewrites the coverage report's ARM status (codegen/cmd/coverage)
#    and prints each module's result: compiled, Go-verified, or the
#    failure, so new failure classes show as one list.
#
# Go runs in a clean environment (env -i): no Azure variables reach it.
# Scratch goes to $REFRESH_DIR (default: a new temporary directory).
set -eu
cd "$(dirname "$0")/.."
verify=0
if [ "${1:-}" = "--verify" ]; then
  verify=1
  shift
fi
xo=${XO_CLI:-xo}
go=${GO:-go}
work=${REFRESH_DIR:-$(mktemp -d)}
mkdir -p "$work"
modcache=${GOMODCACHE:-$HOME/go/pkg/mod}
genv="env -i HOME=$work/gohome PATH=/usr/bin:/bin:$(dirname "$(command -v "$go")") TMPDIR=$work/gohome GOMODCACHE=$modcache GOCACHE=$work/gohome/gocache GOFLAGS=-mod=mod"
mkdir -p "$work/gohome"
prefix=github.com/Azure/azure-sdk-for-go/sdk

# 1. latest releases
if [ $# -gt 0 ]; then
  dirs="$*"
else
  dirs=$(awk -F'|' '/^\| resourcemanager\// { gsub(/ /, "", $2); print $2 }' docs/reports/azure-go-coverage.md | sort -u)
fi
# The candidate module paths: from the major services.toml has for the
# module (its go_module) to two above it, or every major to /v15 for a
# module with no row; all asked of the proxy in one `go list -e` (one
# call per path took about 12 minutes a module).
: > "$work/candidates"
for d in $dirs; do
  have=$(awk -v d="$d" -F'"' '/^dir *=/ { cur = $2 } /^go_module *=/ && cur == d { print $2 }' codegen/services.toml)
  case "$have" in
    */v[0-9]*) m=${have##*/v} ;;
    "") m=0 ;;
    *) m=1 ;;
  esac
  if [ "$m" -eq 0 ]; then lo=1; hi=15; else lo=$m; hi=$((m + 2)); fi
  i=$lo
  while [ "$i" -le "$hi" ]; do
    if [ "$i" -eq 1 ]; then echo "$d $prefix/$d"; else echo "$d $prefix/$d/v$i"; fi
    i=$((i + 1))
  done >> "$work/candidates"
done
$genv $go list -m -e -versions -f '{{.Path}}{{range .Versions}} {{.}}{{end}}' $(awk '{ print $2 }' "$work/candidates") > "$work/versions" 2> "$work/versions.err" || true
: > "$work/modules"
for d in $dirs; do
  best=""
  for p in $(awk -v d="$d" '$1 == d { print $2 }' "$work/candidates"); do
    v=$(awk -v p="$p" '$1 == p { for (i = 2; i <= NF; i++) print $i }' "$work/versions" | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | tail -1 || true)
    if [ -n "$v" ]; then best="$p@$v"; fi
  done
  if [ -z "$best" ]; then
    # every release retracted (armedgemarketplace's go.mod retracts
    # v0.1.0 and v0.1.1): the row's pinned one, which is still Go's code
    pm=$(awk -v d="$d" -F'"' '/^dir *=/ { cur = $2 } /^go_module *=/ && cur == d { m = $2 } /^go_version *=/ && cur == d { print m "@" $2 }' codegen/services.toml)
    if [ -n "$pm" ]; then
      echo "refresh: $d: every Go release retracted; the row's $pm" >&2
      best=$pm
    else
      echo "refresh: $d: no Go release" >&2; continue
    fi
  fi
  echo "$best" >> "$work/modules"
done
$genv $go mod download -json $(cat "$work/modules") > "$work/download.json"
awk -F'"' '/"Path":/ { p = $4 } /"Version":/ { v = $4 } /"Dir":/ { print p, v, $4 }' "$work/download.json" > "$work/modlines"

# 2. rows
(cd codegen/gorows && $genv $go build -o "$work/gorows" .)
env -i HOME="$work/gohome" PATH=/usr/bin:/bin "$work/gorows" "$PWD/codegen/.specs" < "$work/modlines" > "$work/rows.toml" 2> "$work/rows.problems" || true
changed=$($xo run ./codegen/cmd/rows -- "$work/rows.toml")
echo "refresh: rows changed: $(echo "$changed" | grep -c . || true)"
if [ $verify -eq 1 ]; then
  # every module that has a release and a row
  changed=$(awk '{ print $1 }' "$work/modlines" | sed -e "s|^$prefix/||" -e 's|/v[0-9]*$||')
fi

# 3. specs and generation
codegen/fetch-specs.sh > "$work/fetch.out"
"$xo" build -o "$work/gen" ./codegen/cmd/gen > /dev/null
for d in $changed; do
  # the files the generator wrote last time go first, so a client Go
  # dropped does not stay behind (check-generated would find it)
  if [ -d "$d" ]; then
    git ls-files -- "$d" | grep '\.xo$' | while read -r f; do
      if grep -q '^// DO NOT EDIT\.$' "$f"; then rm -f "$f"; fi
    done
  fi
  # a new module joins the workspace (the generator writes its xo.mod)
  grep -qx "use ./$d" xo.work || echo "use ./$d" >> xo.work
  if "$work/gen" "$d" > "$work/$(echo "$d" | tr / _).gen" 2>&1; then
    echo "$d generated"
  else
    echo "$d GENERATE-FAILED"
  fi
done > "$work/gen.out"

# 4. Go vectors and tests
(cd codegen/govec && $genv $go build -o "$work/govec" .)
$xo build -o "$work/vectors" ./codegen/cmd/vectors > /dev/null
: > "$work/result"
for d in $changed; do
  grep -q "^$d generated" "$work/gen.out" || { echo "$d gen-failed" >> "$work/result"; continue; }
  n=$(echo "$d" | tr / _)
  line=$(awk -v p="$prefix/$d" '$1 == p || index($1, p"/v") == 1 { print; exit }' "$work/modlines")
  mp=$(echo "$line" | cut -d' ' -f1); mv=$(echo "$line" | cut -d' ' -f2); md=$(echo "$line" | cut -d' ' -f3)
  env -i HOME="$work/gohome" PATH=/usr/bin:/bin "$work/govec" "$md" "$mp" "$mv" "$work/$n.prog" > /dev/null
  (cd "$work/$n.prog" && $genv $go build -o prog .) || { echo "$d go-program-failed" >> "$work/result"; continue; }
  env -i HOME="$work/gohome" PATH=/usr/bin:/bin "$work/$n.prog/prog" > "$work/$n.go.out" 2>&1 || true
  if grep -q '^panic: ' "$work/$n.go.out"; then
    echo "$d go-program-panicked: $(grep -m1 '^panic: ' "$work/$n.go.out" | cut -c8-)" >> "$work/result"
    continue
  fi
  resp=$md/responses.go; [ -f "$resp" ] || resp=$md/response_types.go; [ -f "$resp" ] || resp=$md/zz_generated_response_types.go
  # the module's vectors as they were, put back if the new ones fail
  had_vec=0; [ -f "$d/govectors_test.xo" ] && { had_vec=1; cp "$d/govectors_test.xo" "$work/$n.old_vectors"; }
  had_fake=0; [ -f "$d/client_test.xo" ] && { had_fake=1; cp "$d/client_test.xo" "$work/$n.old_fake"; }
  # a vectors program that stops is that module's failure, not the batch's
  if ! "$work/vectors" "$work/$n.go.out" "$resp" "$d" "$d/govectors_test.xo" "$(basename "$d") $mv" "$(awk '/sdk\/azcore / { print $2 }' "$work/$n.prog/go.mod")" > "$work/$n.vectors" 2>&1; then
    if [ $had_vec -eq 1 ]; then cp "$work/$n.old_vectors" "$d/govectors_test.xo"; else rm -f "$d/govectors_test.xo"; fi
    echo "$d vectors-failed: $(grep -m1 'fault' "$work/$n.vectors" | cut -c1-120)" >> "$work/result"
    continue
  fi
  # the fake the vectors run against is generated too: always the template
  cp codegen/govec/client_test.xo.txt "$d/client_test.xo"
  "$xo" fmt "$d" > /dev/null || true
  if (cd "$d" && "$xo" test .) > "$work/$n.test" 2>&1; then
    echo "$d Go-verified" >> "$work/result"
  else
    # vectors that do not all pass are not committed: kept in $work
    mv "$d/govectors_test.xo" "$work/$n.new_vectors"
    if [ $had_vec -eq 1 ]; then cp "$work/$n.old_vectors" "$d/govectors_test.xo"; fi
    if [ $had_fake -eq 1 ]; then cp "$work/$n.old_fake" "$d/client_test.xo"; else rm -f "$d/client_test.xo"; fi
    # a test that does not build has no FAIL lines: its errors are counted
    fails=$(grep -c '^--- FAIL' "$work/$n.test" || true)
    errs=$(grep -c ': error XO' "$work/$n.test" || true)
    if [ "$errs" -gt 0 ]; then
      echo "$d compiled vectors-do-not-build $errs errors" >> "$work/result"
    else
      echo "$d compiled $fails failing" >> "$work/result"
    fi
  fi
done

# 5. report
$xo run ./codegen/cmd/coverage
cat "$work/result"
echo "refresh: details in $work"
