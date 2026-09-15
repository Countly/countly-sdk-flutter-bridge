#!/bin/bash
#
# Integration Test Runner for Countly Flutter SDK
#
# Auto-discovers connected Android emulators, iOS simulators, and physical devices,
# categorizes test files by scanning their content, distributes tests across
# available devices in parallel, caches results, and saves logs.
#
# Usage:
#   ./scripts/run_integration_tests.sh [OPTIONS]
#
# Categories:
#   --auto              Run all unattended tests distributed across devices (default)
#   --manual            Run only manual tests (need fg/bg switching, single device)
#   --server            Run only local-server tests (SBS, BM, networking)
#   --rc                Run only remote config tests
#   --light             Run only lightweight tests
#   --all               Run everything (manual tests run last, single device)
#
# Display:
#   --list              List discovered devices and categorized tests
#   --dry-run           Show distribution plan without running
#   -v, --verbose       Stream full test output live (not just pass/fail)
#
# Caching:
#   --fresh             Ignore cache, re-run all tests (even previously passed ones)
#   --clear-cache       Delete the cache file and exit
#
# Devices:
#   -d, --device ID     Restrict to specific device(s), comma-separated
#   --timeout SECS      Per-test timeout in seconds (default: 300)
#
# Filtering:
#   --filter PATTERN    Only run tests whose path matches PATTERN (regex)
#
# Output:
#   Logs saved to test_results/<timestamp>/ in the project root:
#     worker_N.log           Full output per device
#     tests/<test_name>.log  Individual test output
#
# Examples:
#   ./scripts/run_integration_tests.sh                    # auto-discover, use cache
#   ./scripts/run_integration_tests.sh --fresh            # ignore cache, run all
#   ./scripts/run_integration_tests.sh --list             # see devices + test categories
#   ./scripts/run_integration_tests.sh --light --server   # specific categories
#   ./scripts/run_integration_tests.sh -d emulator-5554,IPHONE_UUID
#   ./scripts/run_integration_tests.sh --dry-run          # preview distribution
#   ./scripts/run_integration_tests.sh -v                 # verbose live output

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
EXAMPLE_DIR="$PROJECT_ROOT/example"
TEST_DIR="$EXAMPLE_DIR/integration_test"

# ── Config ───────────────────────────────────────────────────────────
TIMEOUT=300s
RUN_MANUAL=false
RUN_SERVER=false
RUN_RC=false
RUN_LIGHT=false
RUN_AUTO=false
LIST_ONLY=false
DRY_RUN=false
VERBOSE=false
FRESH=false
CLEAR_CACHE=false
RESTRICT_DEVICES=""
TEST_FILTER=""

# Colors (bold)
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
DIM='\033[2m'
NC='\033[0m'

# Persistent paths
RESULTS_BASE="$PROJECT_ROOT/test_results"
CACHE_FILE="$RESULTS_BASE/.cache"
LOG_DIR=""

# Temp directory for internal bookkeeping (cleaned up on exit)
WORK_DIR=""

cleanup() {
  if [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]]; then
    rm -rf "$WORK_DIR"
  fi
}
trap cleanup EXIT

# ── Device Discovery ─────────────────────────────────────────────────

