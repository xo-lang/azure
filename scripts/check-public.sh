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

hits=$(echo "$files" | xargs grep -n -I -E 'AccountKey=[A-Za-z0-9+/]{20}|SharedAccessKey=[A-Za-z0-9+/]{20}|[?&]sig=[A-Za-z0-9%+/]{20}' 2>/dev/null)
[ -n "$hits" ] && report "keys, connection strings or SAS signatures" "$hits"

hits=$(echo "$files" | xargs grep -n -I -E '/U''sers/|/h''ome/[a-z]' 2>/dev/null | grep -v '^scripts/check-public.sh:')
[ -n "$hits" ] && report "home paths" "$hits"

# loopback, IMDS (169.254.169.254, the documented managed identity
# endpoint), and the RFC 5737 documentation ranges are allowed
hits=$(echo "$files" | xargs grep -n -I -E '(^|[^0-9.])([0-9]{1,3}\.){3}[0-9]{1,3}([^0-9.]|$)' 2>/dev/null | grep -v -E '127\.0\.0\.1|169\.254\.169\.254|192\.0\.2\.[0-9]+|198\.51\.100\.[0-9]+|203\.0\.113\.[0-9]+|0\.0\.0\.0' | grep -E '(^|[^0-9.])([0-9]{1,3}\.){3}[0-9]{1,3}([^0-9.]|$)')
[ -n "$hits" ] && report "IP addresses" "$hits"

hits=$(echo "$files" | xargs grep -n -I -E '[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+\.[A-Za-z]{2,}' 2>/dev/null | grep -v -E '@(example|contoso)\.(com|org|net)|@azure-tools/|@typespec/')
[ -n "$hits" ] && report "email addresses" "$hits"

gl=${GITLEAKS_CONFIG:-../xo-publish-tools/gitleaks.toml}
if [ -f "$gl" ]; then
  if ! gitleaks git --no-banner -c "$gl" . >/dev/null 2>&1; then
    echo "check-public: gitleaks found leaks (run: gitleaks git -c $gl .)" >&2
    fail=1
  fi
else
  echo "check-public: no gitleaks config at $gl; set GITLEAKS_CONFIG" >&2
  fail=1
fi

[ $fail -eq 0 ] && echo "check-public: ok"
exit $fail
