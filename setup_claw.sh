#!/data/data/com.termux/files/usr/bin/bash

# ====================================================
#  OPENCLAW ANDROID V2: TERMUX INSTALLER
#  Target: Android (non-rooted). Idempotent, tmux-first.
# ====================================================

set -euo pipefail

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

# --- Spinner helper for long-running commands ---
run_with_spinner() {
  local label="$1"
  shift

  local start_ts now elapsed rc
  local spin_interval="${SPINNER_INTERVAL:-0.2}"
  local heartbeat_interval="${HEARTBEAT_INTERVAL:-10}"
  local frames='|/-\'
  local i=0 frame

  "$@" &
  local cmd_pid=$!

  start_ts=$(date +%s)

  if [ -t 1 ]; then
    while kill -0 "$cmd_pid" 2>/dev/null; do
      now=$(date +%s)
      elapsed=$((now - start_ts))
      frame="${frames:i%4:1}"
      printf "\r${YELLOW}    [%s] %s (%ss elapsed)...${NC}" "$frame" "$label" "$elapsed"
      i=$((i + 1))
      sleep "$spin_interval"
    done
    printf "\r\033[K"
  else
    start_ts=$(date +%s)
    while kill -0 "$cmd_pid" 2>/dev/null; do
      sleep "$heartbeat_interval"
      if kill -0 "$cmd_pid" 2>/dev/null; then
        now=$(date +%s)
        elapsed=$((now - start_ts))
        echo -e "${YELLOW}    [heartbeat] ${label} still running (${elapsed}s elapsed)...${NC}"
      fi
    done
  fi

  if wait "$cmd_pid"; then
    rc=0
  else
    rc=$?
  fi

  if [ -t 1 ]; then
    if [ "$rc" -eq 0 ]; then
      echo -e "${GREEN}    [ok] ${label} complete.${NC}"
    else
      echo -e "${RED}    [error] ${label} failed.${NC}"
    fi
  fi

  return "$rc"
}

# --- Preflight checks ---
preflight_checks() {
  echo -e "${YELLOW}[preflight] Checking environment...${NC}"
  if [ -z "${PREFIX:-}" ]; then
    echo -e "${RED}Error: PREFIX is not set. Run this script inside Termux.${NC}"
    exit 1
  fi
  if [ ! -d "$PREFIX" ]; then
    echo -e "${RED}Error: PREFIX directory does not exist. Not in Termux?${NC}"
    exit 1
  fi
  for cmd in pkg node npm; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      [ "$cmd" = "node" ] || [ "$cmd" = "npm" ] && continue
      echo -e "${RED}Error: $cmd not found. Run inside Termux.${NC}"
      exit 1
    fi
  done
  echo -e "${GREEN}    Preflight OK.${NC}"
}

# --- Mirror health checks ---
detect_ncurses_mirror_mismatch() {
  local ncurses_candidate ui_candidate
  ncurses_candidate="$(apt-cache policy ncurses 2>/dev/null | sed -n 's/^[[:space:]]*Candidate:[[:space:]]*//p' | head -n1)"
  ui_candidate="$(apt-cache policy ncurses-ui-libs 2>/dev/null | sed -n 's/^[[:space:]]*Candidate:[[:space:]]*//p' | head -n1)"

  if [ -z "$ncurses_candidate" ] || [ -z "$ui_candidate" ]; then
    return 1
  fi
  if [ "$ncurses_candidate" = "(none)" ] || [ "$ui_candidate" = "(none)" ]; then
    return 1
  fi

  [ "$ncurses_candidate" != "$ui_candidate" ]
}

print_mirror_recovery_hint() {
  echo -e "${YELLOW}    Suggested recovery:${NC}"
  echo -e "      1) ${GREEN}termux-change-repo${NC} (pick a different mirror)"
  echo -e "      2) ${GREEN}pkg update -y && pkg upgrade -y${NC}"
  echo -e "      3) re-run ${GREEN}./setup_claw.sh${NC}"
}

