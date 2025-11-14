#!/bin/zsh
# Usage: ./sim_push.sh <simulator-udid-or-name> <bundle-id> <path-to-push-json>
# Example: ./sim_push.sh "iPhone 16" com.lauraleal.centinela ./scripts/example_push.json

set -euo pipefail
if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <simulator-udid-or-name> <bundle-id> <path-to-push-json>"
  exit 2
fi

SIM=$1
BUNDLE=$2
JSON=$3

# Resolve simulator identifier if a name was provided
UDID=$(
  xcrun simctl list devices available | awk -F"(" -v sim="$SIM" '$0 ~ sim { gsub(/\)/, "", $2); print $2; exit }' | tr -d ' ' 
)

# If UDID empty, try treating first arg as UDID
if [[ -z "$UDID" ]]; then
  UDID="$SIM"
fi

if [[ ! -f "$JSON" ]]; then
  echo "Push JSON file not found: $JSON"
  exit 3
fi

# Ensure simulator is booted
BOOTED=$(
  xcrun simctl list devices booted | grep -Eo "\b[0-9A-F-]{36}\b" | head -n1 || true
)
if [[ "$BOOTED" != "$UDID" ]]; then
  echo "Booting simulator $UDID (if not already)..."
  xcrun simctl boot "$UDID" || true
  # Give the simulator a moment to boot
  sleep 1
fi

echo "Pushing notification to simulator UDID=$UDID bundle=$BUNDLE using $JSON"
xcrun simctl push "$UDID" "$BUNDLE" "$JSON"

echo "Done."