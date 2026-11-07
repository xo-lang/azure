#!/bin/sh
# Fetch the azure-rest-api-specs files the generator reads (decision
# 0002) into codegen/.specs/<commit>/ (ignored by git): one sparse
# checkout per commit from a shared partial clone (codegen/.specs/.store),
# of the spec folders services.toml names, without examples. A
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
# One shared partial clone holds every commit's objects (most files are
# the same across commits); each commit is checked out of it sparsely,
# without the examples folders the generator never reads, as plain
# files (.fetched lists the folders).
store="$here/.specs/.store"
if [ ! -d "$store" ]; then
  mkdir -p "$store"
  git init -q "$store"
  git -C "$store" remote add origin "$repo"
  git -C "$store" config extensions.partialClone origin
  git -C "$store" config remote.origin.promisor true
  git -C "$store" config remote.origin.partialclonefilter blob:none
  git -C "$store" config extensions.worktreeConfig true
fi
# The sparse patterns of $dirs: a folder without its examples, or a file.
patterns() {
  for d in $dirs; do
    case $d in
      *.json) printf '/%s ' "$d" ;;
      *) printf '/%s/ !/%s/**/examples/ ' "$d" "$d" ;;
    esac
  done
}
# Check out $dirs (plus the folders fetched before) of $commit at $dst.
checkout() {
  # a commit's folders only grow: worktrees share .specs, each with
  # its own services.toml
  if [ -f "$dst/.fetched" ]; then
    dirs=$( (echo "$dirs"; cat "$dst/.fetched") | sort -u)
  fi
  pats=$(patterns)
  rm -rf "${dst:?}"
  git -C "$store" worktree prune
  if ! git -C "$store" cat-file -e "$commit^{commit}" 2>/dev/null; then
    git -C "$store" fetch -q --depth 1 --filter=blob:none origin "$commit"
  fi
  git -C "$store" worktree add -q --no-checkout --detach "$dst" "$commit"
  git -C "$dst" sparse-checkout set --no-cone $pats
  git -C "$dst" read-tree -mu HEAD
  # plain files from here: a worktree's index lists the whole spec
  # repository (tens of MB a commit)
  rm "$dst/.git"
  git -C "$store" worktree prune
  echo "$dirs" > "$dst/.fetched"
}
# The files that nothing fetched holds but the fetched specs' relative
# $refs name (synapse's common/v1/types.json) or a readme's input-file
# list does (workloads' ../operations/).
refs_outside() {
  for d in $dirs; do
    [ -e "$dst/$d" ] || continue
    grep -rEo --include='*.json' '"\$ref": *"[^"#]+' "$dst/$d" || true
    grep -rEo --include='readme.md' '^ *- *\.\./[^ ]+\.json' "$dst/$d" || true
  done 2>/dev/null | DIRS="$dirs" awk -v root="$dst/" '
    BEGIN { n = split(ENVIRON["DIRS"], D, "\n") }
    {
      i = index($0, ":"); f = substr($0, 1, i - 1); r = substr($0, i + 1)
      sub(/^"\$ref": *"/, "", r); sub(/^ *- */, "", r)
      if (r ~ /^[a-z]+:/) next
      rel = substr(f, length(root) + 1); sub(/\/[^\/]*$/, "", rel)
      m = split(rel "/" r, s, "/"); k = 0
      for (j = 1; j <= m; j++) {
        if (s[j] == "." || s[j] == "") continue
        if (s[j] == "..") { k--; continue }
        o[++k] = s[j]
      }
      out = o[1]; for (j = 2; j <= k; j++) out = out "/" o[j]
      for (j = 1; j <= n; j++) if (D[j] != "" && (out == D[j] || index(out, D[j] "/") == 1)) next
      print out
    }' | sort -u
}
for commit in $(echo "$rows" | awk '{ print $1 }' | sort -u); do
  dst="$here/.specs/$commit"
  dirs=$( (echo specification/common-types; echo "$rows" | awk -v c="$commit" '$1 == c { print $2; if ($3 != "") print $3 }') | sort -u)
  if [ -d "$dst/.git" ]; then
    # a clone of its own, from before the shared store
    pats=$(patterns)
    git -C "$dst" sparse-checkout set --no-cone $pats
  elif [ ! -f "$dst/.fetched" ] || [ -n "$(echo "$dirs" | grep -vxF -f "$dst/.fetched")" ]; then
    checkout
  else
    dirs=$(cat "$dst/.fetched")
  fi
  # and the folders the specs refer to, until none is missing
  while [ ! -d "$dst/.git" ]; do
    more=$(refs_outside)
    [ -z "$more" ] && break
    dirs=$( (echo "$dirs"; echo "$more") | sort -u)
    checkout
  done
  echo "ok: $(echo "$dirs" | wc -l | tr -d ' ') spec folders at $commit"
done