# --- Install dependencies ---
install_dependencies() {
  echo -e "${YELLOW}[1/6] Updating system and installing dependencies...${NC}"
  run_with_spinner "pkg update" pkg update -y
  run_with_spinner "pkg upgrade" pkg upgrade -y

  if detect_ncurses_mirror_mismatch; then
    echo -e "${YELLOW}    Mirror looks stale (ncurses candidate mismatch). Refreshing metadata and retrying...${NC}"
    run_with_spinner "pkg clean cache" pkg clean || true
    run_with_spinner "pkg update (retry)" pkg update -y || true
  fi

  if ! run_with_spinner "pkg install dependencies" \
    pkg install -y nodejs-lts git build-essential python cmake clang ninja pkg-config binutils termux-api termux-services proot tmux nano; then
    if detect_ncurses_mirror_mismatch; then
      echo -e "${RED}    Dependency install failed due to mirror package mismatch (ncurses vs ncurses-ui-libs).${NC}"
      print_mirror_recovery_hint
    else
      echo -e "${RED}    Dependency install failed.${NC}"
      echo -e "${YELLOW}    If this is a mirror issue, switch mirror with ${GREEN}termux-change-repo${YELLOW} and retry.${NC}"
    fi
    exit 1
  fi

  echo -e "${GREEN}    Dependencies installed.${NC}"
}

# --- Configure environment (idempotent managed block) ---
configure_environment() {
  echo -e "${YELLOW}[2/6] Configuring environment paths...${NC}"
  mkdir -p "$PREFIX/tmp"
  mkdir -p "$PREFIX/tmp/openclaw"
  mkdir -p "$HOME/tmp"

  local profile="$HOME/.bashrc"
  [ -n "${PROFILE:-}" ] && profile="$PROFILE"
  touch "$profile"

  # Managed block: remove old block if present, then append
  if grep -q 'OPENCLAW-ANDROID-V2 ENV' "$profile" 2>/dev/null; then
    sed -i '/# OPENCLAW-ANDROID-V2 ENV/,/# END OPENCLAW-ANDROID-V2/d' "$profile"
  fi
  {
    echo ''
    echo '# OPENCLAW-ANDROID-V2 ENV'
    echo 'export TMPDIR="$PREFIX/tmp"'
    echo 'export TMP="$PREFIX/tmp"'
    echo 'export TEMP="$PREFIX/tmp"'
    echo 'export SVDIR="$PREFIX/var/service"'
    echo '# END OPENCLAW-ANDROID-V2'
  } >> "$profile"

  export TMPDIR="$PREFIX/tmp"
  export TMP="$PREFIX/tmp"
  export TEMP="$PREFIX/tmp"
  export SVDIR="$PREFIX/var/service"
  echo -e "${GREEN}    Environment configured.${NC}"
}

# --- Node-GYP workaround ---
apply_gyp_workaround() {
  echo -e "${YELLOW}[3/6] Applying Node-GYP workaround...${NC}"
  mkdir -p ~/.gyp
  echo '{"variables":{"android_ndk_path":""}}' > ~/.gyp/include.gypi
  echo -e "${GREEN}    Done.${NC}"
}

# --- Install OpenClaw ---
install_openclaw() {
  echo -e "${YELLOW}[4/6] Installing OpenClaw via npm (may take 15–30 min on first run)...${NC}"
  local openclaw_root="$PREFIX/lib/node_modules/openclaw"
  local koffi_base="$openclaw_root/node_modules/koffi/lib/native/base/base.cc"
  local koffi_src="$openclaw_root/node_modules/koffi/build/koffi/android_arm64/koffi.node"
  local koffi_dst_dir="$openclaw_root/node_modules/build/koffi/android_arm64"

  # Android Bionic can define RENAME_NOREPLACE without exposing renameat2().
  # Install first without scripts so we can patch koffi source before build.
  run_with_spinner "npm install openclaw@latest (ignore scripts)" \
    npm install -g --ignore-scripts openclaw@latest

  if [ -f "$koffi_base" ]; then
    if grep -q '!defined(__ANDROID__)' "$koffi_base" 2>/dev/null; then
      echo -e "${GREEN}    koffi renameat2 Android guard already present.${NC}"
    else
      sed -i 's/#if defined(RENAME_NOREPLACE)/#if defined(RENAME_NOREPLACE) \&\& !defined(__ANDROID__)/' "$koffi_base"
      echo -e "${GREEN}    Patched koffi renameat2 guard for Android.${NC}"
    fi
  else
    echo -e "${YELLOW}    koffi base.cc not found; skipping source patch.${NC}"
  fi

  if [ -d "$openclaw_root" ]; then
    run_with_spinner "npm rebuild openclaw native modules" \
      npm rebuild --prefix "$openclaw_root"
  fi

  if [ -f "$koffi_src" ]; then
    mkdir -p "$koffi_dst_dir"
    cp "$koffi_src" "$koffi_dst_dir/koffi.node"
    echo -e "${GREEN}    Synced koffi.node to loader path.${NC}"
  else
    echo -e "${YELLOW}    koffi.node not found after rebuild; skipping loader-path sync.${NC}"
  fi

  echo -e "${GREEN}    OpenClaw installed.${NC}"
}

