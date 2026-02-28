#!/data/data/com.termux/files/usr/bin/bash

# OpenClaw Android v2: Fix path patching issues
# This script cleans up duplicate prefixes and ensures all paths are correctly patched

set -euo pipefail

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
OPENCLAW_ROOT="$PREFIX/lib/node_modules/openclaw"
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

echo -e "${YELLOW}OpenClaw Path Fixer${NC}"
echo "===================="
echo ""

if [ ! -d "$OPENCLAW_ROOT" ]; then
  echo -e "${RED}Error: OpenClaw not found at $OPENCLAW_ROOT${NC}"
  exit 1
fi

echo "Checking for path issues..."

# Step 1: Remove any duplicate prefixes that may have accumulated
echo -e "${YELLOW}Step 1: Removing duplicate prefixes...${NC}"
FIXED_DUPLICATES=0
for f in "$OPENCLAW_ROOT"/dist/*.js "$OPENCLAW_ROOT"/dist/plugin-sdk/*.js 2>/dev/null; do
  [ -f "$f" ] || continue

  # Keep removing duplicates until none remain
  while grep -q "$PREFIX/$PREFIX" "$f" 2>/dev/null; do
    sed -i "s|$PREFIX/$PREFIX|$PREFIX|g" "$f"
    FIXED_DUPLICATES=$((FIXED_DUPLICATES + 1))
  done
done

if [ "$FIXED_DUPLICATES" -gt 0 ]; then
  echo -e "${GREEN}Fixed duplicate prefixes in files${NC}"
else
  echo "No duplicate prefixes found"
fi

# Step 2: Patch any remaining /tmp/openclaw references (that aren't already patched)
echo -e "${YELLOW}Step 2: Patching remaining /tmp/openclaw references...${NC}"
PATCHED=0
find "$OPENCLAW_ROOT" -type f \( -name '*.js' -o -name '*.json' -o -name '*.mjs' \) 2>/dev/null | while read -r f; do
  # Only patch if the file has /tmp/openclaw that isn't already part of the full path
  if grep -v "$PREFIX/tmp/openclaw" "$f" 2>/dev/null | grep -q '/tmp/openclaw' 2>/dev/null; then
    # Use multiple sed patterns to catch different contexts
    sed -i "s|\"\/tmp\/openclaw\"|\"$PREFIX/tmp/openclaw\"|g; s|'\/tmp\/openclaw'|'$PREFIX/tmp/openclaw'|g; s|=\/tmp\/openclaw|=$PREFIX/tmp/openclaw|g" "$f"
    PATCHED=$((PATCHED + 1))
  fi
done

if [ "$PATCHED" -gt 0 ]; then
  echo -e "${GREEN}Patched $PATCHED file(s)${NC}"
else
  echo "All files already correctly patched"
fi

# Step 3: Verify the temp directory exists and is writable
echo -e "${YELLOW}Step 3: Verifying temp directory...${NC}"
mkdir -p "$PREFIX/tmp/openclaw"
if [ -w "$PREFIX/tmp/openclaw" ]; then
  echo -e "${GREEN}Temp directory OK: $PREFIX/tmp/openclaw${NC}"
else
  echo -e "${RED}Warning: Temp directory not writable${NC}"
fi

echo ""
echo -e "${GREEN}Path fixing complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Restart OpenClaw: ./scripts/stop_claw.sh && ./scripts/start_claw.sh"
echo "2. Run health check: ./scripts/doctor_claw.sh"
