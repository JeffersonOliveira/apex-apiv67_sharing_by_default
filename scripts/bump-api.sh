#!/usr/bin/env bash
# Changes the apiVersion in the meta.xml of one class from 66.0 to 67.0 (or back).
#
# Usage:
#   ./scripts/bump-api.sh InvoiceQueryV66            # 66.0 -> 67.0
#   ./scripts/bump-api.sh InvoiceQueryV66 --revert   # 67.0 -> 66.0
set -euo pipefail

REVERT=0
CLASS_NAME=""
for arg in "$@"; do
  case "$arg" in
    --revert) REVERT=1 ;;
    -h|--help)
      sed -n '2,7p' "$0"
      exit 0
      ;;
    *) CLASS_NAME="$arg" ;;
  esac
done

if [ -z "$CLASS_NAME" ]; then
  echo "Usage: $0 <ClassName> [--revert]" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
META="$ROOT/force-app/main/default/classes/${CLASS_NAME}.cls-meta.xml"

if [ ! -f "$META" ]; then
  echo "File not found: $META" >&2
  exit 1
fi

if [ "$REVERT" -eq 1 ]; then
  FROM="67.0"
  TO="66.0"
else
  FROM="66.0"
  TO="67.0"
fi

if ! grep -q "<apiVersion>${FROM}</apiVersion>" "$META"; then
  echo "apiVersion ${FROM} not found in $META (nothing changed)." >&2
  exit 1
fi

sed -i.bak "s|<apiVersion>${FROM}</apiVersion>|<apiVersion>${TO}</apiVersion>|" "$META"
rm -f "${META}.bak"
echo "${CLASS_NAME}: apiVersion ${FROM} -> ${TO}"

if [ "$REVERT" -eq 0 ]; then
  echo
  echo "Now deploy only this class and read the error:"
  echo "  sf project deploy start --metadata ApexClass:${CLASS_NAME} -o <your-org-alias>"
  echo "If your org accepts it, check the release notes of your org: the rule may not be active there yet."
  echo "When you are done: $0 ${CLASS_NAME} --revert"
fi