# --- Patch all /tmp/openclaw references in installed package ---
patch_openclaw_paths() {
  echo -e "${YELLOW}[5/6] Patching hardcoded /tmp/openclaw paths...${NC}"
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
    # Fallback: single file used in v1
    local f="$root/dist/entry.js"
    if [ -f "$f" ] && grep -q '/tmp/openclaw' "$f" 2>/dev/null; then
      sed -i "s|/tmp/openclaw|$PREFIX/tmp/openclaw|g" "$f"
      count=1
    fi
  fi
  if [ "$count" -gt 0 ]; then
    echo -e "${GREEN}    Patched $count file(s).${NC}"
  else
    echo -e "${YELLOW}    No files contained /tmp/openclaw (may already be patched or structure changed).${NC}"
  fi
}

# --- Create runit service definition (do not start or enable) ---
setup_service_definition() {
  echo -e "${YELLOW}[6/6] Setting up service definition (optional; not started)...${NC}"
  local service_dir="$PREFIX/var/service/openclaw"
  local log_dir="$PREFIX/var/log/openclaw"
  mkdir -p "$service_dir/log"
  mkdir -p "$log_dir"

  cat <<EOF > "$service_dir/run"
#!/data/data/com.termux/files/usr/bin/sh
export PATH=$PREFIX/bin:\$PATH
export TMPDIR=$PREFIX/tmp
exec openclaw gateway 2>&1
EOF
  cat <<EOF > "$service_dir/log/run"
#!/data/data/com.termux/files/usr/bin/sh
exec svlogd -tt $log_dir
EOF
  chmod +x "$service_dir/run"
  chmod +x "$service_dir/log/run"
  echo -e "${GREEN}    Service definition ready. Use scripts/start_claw.sh --mode service after onboarding to start.${NC}"
}

# --- Post-install summary ---
post_install_summary() {
  echo -e "\n${GREEN}============================================="
  echo -e "       SETUP COMPLETE"
  echo -e "=============================================${NC}"
  echo -e "\n${YELLOW}Next steps:${NC}"
  echo -e "  1. Run:  ${GREEN}openclaw onboard${NC}"
  echo -e "     When asked to install a Daemon/System Service: ${RED}say No${NC}."
  echo -e "  2. Then: ${GREEN}source ~/.bashrc${NC}"
  echo -e "  3. Start: ${GREEN}./scripts/start_claw.sh${NC}  (default: tmux)"
  echo -e "  4. Run:   ${GREEN}termux-wake-lock${NC}  (so it keeps running in background)"
  echo -e "  5. Open:  ${GREEN}http://localhost:18789${NC}"
  echo -e "\nOptional: run ${GREEN}./scripts/doctor_claw.sh${NC} to verify the environment."
  echo ""
}

# --- Main ---
main() {
  echo -e "${GREEN}>>> OpenClaw Android v2 Setup${NC}"
  preflight_checks
  install_dependencies
  configure_environment
  apply_gyp_workaround
  install_openclaw
  patch_openclaw_paths
  setup_service_definition
  post_install_summary
}

main "$@"