discover_devices() {
  local devices=()

  # ── Android: emulators and physical devices via adb ──
  if command -v adb &>/dev/null; then
    while IFS= read -r line; do
      local id state
      id=$(echo "$line" | awk '{print $1}')
      state=$(echo "$line" | awk '{print $2}')
      if [[ -n "$id" && "$state" == "device" ]]; then
        devices+=("android:$id")
      fi
    done < <(adb devices 2>/dev/null | tail -n +2 | grep -v '^$')
  fi

  # ── iOS: booted simulators via simctl ──
  if command -v xcrun &>/dev/null; then
    while IFS= read -r line; do
      local uuid
      uuid=$(echo "$line" | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')
      if [[ -n "$uuid" ]]; then
        devices+=("ios:$uuid")
      fi
    done < <(xcrun simctl list devices booted 2>/dev/null | awk '/^-- /{ios=($0 ~ /^-- iOS /)} ios && /Booted/')
  fi

  # ── iOS: connected physical devices (via idevice_id or flutter) ──
  if command -v idevice_id &>/dev/null; then
    while IFS= read -r udid; do
      if [[ -n "$udid" ]]; then
        # Check not already found
        local found=false
        for d in "${devices[@]+"${devices[@]}"}"; do
          [[ "$d" == *"$udid"* ]] && found=true && break
        done
        $found || devices+=("ios:$udid")
      fi
    done < <(idevice_id -l 2>/dev/null)
  fi

  echo "${devices[@]+"${devices[@]}"}"
}

get_device_label() {
  local device="$1"
  local platform="${device%%:*}"
  local id="${device#*:}"

  if [[ "$platform" == "android" ]]; then
    local model
    model=$(adb -s "$id" shell getprop ro.product.model 2>/dev/null | tr -d '\r' || echo "$id")
    echo "[Android] $model ($id)"
  else
    local name
    name=$(xcrun simctl list devices 2>/dev/null | grep "$id" | sed 's/(.*//' | xargs 2>/dev/null || echo "$id")
    if [[ -z "$name" || "$name" == "$id" ]]; then
      echo "[iOS] $id"
    else
      echo "[iOS] $name ($id)"
    fi
  fi
}

# ── Test Discovery ───────────────────────────────────────────────────

MANUAL_PATTERNS='FlutterForegroundTask\.(minimizeApp|launchApp)|goBackgroundAndForeground\(\)|goForeground\(\)|goBackground\(\)'
SERVER_PATTERN='createServer\('
RC_PATTERN='SERVER_URL_RC|APP_KEY_RC'

discover_tests() {
  local manual_tests=()
  local server_tests=()
  local rc_tests=()
  local light_tests=()

  # Pre-scan local utility files (not the shared utils.dart) for category traits.
  # utils.dart is imported by everything and defines helpers for all categories,
  # so including it would mark every test as manual.
  local util_traits=()
  while IFS= read -r util_file; do
    local ubasename
    ubasename=$(basename "$util_file")
    [[ "$ubasename" == "utils.dart" ]] && continue
    local util_content traits=""
    util_content=$(cat "$util_file")
    echo "$util_content" | grep -qE "$MANUAL_PATTERNS" && traits="${traits}manual,"
    echo "$util_content" | grep -qE "$SERVER_PATTERN" && traits="${traits}server,"
    echo "$util_content" | grep -qE "$RC_PATTERN" && traits="${traits}rc,"
    [[ -n "$traits" ]] && util_traits+=("${ubasename}:${traits}")
  done < <(find "$TEST_DIR" \( -name "*utils*.dart" -o -name "*_utils.dart" \) -type f)

  # Scan each test file
  while IFS= read -r test_file; do
    local rel_path="${test_file#$TEST_DIR/}"

    # Skip utility files
    [[ "$rel_path" == *"utils.dart" || "$rel_path" == *"_utils.dart" ]] && continue

    # Apply --filter pattern
    if [[ -n "$TEST_FILTER" ]] && ! echo "$rel_path" | grep -qE "$TEST_FILTER"; then
      continue
    fi

    local content is_manual=false is_server=false is_rc=false
    content=$(cat "$test_file")

    # Direct pattern match
    echo "$content" | grep -qE "$MANUAL_PATTERNS" && is_manual=true
    echo "$content" | grep -qE "$SERVER_PATTERN" && is_server=true
    echo "$content" | grep -qE "$RC_PATTERN" && is_rc=true

    # Transitive match via imported local utils
    while IFS= read -r import_line; do
      local imported_file
      imported_file=$(echo "$import_line" | grep -oE "'[^']+'" | tr -d "'" | xargs basename 2>/dev/null)
      if [[ -n "$imported_file" ]]; then
        for ut_entry in "${util_traits[@]+"${util_traits[@]}"}"; do
          local ut_name="${ut_entry%%:*}"
          local ut_traits="${ut_entry#*:}"
          if [[ "$ut_name" == "$imported_file" ]]; then
            [[ "$ut_traits" == *"manual"* ]] && is_manual=true
            [[ "$ut_traits" == *"server"* ]] && is_server=true
            [[ "$ut_traits" == *"rc"* ]] && is_rc=true
            break
          fi
        done
      fi
    done < <(echo "$content" | grep "^import " | grep -v "package:")

    # Priority: manual > server > rc > light
    if $is_manual; then
      manual_tests+=("$rel_path")
    elif $is_server; then
      server_tests+=("$rel_path")
    elif $is_rc; then
      rc_tests+=("$rel_path")
    else
      light_tests+=("$rel_path")
    fi
  done < <(find "$TEST_DIR" -name "*_test.dart" -type f | sort)

  # Write to temp files
  if [[ ${#manual_tests[@]} -gt 0 ]]; then printf '%s\n' "${manual_tests[@]}" > "$WORK_DIR/tests_manual.txt"; else touch "$WORK_DIR/tests_manual.txt"; fi
  if [[ ${#server_tests[@]} -gt 0 ]]; then printf '%s\n' "${server_tests[@]}" > "$WORK_DIR/tests_server.txt"; else touch "$WORK_DIR/tests_server.txt"; fi
  if [[ ${#rc_tests[@]} -gt 0 ]]; then printf '%s\n' "${rc_tests[@]}" > "$WORK_DIR/tests_rc.txt"; else touch "$WORK_DIR/tests_rc.txt"; fi
  if [[ ${#light_tests[@]} -gt 0 ]]; then printf '%s\n' "${light_tests[@]}" > "$WORK_DIR/tests_light.txt"; else touch "$WORK_DIR/tests_light.txt"; fi
}

count_tests() {
  local n
  n=$(grep -c '[^ ]' "$1" 2>/dev/null) || true
  echo "${n:-0}"
}

# ── Cache ────────────────────────────────────────────────────────────
# Cache is per-platform: passing on Android doesn't mean passing on iOS.
# Separate cache files: .cache_android, .cache_ios
# Format: one line per passed test:
#   <test_relative_path> <composite_hash>
#
# The composite hash covers:
#   - The test file itself
#   - All local imports (utils.dart, sbs_utils.dart, etc.)
#   - The SDK pubspec.yaml (version changes invalidate everything)
# So editing utils.dart or bumping the SDK version invalidates all cached results.

_cache_file_for_platform() {
  echo "$RESULTS_BASE/.cache_${1}"
}

# Compute a composite hash for a test: the test file + its local imports + SDK version
_compute_test_hash() {
  local test_path="$1"
  local test_file="$TEST_DIR/$test_path"
  local files_to_hash="$test_file"

  # Find local imports (non-package imports) and resolve them relative to the test file
  local test_dir
  test_dir=$(dirname "$test_file")
  while IFS= read -r import_line; do
    local rel_import
    rel_import=$(echo "$import_line" | grep -oE "'[^']+'" | tr -d "'")
    if [[ -n "$rel_import" ]]; then
      local resolved="$test_dir/$rel_import"
      [[ -f "$resolved" ]] && files_to_hash="$files_to_hash $resolved"
    fi
  done < <(grep "^import " "$test_file" 2>/dev/null | grep -v "package:")

  # Also include the SDK pubspec (version changes should invalidate cache)
  local sdk_pubspec="$PROJECT_ROOT/pubspec.yaml"
  [[ -f "$sdk_pubspec" ]] && files_to_hash="$files_to_hash $sdk_pubspec"

  # Hash all files together
  cat $files_to_hash 2>/dev/null | shasum -a 256 | awk '{print $1}'
}

cache_is_passed() {
  local test_path="$1"
  local platform="$2"
  $FRESH && return 1

  local cf
  cf=$(_cache_file_for_platform "$platform")
  [[ ! -f "$cf" ]] && return 1

  local current_hash
  current_hash=$(_compute_test_hash "$test_path")
  grep -q "^${test_path} ${current_hash}$" "$cf" 2>/dev/null
}


cache_mark_passed() {
  local test_path="$1"
  local platform="$2"
  local cf
  cf=$(_cache_file_for_platform "$platform")
  mkdir -p "$(dirname "$cf")"

  local current_hash
  current_hash=$(_compute_test_hash "$test_path")

  if [[ -f "$cf" ]]; then
    grep -v "^${test_path} " "$cf" > "$cf.tmp" 2>/dev/null || true
    mv "$cf.tmp" "$cf"
  fi
  echo "${test_path} ${current_hash}" >> "$cf"
}

cache_mark_failed() {
  local test_path="$1"
  local platform="$2"
  local cf
  cf=$(_cache_file_for_platform "$platform")
  [[ ! -f "$cf" ]] && return
  grep -v "^${test_path} " "$cf" > "$cf.tmp" 2>/dev/null || true
  mv "$cf.tmp" "$cf"
}

# Filter out tests that are cached (passed) on a single platform.
filter_cached_tests() {
  local input_file="$1"
  local output_file="$2"
  local platform="$3"
  local skipped=0

  > "$output_file"
  while IFS= read -r test; do
    [[ -z "$test" ]] && continue
    if cache_is_passed "$test" "$platform"; then
      ((skipped++))
    else
      echo "$test" >> "$output_file"
    fi
  done < "$input_file"

  echo "$skipped"
}

# ── Distribution ─────────────────────────────────────────────────────

distribute_tests() {
  local -a devices=($1)
  shift
  local -a tests=("$@")
  local num_devices=${#devices[@]}

  [[ $num_devices -eq 0 || ${#tests[@]} -eq 0 ]] && return

  for i in $(seq 0 $((num_devices - 1))); do
    > "$WORK_DIR/device_${i}_tests.txt"
  done

  local idx=0
  for test in "${tests[@]}"; do
    echo "$test" >> "$WORK_DIR/device_$((idx % num_devices))_tests.txt"
    ((idx++))
  done
}

# ── Worker ───────────────────────────────────────────────────────────

run_worker() {
  local worker_id="$1"
  local device="$2"
  local test_list_file="$3"
  local log_file="$LOG_DIR/worker_${worker_id}.log"
  local result_file="$WORK_DIR/worker_${worker_id}.result"
  local platform="${device%%:*}"
  local device_id="${device#*:}"
  local passed=0 failed=0
  local failed_tests=()
  local start_time=$SECONDS

  # Stagger iOS worker starts to prevent Xcode concurrent build lock conflicts
  # Android workers start immediately (Gradle handles concurrency fine)
  local ios_stagger="${4:-0}"
  if [[ "$platform" == "ios" && $ios_stagger -gt 0 ]]; then
    sleep $((ios_stagger * 40))
  fi

  {
    echo "════════════════════════════════════════════════════"
    echo "  Worker $worker_id — $(get_device_label "$device")"
    echo "  Started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "════════════════════════════════════════════════════"
    echo ""
  } > "$log_file"

  while IFS= read -r test; do
    [[ -z "$test" ]] && continue

    local test_path="integration_test/$test"
    local test_log="$LOG_DIR/tests/${test//\//__}.log"
    local test_start=$SECONDS
    mkdir -p "$(dirname "$test_log")"

    echo "[W$worker_id] ▶ $test" >> "$log_file"

    local port=$((8080 + worker_id))
    if (cd "$EXAMPLE_DIR" && flutter test "$test_path" -d "$device_id" --timeout "$TIMEOUT" --dart-define=TEST_SERVER_PORT=$port 2>&1 | tee "$test_log" >> "$log_file"); then
      local elapsed=$(( SECONDS - test_start ))
      echo "[W$worker_id] ✓ PASSED ($test) ${elapsed}s" >> "$log_file"
      cache_mark_passed "$test" "$platform"
      ((passed++))
    else
      local elapsed=$(( SECONDS - test_start ))
      echo "[W$worker_id] ✗ FAILED ($test) ${elapsed}s" >> "$log_file"
      cache_mark_failed "$test" "$platform"
      ((failed++))
      failed_tests+=("$test")
    fi
    echo "" >> "$log_file"
  done < "$test_list_file"

  local total_time=$(( SECONDS - start_time ))
  {
    echo "worker=$worker_id"
    echo "device=$device"
    echo "passed=$passed"
    echo "failed=$failed"
    echo "time=$total_time"
    for ft in "${failed_tests[@]+"${failed_tests[@]}"}"; do
      echo "failed_test=$ft"
    done
  } > "$result_file"

  return $failed
}

# ── Live Progress ────────────────────────────────────────────────────

show_live_progress() {
  local num_workers="$1"
  local colors=("$RED" "$GREEN" "$YELLOW" "$CYAN" "\033[0;35m" "\033[0;36m")

  for i in $(seq 0 $((num_workers - 1))); do
    local color="${colors[$((i % ${#colors[@]}))]}"
    local log="$LOG_DIR/worker_${i}.log"
    touch "$log"
    if $VERBOSE; then
      tail -f "$log" 2>/dev/null | while IFS= read -r line; do
        echo -e "${color}${line}${NC}"
      done &
    else
      tail -f "$log" 2>/dev/null | grep --line-buffered -E '(▶|✓|✗)' | while IFS= read -r line; do
        echo -e "${color}${line}${NC}"
      done &
    fi
  done
}

# ── Parse Arguments ──────────────────────────────────────────────────

HAS_CATEGORY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --auto)         RUN_AUTO=true; HAS_CATEGORY=true; shift ;;
    --manual)       RUN_MANUAL=true; HAS_CATEGORY=true; shift ;;
    --server)       RUN_SERVER=true; HAS_CATEGORY=true; shift ;;
    --rc)           RUN_RC=true; HAS_CATEGORY=true; shift ;;
    --light)        RUN_LIGHT=true; HAS_CATEGORY=true; shift ;;
    --all)          RUN_MANUAL=true; RUN_SERVER=true; RUN_RC=true; RUN_LIGHT=true; HAS_CATEGORY=true; shift ;;
    --list)         LIST_ONLY=true; HAS_CATEGORY=true; shift ;;
    --dry-run)      DRY_RUN=true; shift ;;
    -v|--verbose)   VERBOSE=true; shift ;;
    --fresh)        FRESH=true; shift ;;
    --clear-cache)  CLEAR_CACHE=true; shift ;;
    -d|--device)    RESTRICT_DEVICES="$2"; shift 2 ;;
    --timeout)      TIMEOUT="$2"; shift 2 ;;
    --filter)       TEST_FILTER="$2"; shift 2 ;;
    -h|--help)
      head -48 "$0" | tail -n +2 | sed 's/^# \?//'
      exit 0 ;;
    *)
      echo "Unknown option: $1 (use --help)"; exit 1 ;;
  esac
done

if ! $HAS_CATEGORY; then
  RUN_AUTO=true
fi
if $RUN_AUTO; then
  RUN_SERVER=true; RUN_RC=true; RUN_LIGHT=true
fi

# ── Main ─────────────────────────────────────────────────────────────

main() {

# Handle --clear-cache
if $CLEAR_CACHE; then
  local cleared=false
  for p in android ios; do
    local cf
    cf=$(_cache_file_for_platform "$p")
    if [[ -f "$cf" ]]; then
      rm "$cf"
      cleared=true
    fi
  done
  if $cleared; then
    echo -e "${GREEN}Cache cleared (android + ios).${NC}"
  else
    echo -e "${DIM}No cache files found.${NC}"
  fi
  return 0
fi

WORK_DIR=$(mktemp -d)

echo -e "${WHITE}Countly Flutter SDK - Integration Test Runner${NC}"
echo ""

# ── Step 1: Discover devices ──────────────────────────────────────
echo -e "${DIM}Scanning for devices...${NC}"
DEVICE_LIST=($(discover_devices))

# Apply device filter
if [[ -n "$RESTRICT_DEVICES" ]]; then
  IFS=',' read -ra FILTER <<< "$RESTRICT_DEVICES"
  FILTERED=()
  for device in "${DEVICE_LIST[@]+"${DEVICE_LIST[@]}"}"; do
    local did="${device#*:}"
    for f in "${FILTER[@]}"; do
      [[ "$did" == "$f" ]] && FILTERED+=("$device") && break
    done
  done
  DEVICE_LIST=("${FILTERED[@]+"${FILTERED[@]}"}")
fi

if [[ ${#DEVICE_LIST[@]} -eq 0 ]]; then
  echo -e "${RED}No devices found!${NC}"
  echo ""
  echo "Start a device first:"
  echo "  Android emulator:    flutter emulators --launch Pixel_9_Pro_XL_API_36"
  echo "  iOS simulator:       open -a Simulator"
  echo "  Check connected:     adb devices && xcrun simctl list devices booted"
  return 1
fi

echo -e "${GREEN}Found ${#DEVICE_LIST[@]} device(s):${NC}"
for device in "${DEVICE_LIST[@]}"; do
  echo -e "  ${CYAN}●${NC} $(get_device_label "$device")"
done

# ── Step 2: Discover and categorize tests ─────────────────────────
echo ""
echo -e "${DIM}Scanning for tests...${NC}"
discover_tests

local MANUAL_COUNT SERVER_COUNT RC_COUNT LIGHT_COUNT TOTAL_COUNT
MANUAL_COUNT=$(count_tests "$WORK_DIR/tests_manual.txt")
SERVER_COUNT=$(count_tests "$WORK_DIR/tests_server.txt")
RC_COUNT=$(count_tests "$WORK_DIR/tests_rc.txt")
LIGHT_COUNT=$(count_tests "$WORK_DIR/tests_light.txt")
TOTAL_COUNT=$((MANUAL_COUNT + SERVER_COUNT + RC_COUNT + LIGHT_COUNT))

echo -e "${GREEN}Found $TOTAL_COUNT test(s):${NC}"
echo -e "  Light: $LIGHT_COUNT  Server: $SERVER_COUNT  RC: $RC_COUNT  Manual: $MANUAL_COUNT"

# Show cache status per platform
if ! $FRESH; then
  for p in android ios; do
    local cf
    cf=$(_cache_file_for_platform "$p")
    if [[ -f "$cf" ]]; then
      local cached_count
      cached_count=$(wc -l < "$cf" | tr -d ' ')
      echo -e "  ${DIM}Cache ($p): $cached_count passed (use --fresh to re-run)${NC}"
    fi
  done
fi

# ── List mode ─────────────────────────────────────────────────────
if $LIST_ONLY; then
  echo ""
  for category in manual server rc light; do
    local file="$WORK_DIR/tests_${category}.txt"
    local label
    case "$category" in
      manual) label="Manual (fg/bg switching required)" ;;
      server) label="Server (local test server)" ;;
      rc)     label="Remote Config (needs network)" ;;
      light)  label="Lightweight (no server needed)" ;;
    esac
    local count
    count=$(count_tests "$file")
    echo -e "${YELLOW}$label ($count):${NC}"
    while IFS= read -r test; do
      if [[ -n "$test" ]]; then
        local cache_status=""
        for p in android ios; do
          if cache_is_passed "$test" "$p"; then
            cache_status="${cache_status}${p} "
          fi
        done
        if [[ -n "$cache_status" ]]; then
          echo -e "  ${DIM}✓ $test (cached: ${cache_status% })${NC}"
        else
          echo "  $test"
        fi
      fi
    done < "$file"
    echo ""
  done
  return 0
fi

# ── Step 3: Build test list, applying per-platform cache ──────────
# Determine which platforms are active from the device list
local ACTIVE_PLATFORMS=()
for device in "${DEVICE_LIST[@]}"; do
  local p="${device%%:*}"
  # Add unique platforms only
  local already=false
  for ap in "${ACTIVE_PLATFORMS[@]+"${ACTIVE_PLATFORMS[@]}"}"; do
    [[ "$ap" == "$p" ]] && already=true && break
  done
  $already || ACTIVE_PLATFORMS+=("$p")
done
echo -e "  ${DIM}Active platforms: ${ACTIVE_PLATFORMS[*]}${NC}"

# Build per-platform filtered test lists (each platform uses its own cache)
# Collect all tests to run per category first
local ALL_AUTO_TESTS=()
for category in light server rc; do
  local should_run=false
  case "$category" in
    light)  $RUN_LIGHT && should_run=true ;;
    server) $RUN_SERVER && should_run=true ;;
    rc)     $RUN_RC && should_run=true ;;
  esac
  if $should_run; then
    while IFS= read -r t; do [[ -n "$t" ]] && ALL_AUTO_TESTS+=("$t"); done < "$WORK_DIR/tests_${category}.txt"
  fi
