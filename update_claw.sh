#!/data/data/com.termux/files/usr/bin/bash

# OpenClaw Android v2: safe update. Detects runtime mode, stops, updates, re-patches, restarts.

set -euo pipefail

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
SVDIR="${SVDIR:-$PREFIX/var/service}"
TMUX_SESSION="${OPENCLAW_TMUX_SESSION:-openclaw}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

# Detect current runtime mode
detect_mode() {
  if command -v sv >/dev/null 2>&1 && [ -d "$SVDIR/openclaw" ] && sv status openclaw 2>/dev/null | grep -q "run:"; then
    echo "service"
    return
  fi
  if command -v tmux >/dev/null 2>&1 && tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    echo "tmux"
    return
  fi
  echo "none"
}

# Re-apply /tmp/openclaw patch (same logic as setup_claw.sh)
patch_openclaw_paths() {
  local root="$PREFIX/lib/node_modules/openclaw"
  local count=0
  if [ -d "$root" ]; then
    while IFS= read -r -d '' f; do
      if grep -q '/tmp/openclaw' "$f" 2>/dev/null; then
        sed -i "s|/tmp/openclaw|$PREFIX/tmp/openclaw|g" "$f"
        count=$((count + 1))
      fi
    done < <(find "$root" -type f \( -name '*.js' -o -name '*.json' -o -name '*.mjs' \) -print0 2>/dev/null || true)
  fi
  if [ "$count" -eq 0 ]; then
    local f="$root/dist/entry.js"
    if [ -f "$f" ] && grep -q '/tmp/openclaw' "$f" 2>/dev/null; then
      sed -i "s|/tmp/openclaw|$PREFIX/tmp/openclaw|g" "$f"
      count=1
    fi
  fi
  echo "$count"
}

export TMPDIR="${TMPDIR:-$PREFIX/tmp}"
export PATH="$PREFIX/bin:$PATH"

echo -e "${GREEN}>>> Updating OpenClaw...${NC}"

MODE="$(detect_mode)"
echo -e "${YELLOW}Current mode: $MODE${NC}"

# Capture version before update (best-effort)
BEFORE_VER=""
if command -v openclaw >/dev/null 2>&1; then
  BEFORE_VER="$(openclaw --version 2>/dev/null || true)"
fi

# Stop current mode (no-op if none)
if [ "$MODE" = "service" ]; then
  echo -e "${YELLOW}Stopping service...${NC}"
  sv down openclaw
elif [ "$MODE" = "tmux" ]; then
  echo -e "${YELLOW}Stopping tmux session...${NC}"
  tmux kill-session -t "$TMUX_SESSION" 2>/dev/null || true
fi

# Update
echo -e "${YELLOW}Fetching latest from npm...${NC}"
npm install -g openclaw@latest

# Re-patch
echo -e "${YELLOW}Re-patching /tmp/openclaw paths...${NC}"
PATCHED="$(patch_openclaw_paths)"
if [ "${PATCHED:-0}" -gt 0 ]; then
  echo -e "${GREEN}Patched $PATCHED file(s).${NC}"
else
  echo -e "${YELLOW}No files needed patching (or structure changed).${NC}"
fi

# Restart in prior mode
if [ "$MODE" = "service" ]; then
  echo -e "${YELLOW}Restarting service...${NC}"
  export SVDIR="$SVDIR"
  sv up openclaw
  echo -e "${GREEN}Service restarted.${NC}"
elif [ "$MODE" = "tmux" ]; then
  echo -e "${YELLOW}Restarting tmux session...${NC}"
  tmux new-session -d -s "$TMUX_SESSION" "export TMPDIR=\"$PREFIX/tmp\" TMP=\"$PREFIX/tmp\" TEMP=\"$PREFIX/tmp\" PATH=\"$PREFIX/bin:\$PATH\"; openclaw gateway"
  echo -e "${GREEN}Tmux session '$TMUX_SESSION' restarted.${NC}"
fi

# Version after
AFTER_VER=""
if command -v openclaw >/dev/null 2>&1; then
  AFTER_VER="$(openclaw --version 2>/dev/null || true)"
fi

echo -e "\n${GREEN}>>> Update complete.${NC}"
[ -n "$BEFORE_VER" ] && echo "Before: $BEFORE_VER"
[ -n "$AFTER_VER" ] && echo "After:  $AFTER_VER"
echo "Status: ./scripts/status_claw.sh"
