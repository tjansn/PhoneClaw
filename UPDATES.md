# PhoneClaw Updates

## 2026-02-28: Bug Fixes and Documentation Improvements

### Fixed Issues

1. **Doctor Script False Positive** (`scripts/doctor_claw.sh`)
   - Fixed the path checking logic that incorrectly reported files as unpatched
   - Now properly distinguishes between `/tmp/openclaw` and the correctly patched `$PREFIX/tmp/openclaw`
   - Previous behavior: Reported 8 files as "unpatched" even when they were correctly patched
   - New behavior: Only reports truly unpatched files

2. **Dashboard Authentication Documentation** (`README.md`)
   - Added comprehensive instructions for accessing the dashboard with authentication token
   - Documented the `openclaw dashboard` command that generates the authenticated URL
   - Explained the `#token=...` URL parameter requirement
   - Added troubleshooting section for "unauthorized: gateway token missing" errors

3. **Path Patching Issues** (New: `scripts/fix_paths.sh`)
   - Created dedicated script to fix path patching issues
   - Handles duplicate prefix removal (e.g., `$PREFIX/$PREFIX/tmp/openclaw`)
   - Safely patches remaining `/tmp/openclaw` references
   - Verifies temp directory setup

### Documentation Improvements

1. **Phase 5: Access the Dashboard**
   - Added step-by-step instructions for both phone and computer access
   - Emphasized the importance of using the full URL with token
   - Added troubleshooting section for common authentication issues

2. **Troubleshooting Section Enhancements**
   - Added section on dashboard authentication errors
   - Updated path patching troubleshooting with new `fix_paths.sh` script
   - Clarified that some doctor warnings about `/tmp/openclaw` may be false positives
   - Added verification method: check if logs are being written to `$PREFIX/tmp/openclaw/`

3. **Quick Reference Table**
   - Added `openclaw dashboard` command
   - Added `./scripts/fix_paths.sh` command
   - Updated dashboard URL format to show token requirement
   - Clarified SSH port forwarding instructions

### New Files

- `scripts/fix_paths.sh` - Dedicated path fixing utility
  - Removes duplicate prefixes
  - Patches remaining unpatched files
  - Verifies temp directory
  - Safe to run multiple times

### Technical Details

**Doctor Script Fix:**
```bash
# Before (false positive):
if grep -q '/tmp/openclaw' "$f" 2>/dev/null; then
  # This matched /tmp/openclaw within /data/.../tmp/openclaw
fi

# After (correct detection):
if grep -v "$PREFIX/tmp/openclaw" "$f" 2>/dev/null | grep -q '/tmp/openclaw' 2>/dev/null; then
  # Only matches standalone /tmp/openclaw, not the patched version
fi
```

**Dashboard Authentication:**
- Token must be passed in URL fragment: `http://localhost:18789/#token=YOUR_TOKEN`
- Token stored in `~/.openclaw/openclaw.json` under `gateway.auth.token`
- Use `openclaw dashboard` to get the full authenticated URL automatically

### Testing Recommendations

After updating, test the following:

1. Run `./scripts/doctor_claw.sh` - should pass without false positives
2. Run `openclaw dashboard` - should display URL with token
3. Access dashboard with token URL - should connect without authentication errors
4. If issues persist, run `./scripts/fix_paths.sh` to ensure clean state

### Known Issues

- The doctor script may still report `/tmp/openclaw` references in rare edge cases where the string appears in comments or non-path contexts
- As long as the gateway is running and logs are being written to `$PREFIX/tmp/openclaw/`, the system is working correctly

### Upgrade Path

For existing installations:

```bash
cd ~/phoneclaw-setup
git pull origin main
chmod +x scripts/fix_paths.sh
./scripts/fix_paths.sh
./scripts/doctor_claw.sh
```

No gateway restart required unless path issues were detected and fixed.