done

local ALL_MANUAL_TESTS=()
if $RUN_MANUAL; then
  while IFS= read -r t; do [[ -n "$t" ]] && ALL_MANUAL_TESTS+=("$t"); done < "$WORK_DIR/tests_manual.txt"
fi

# Write the full test list to a temp file for filtering
local all_auto_file="$WORK_DIR/all_auto.txt"
local all_manual_file="$WORK_DIR/all_manual.txt"
printf '%s\n' "${ALL_AUTO_TESTS[@]+"${ALL_AUTO_TESTS[@]}"}" > "$all_auto_file"
printf '%s\n' "${ALL_MANUAL_TESTS[@]+"${ALL_MANUAL_TESTS[@]}"}" > "$all_manual_file"

# Filter per platform and show skip counts
local TOTAL_SKIPPED_DISPLAY=""
for p in "${ACTIVE_PLATFORMS[@]}"; do
  local filtered="$WORK_DIR/filtered_auto_${p}.txt"
  local skipped
  skipped=$(filter_cached_tests "$all_auto_file" "$filtered" "$p")
  if [[ $skipped -gt 0 ]]; then
    TOTAL_SKIPPED_DISPLAY="${TOTAL_SKIPPED_DISPLAY}  ${GREEN}Skipping $skipped cached test(s) on $p${NC}\n"
  fi
  # Also filter manual tests per platform
  local filtered_manual="$WORK_DIR/filtered_manual_${p}.txt"
  local manual_skipped
  manual_skipped=$(filter_cached_tests "$all_manual_file" "$filtered_manual" "$p")
  if [[ $manual_skipped -gt 0 ]]; then
    TOTAL_SKIPPED_DISPLAY="${TOTAL_SKIPPED_DISPLAY}  ${GREEN}Skipping $manual_skipped cached manual test(s) on $p${NC}\n"
  fi
