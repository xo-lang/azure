#!/bin/sh
# Fails when tracked files hold data that must not be public (decision
# 0007): GUIDs other than the all-zero placeholder (subscription, tenant
# and client IDs), storage keys and connection strings, SAS signatures,
# local home paths, IP addresses outside loopback, link local metadata
# and the documentation ranges, and email addresses. Then runs gitleaks
# over the whole history with the publishing tools' rules.
# Usage: scripts/check-public.sh
set -u
cd "$(dirname "$0")/.."
fail=0
files=$(git ls-files -co --exclude-standard | grep -v -E '^(LICENSE|NOTICE\.md)$')

report() {
  echo "check-public: $1 ($(echo "$2" | grep -c .) lines)" >&2
  echo "$2" | head -20 >&2
  fail=1
}

# the all-zero GUID is the placeholder tests and docs use
hits=$(echo "$files" | xargs grep -n -I -i -E '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' 2>/dev/null | grep -v -E '00000000-0000-0000-0000-000000000000' )
[ -n "$hits" ] && report "GUIDs (subscription, tenant or client ids?)" "$hits"

# storage/azblob/sas/testdata/sas_vectors.json holds SAS signed with
# Azurite's public development key (devstoreaccount1); its test signs
# each one again with that key and fails on any other, so it is skipped
# here (gitleaks still scans it)
hits=$(echo "$files" | grep -v -x 'storage/azblob/sas/testdata/sas_vectors\.json' | xargs grep -n -I -E 'AccountKey=[A-Za-z0-9+/]{20}|SharedAccessKey=[A-Za-z0-9+/]{20}|(^|[?&"])sig=[A-Za-z0-9%+/]{20}' 2>/dev/null)
[ -n "$hits" ] && report "keys, connection strings or SAS signatures" "$hits"

# `/home/user/` is the placeholder Microsoft's specs use in their docs
# (`/home/user/.ssh/authorized_keys`); any other home path fails.
hits=$(echo "$files" | xargs grep -n -I -E '/U''sers/|/h''ome/[a-z]' 2>/dev/null | grep -v '^scripts/check-public.sh:' | sed 's|/h''ome/user/||g' | grep -E '/U''sers/|/h''ome/[a-z]')
[ -n "$hits" ] && report "home paths" "$hits"

# loopback, IMDS (169.254.169.254, the documented managed identity
# endpoint), the RFC 5737 documentation ranges, 124.56.78.x, the
# example Microsoft's Key Vault spec documents ip rules with, and a
# network prefix or version (`x.0.0.0`, which the generator keeps in
# documentation: a template's "1.0.0.0") are allowed
hits=$(echo "$files" | xargs grep -n -I -E '(^|[^0-9.])([0-9]{1,3}\.){3}[0-9]{1,3}([^0-9.]|$)' 2>/dev/null | grep -v -E '127\.0\.0\.1|169\.254\.169\.254|124\.56\.78\.(91|0/24)|192\.0\.2\.[0-9]+|198\.51\.100\.[0-9]+|203\.0\.113\.[0-9]+|0\.0\.0\.0|(^|[^0-9.])[0-9]{1,3}\.0\.0\.0([^0-9.]|$)' | grep -E '(^|[^0-9.])([0-9]{1,3}\.){3}[0-9]{1,3}([^0-9.]|$)')
[ -n "$hits" ] && report "IP addresses" "$hits"

# OData annotations (`Name@odata.type`) are protocol syntax, not addresses.
hits=$(echo "$files" | xargs grep -n -I -E '[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+\.[A-Za-z]{2,}' 2>/dev/null | grep -v -E '@(example|contoso)\.(com|org|net)|@azure-tools/|@typespec/|@odata\.(type|etag|metadata|editLink|id)\b')
[ -n "$hits" ] && report "email addresses" "$hits"

gl=${GITLEAKS_CONFIG:-../xo-publish-tools/gitleaks.toml}
if [ -f "$gl" ]; then
  # the shared rules, extended with this repository's path allowlist
  # gitleaks reads the format from the extension
  cfgdir=$(mktemp -d "${TMPDIR:-/tmp}/gitleaks-azure.XXXXXX")
  cfg="$cfgdir/gitleaks.toml"
  printf '[extend]\npath = "%s"\n\n' "$(cd "$(dirname "$gl")" && pwd)/$(basename "$gl")" >"$cfg"
  cat scripts/gitleaks-extra.toml >>"$cfg"
  # The directory scan covers what git would commit (tracked and
  # untracked files, not ignored ones such as codegen/.specs, Microsoft's
  # spec cache), copied with their paths so the allowlist still applies.
  mkdir "$cfgdir/tree"
  git ls-files -co --exclude-standard | rsync -a --files-from=- . "$cfgdir/tree/"
  if ! gitleaks git --no-banner -c "$cfg" . >/dev/null 2>&1 || ! (cd "$cfgdir/tree" && gitleaks dir --no-banner -c "$cfg" . >/dev/null 2>&1); then
    echo "check-public: gitleaks found leaks (run: gitleaks git -c $cfg . and gitleaks dir over the tracked files)" >&2
    fail=1
  fi
  rm -rf "$cfgdir"
else
  echo "check-public: no gitleaks config at $gl; set GITLEAKS_CONFIG" >&2
  fail=1
fi

[ $fail -eq 0 ] && echo "check-public: ok"
exit $fail
