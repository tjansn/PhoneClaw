#!/data/data/com.termux/files/usr/bin/bash

# OpenClaw Android v2: environment and readiness check. Emits pass/warn/fail and remediation.

set -euo pipefail

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
export PATH="$PREFIX/bin:${PATH:-}"
SVDIR="${SVDIR:-$PREFIX/var/service}"
OPENCLAW_ROOT="$PREFIX/lib/node_modules/openclaw"
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

PASS=0
WARN=0
FAIL=0

check() {
  local status="$1"
  local msg="$2"
  local remedy="${3:-}"
  case "$status" in
    pass) echo -e "  ${GREEN}PASS${NC} $msg"; PASS=$((PASS+1)) ;;
    warn) echo -e "  ${YELLOW}WARN${NC} $msg"; [ -n "$remedy" ] && echo -e "    ${YELLOW}-> $remedy${NC}"; WARN=$((WARN+1)) ;;
    fail) echo -e "  ${RED}FAIL${NC} $msg"; [ -n "$remedy" ] && echo -e "    ${RED}-> $remedy${NC}"; FAIL=$((FAIL+1)) ;;
  esac
}

echo "OpenClaw Doctor"
echo "=============="

# Termux environment
if [ -z "${PREFIX:-}" ]; then
  check fail "PREFIX is not set" "Run this script inside Termux."
else
  check pass "PREFIX is set ($PREFIX)"
fi
[ -d "$PREFIX" ] && check pass "PREFIX directory exists" || check fail "PREFIX directory missing" "Reinstall Termux from F-Droid."

# Required commands
for cmd in pkg node npm; do
  if command -v "$cmd" >/dev/null 2>&1; then
    check pass "$cmd is available"
  else
    [ "$cmd" = "pkg" ] && check fail "$cmd not found" "Run inside Termux."
    [ "$cmd" = "node" ] || [ "$cmd" = "npm" ] && check fail "$cmd not found" "Run setup_claw.sh or: pkg install -y nodejs-lts"
  fi
done

# Termux:API (optional but recommended)
if command -v termux-api >/dev/null 2>&1; then
  check pass "Termux:API (termux-api) available"
else
  check warn "Termux:API not found" "Install Termux:API from F-Droid for hardware features."
fi

# OpenClaw install
if command -v openclaw >/dev/null 2>&1; then
  check pass "openclaw in PATH"
else
  check fail "openclaw not in PATH" "Run setup_claw.sh"
fi
[ -d "$OPENCLAW_ROOT" ] && check pass "OpenClaw package at $OPENCLAW_ROOT" || check fail "OpenClaw package missing" "Run setup_claw.sh"

# Temp path patch status
# Check for /tmp/openclaw that is NOT preceded by $PREFIX (to avoid false positives)
UNPATCHED=0
if [ -d "$OPENCLAW_ROOT" ]; then
  while IFS= read -r -d '' f; do
    # Look for /tmp/openclaw that isn't part of the full patched path
    if grep -v "$PREFIX/tmp/openclaw" "$f" 2>/dev/null | grep -q '/tmp/openclaw' 2>/dev/null; then
      UNPATCHED=$((UNPATCHED+1))
    fi
  done < <(find "$OPENCLAW_ROOT" -type f \( -name '*.js' -o -name '*.json' -o -name '*.mjs' \) -print0 2>/dev/null || true)
fi
if [ "$UNPATCHED" -gt 0 ]; then
  check fail "$UNPATCHED file(s) still reference /tmp/openclaw" "Run update_claw.sh or re-run setup_claw.sh to re-apply patches."
else
  check pass "No unpatched /tmp/openclaw references in package"
fi

# Temp and log dirs
[ -d "$PREFIX/tmp" ] && check pass "\$PREFIX/tmp exists" || check fail "\$PREFIX/tmp missing" "Run setup_claw.sh"
[ -d "$PREFIX/tmp/openclaw" ] && check pass "\$PREFIX/tmp/openclaw exists" || check warn "\$PREFIX/tmp/openclaw missing" "mkdir -p $PREFIX/tmp/openclaw"
if [ -d "$PREFIX/tmp/openclaw" ]; then
  if [ -w "$PREFIX/tmp/openclaw" ]; then
    check pass "\$PREFIX/tmp/openclaw is writable"
  else
    check fail "\$PREFIX/tmp/openclaw not writable" "Fix permissions or recreate directory."
  fi
fi

# Runtime readiness
if command -v tmux >/dev/null 2>&1; then
  check pass "tmux available (default runtime)"
else
  check warn "tmux not installed" "pkg install -y tmux"
fi
if [ -d "$SVDIR/openclaw" ]; then
  check pass "Service definition present ($SVDIR/openclaw)"
  if command -v sv >/dev/null 2>&1; then
    check pass "sv (runit) available for service mode"
  else
    check warn "sv not found" "pkg install -y termux-services"
  fi
else
  check warn "Service definition missing" "Run setup_claw.sh to create it for --mode service"
fi

# Endpoint (only if gateway might be running)
if command -v curl >/dev/null 2>&1; then
  if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 http://127.0.0.1:18789 2>/dev/null | grep -q '200\|301\|302'; then
    check pass "Gateway UI reachable at http://localhost:18789"
  else
    check warn "Gateway not responding on 18789" "Start with ./scripts/start_claw.sh and run termux-wake-lock"
  fi
else
  check warn "curl not installed; skipping UI check" "pkg install -y curl"
fi

# Summary
echo ""
echo "Summary: $PASS pass, $WARN warn, $FAIL fail"
if [ "$FAIL" -gt 0 ]; then
  echo -e "${RED}Fix FAIL items and re-run doctor or setup.${NC}"
  exit 2
fi
if [ "$WARN" -gt 0 ]; then
  echo -e "${YELLOW}Address WARN items for full functionality.${NC}"
  exit 0
fi
echo -e "${GREEN}Environment looks good.${NC}"
exit 0