done

if [[ -n "$TOTAL_SKIPPED_DISPLAY" ]]; then
  echo -e "$TOTAL_SKIPPED_DISPLAY"
fi

# Check if there's anything to run across all platforms
local has_auto=false has_manual=false
for p in "${ACTIVE_PLATFORMS[@]}"; do
  [[ -s "$WORK_DIR/filtered_auto_${p}.txt" ]] && has_auto=true
  [[ -s "$WORK_DIR/filtered_manual_${p}.txt" ]] && has_manual=true
done

if ! $has_auto && ! $has_manual; then
  echo ""
  echo -e "${GREEN}All tests already passed (cached) on all platforms. Use --fresh to re-run.${NC}"
  return 0
fi

# ── Step 4: Distribute per-platform filtered tests across devices ──
local NUM_DEVICES=${#DEVICE_LIST[@]}

# Assign each device its platform-filtered test list
for i in $(seq 0 $((NUM_DEVICES - 1))); do
  local device="${DEVICE_LIST[$i]}"
  local p="${device%%:*}"
  cp "$WORK_DIR/filtered_auto_${p}.txt" "$WORK_DIR/device_${i}_tests_full.txt"
done

# Round-robin distribute: for devices sharing a platform, split their shared list
# Group devices by platform, then distribute each platform's tests among its devices
for p in "${ACTIVE_PLATFORMS[@]}"; do
  local -a platform_device_indices=()
  for i in $(seq 0 $((NUM_DEVICES - 1))); do
    local device="${DEVICE_LIST[$i]}"
    [[ "${device%%:*}" == "$p" ]] && platform_device_indices+=("$i")
  done

  local num_p_devices=${#platform_device_indices[@]}
  if [[ $num_p_devices -le 1 ]]; then
    # Single device for this platform — it gets all tests
    for idx in "${platform_device_indices[@]}"; do
      cp "$WORK_DIR/filtered_auto_${p}.txt" "$WORK_DIR/device_${idx}_tests.txt"
    done
  else
    # Multiple devices — round-robin split
    for idx in "${platform_device_indices[@]}"; do
      > "$WORK_DIR/device_${idx}_tests.txt"
    done
    local rr=0
    while IFS= read -r test; do
      [[ -z "$test" ]] && continue
      local target_idx="${platform_device_indices[$((rr % num_p_devices))]}"
      echo "$test" >> "$WORK_DIR/device_${target_idx}_tests.txt"
      ((rr++))
    done < "$WORK_DIR/filtered_auto_${p}.txt"
  fi
done

# Count total running tests
local total_auto=0 total_manual=0
for i in $(seq 0 $((NUM_DEVICES - 1))); do
  local c; c=$(count_tests "$WORK_DIR/device_${i}_tests.txt")
  total_auto=$((total_auto + c))
done
# Manual: collect tests uncached on ANY platform (user picks device later, re-filtered then)
local MANUAL_TESTS_TO_RUN=()
if $RUN_MANUAL; then
  local manual_combined="$WORK_DIR/manual_combined.txt"
  > "$manual_combined"
  for p in "${ACTIVE_PLATFORMS[@]}"; do
    cat "$WORK_DIR/filtered_manual_${p}.txt" >> "$manual_combined" 2>/dev/null
  done
  # Deduplicate
  while IFS= read -r t; do
    [[ -n "$t" ]] && MANUAL_TESTS_TO_RUN+=("$t")
  done < <(sort -u "$manual_combined")
fi
total_manual=${#MANUAL_TESTS_TO_RUN[@]}

echo -e "  ${WHITE}Running: $total_auto auto + $total_manual manual${NC}"

echo ""
if [[ $total_auto -gt 0 ]]; then
  echo -e "${WHITE}Distribution Plan:${NC}"
  for i in $(seq 0 $((NUM_DEVICES - 1))); do
    local count
    count=$(count_tests "$WORK_DIR/device_${i}_tests.txt")
    echo -e "  ${CYAN}●${NC} $(get_device_label "${DEVICE_LIST[$i]}") → $count test(s)"
    if $DRY_RUN; then
      while IFS= read -r t; do
        [[ -n "$t" ]] && echo -e "      $t"
      done < "$WORK_DIR/device_${i}_tests.txt"
    fi
  done
fi

if [[ $total_manual -gt 0 ]]; then
  echo -e "  ${YELLOW}●${NC} Manual tests (after parallel run) → $total_manual test(s)"
fi

if $DRY_RUN; then
  echo -e "\n${DIM}Dry run complete. Remove --dry-run to execute.${NC}"
  return 0
fi

# ── Step 5: Create log directory & launch workers ─────────────────
local OVERALL_START=$SECONDS
local WORKER_PIDS=()
local run_ts
run_ts=$(date '+%Y%m%d_%H%M%S')
LOG_DIR="$RESULTS_BASE/${run_ts}"
mkdir -p "$LOG_DIR/tests"

local TOTAL_PASSED=0
local TOTAL_FAILED=0
local ALL_FAILED_TESTS=()

if [[ $total_auto -gt 0 ]]; then
  echo ""
  echo -e "${WHITE}Running $total_auto unattended tests across ${NUM_DEVICES} device(s)...${NC}"
  echo -e "${DIM}Logs → $LOG_DIR${NC}"

  echo ""

  local ios_count=0
  for i in $(seq 0 $((NUM_DEVICES - 1))); do
    local test_file="$WORK_DIR/device_${i}_tests.txt"
    local count
    count=$(count_tests "$test_file")
    if [[ $count -gt 0 ]]; then
      local stagger=0
      if [[ "${DEVICE_LIST[$i]%%:*}" == "ios" ]]; then
        stagger=$ios_count
        ((ios_count++))
      fi
      run_worker "$i" "${DEVICE_LIST[$i]}" "$test_file" "$stagger" &
      WORKER_PIDS+=($!)
    fi
  done

  show_live_progress "$NUM_DEVICES"

  # Wait for all workers
  for pid in "${WORKER_PIDS[@]}"; do
    wait "$pid" || true
  done

  # Kill tail processes
  jobs -p 2>/dev/null | xargs kill 2>/dev/null || true
  wait 2>/dev/null || true

  echo ""

  # ── Step 6: Aggregate results ───────────────────────────────────
  echo -e "${WHITE}═══════════════════════════════════════════════════${NC}"
  echo -e "${WHITE}  Results${NC}"
  echo -e "${WHITE}═══════════════════════════════════════════════════${NC}"

  for i in $(seq 0 $((NUM_DEVICES - 1))); do
    local result_file="$WORK_DIR/worker_${i}.result"
    [[ ! -f "$result_file" ]] && continue

    local w_device="" w_passed=0 w_failed=0 w_time=0
    local w_failed_tests=()

    while IFS='=' read -r key value; do
      case "$key" in
        device)      w_device="$value" ;;
        passed)      w_passed="$value" ;;
        failed)      w_failed="$value" ;;
        time)        w_time="$value" ;;
        failed_test) w_failed_tests+=("$value") ;;
      esac
    done < "$result_file"

    echo ""
    echo -e "  ${CYAN}●${NC} $(get_device_label "$w_device")"
    echo -e "    ${GREEN}Passed: $w_passed${NC}  ${RED}Failed: $w_failed${NC}  Time: ${w_time}s"

    for ft in "${w_failed_tests[@]+"${w_failed_tests[@]}"}"; do
      echo -e "    ${RED}✗${NC} $ft"
      ALL_FAILED_TESTS+=("$ft")
    done

    TOTAL_PASSED=$((TOTAL_PASSED + w_passed))
    TOTAL_FAILED=$((TOTAL_FAILED + w_failed))
  done
fi

# ── Step 7: Manual tests (single device, sequential) ─────────────
if [[ ${#MANUAL_TESTS_TO_RUN[@]} -gt 0 ]]; then
  echo ""
  echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
  echo -e "${YELLOW}  Manual Tests (${#MANUAL_TESTS_TO_RUN[@]} tests)${NC}"
  echo -e "${YELLOW}  These need you at the device for fg/bg switching.${NC}"
  echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
  echo ""
  echo "Which device for manual tests?"
  for i in $(seq 0 $((NUM_DEVICES - 1))); do
    echo "  [$i] $(get_device_label "${DEVICE_LIST[$i]}")"
  done
  read -p "Device number [0]: " manual_device_idx
  manual_device_idx=${manual_device_idx:-0}

  local manual_device="${DEVICE_LIST[$manual_device_idx]}"
  local manual_platform="${manual_device%%:*}"
  local manual_device_id="${manual_device#*:}"

  # Re-filter manual tests for the selected device's platform
  local manual_filtered="$WORK_DIR/filtered_manual_selected.txt"
  filter_cached_tests "$all_manual_file" "$manual_filtered" "$manual_platform" > /dev/null
  MANUAL_TESTS_TO_RUN=()
  while IFS= read -r t; do [[ -n "$t" ]] && MANUAL_TESTS_TO_RUN+=("$t"); done < "$manual_filtered"

  if [[ ${#MANUAL_TESTS_TO_RUN[@]} -eq 0 ]]; then
    echo -e "\n${GREEN}All manual tests already passed (cached) on $manual_platform. Use --fresh to re-run.${NC}"
  else
    echo ""
    read -p "Press Enter when ready (stay at the device)..."
  fi

  local manual_passed=0 manual_failed=0

  for test in "${MANUAL_TESTS_TO_RUN[@]}"; do
    echo -e "\n${CYAN}▶${NC} $test"
    local test_start=$SECONDS
    local test_log="$LOG_DIR/tests/${test//\//__}.log"
    mkdir -p "$(dirname "$test_log")"

    if (cd "$EXAMPLE_DIR" && flutter test "integration_test/$test" -d "$manual_device_id" --timeout "$TIMEOUT" --dart-define=TEST_SERVER_PORT=8080 2>&1 | tee "$test_log"); then
      local elapsed=$(( SECONDS - test_start ))
      echo -e "${GREEN}  ✓ PASSED${NC} (${elapsed}s)"
      cache_mark_passed "$test" "$manual_platform"
      ((manual_passed++))
    else
      local elapsed=$(( SECONDS - test_start ))
      echo -e "${RED}  ✗ FAILED${NC} (${elapsed}s)"
      cache_mark_failed "$test" "$manual_platform"
      ((manual_failed++))
      ALL_FAILED_TESTS+=("$test")
    fi
  done

  TOTAL_PASSED=$((TOTAL_PASSED + manual_passed))
  TOTAL_FAILED=$((TOTAL_FAILED + manual_failed))
fi

# ── Final Summary ─────────────────────────────────────────────────
local OVERALL_TIME=$(( SECONDS - OVERALL_START ))

echo ""
echo -e "${WHITE}═══════════════════════════════════════════════════${NC}"
echo -e "${WHITE}  Final Summary${NC}"
echo -e "${WHITE}═══════════════════════════════════════════════════${NC}"
echo -e "  Ran: $((TOTAL_PASSED + TOTAL_FAILED))  ${GREEN}Passed: $TOTAL_PASSED${NC}  ${RED}Failed: $TOTAL_FAILED${NC}"
echo -e "  Wall time: ${OVERALL_TIME}s"

if [[ ${#ALL_FAILED_TESTS[@]} -gt 0 ]]; then
  echo ""
  echo -e "  ${RED}Failed tests:${NC}"
  for ft in "${ALL_FAILED_TESTS[@]}"; do
    echo -e "    ${RED}✗${NC} $ft"
    echo -e "      ${DIM}→ cat $LOG_DIR/tests/${ft//\//__}.log${NC}"
  done
fi

echo ""
echo -e "  ${DIM}Full logs:     $LOG_DIR/${NC}"
echo -e "  ${DIM}Worker logs:   cat $LOG_DIR/worker_N.log${NC}"
echo -e "  ${DIM}Per-test logs: cat $LOG_DIR/tests/<name>.log${NC}"
echo ""

if [[ $TOTAL_FAILED -eq 0 ]]; then
  echo -e "  ${GREEN}All tests passed!${NC}"
  osascript -e "display notification \"✅ All $TOTAL_PASSED tests passed (${OVERALL_TIME}s)\" with title \"Flutter Integration Tests\" sound name \"Glass\""
else
  echo -e "  ${RED}$TOTAL_FAILED test(s) failed.${NC}"
  osascript -e "display notification \"❌ $TOTAL_FAILED failed, $TOTAL_PASSED passed (${OVERALL_TIME}s)\" with title \"Flutter Integration Tests\" sound name \"Basso\""
fi

return $TOTAL_FAILED
}

main
exit $?
