#!/bin/bash
# obos skill test runner
# Usage: ./tests/run.sh [command_name]
# Validates skill command files: structure, templates, consistency

set -eo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/../skill" && pwd)"
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
FIXTURE_DIR="$TEST_DIR/fixtures"
PASS=0
FAIL=0
SKIP=0

red()   { printf "\033[31m%s\033[0m\n" "$1"; }
green() { printf "\033[32m%s\033[0m\n" "$1"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$1"; }

assert_file_exists() {
  if [[ -f "$1" ]]; then
    green "  ✓ $2"
    PASS=$((PASS+1))
  else
    red "  ✗ $2 (file not found: $1)"
    FAIL=$((FAIL+1))
  fi
}

assert_contains() {
  # Usage: assert_contains file pattern desc
  #    or: assert_contains file grep_flags pattern desc
  local file="$1"; shift
  local grep_flags=()
  while [[ "$1" == -* && $# -gt 2 ]]; do
    grep_flags+=("$1"); shift
  done
  local pattern="$1" desc="$2"
  if grep -q ${grep_flags[@]+"${grep_flags[@]}"} -- "$pattern" "$file" 2>/dev/null; then
    green "  ✓ $desc"
    PASS=$((PASS+1))
  else
    red "  ✗ $desc (pattern not found: $pattern)"
    FAIL=$((FAIL+1))
  fi
}

assert_not_contains() {
  local file="$1" pattern="$2" desc="$3"
  if ! grep -q "$pattern" "$file" 2>/dev/null; then
    green "  ✓ $desc"
    PASS=$((PASS+1))
  else
    red "  ✗ $desc (should not contain: $pattern)"
    FAIL=$((FAIL+1))
  fi
}

assert_line_count() {
  local file="$1" max="$2" desc="$3"
  local count
  count=$(wc -l < "$file" | tr -d ' ')
  if [[ "$count" -le "$max" ]]; then
    green "  ✓ $desc ($count lines ≤ $max)"
    PASS=$((PASS+1))
  else
    red "  ✗ $desc ($count lines > $max)"
    FAIL=$((FAIL+1))
  fi
}

# Run test files
run_test_file() {
  local test_file="$1"
  local name
  name=$(basename "$test_file" .sh)
  echo ""
  echo "━━━ Testing: $name ━━━"
  source "$test_file"
}

# Main
echo "obos skill test suite"
echo "====================="

if [[ $# -gt 0 ]]; then
  target="$TEST_DIR/test_$1.sh"
  if [[ -f "$target" ]]; then
    run_test_file "$target"
  else
    red "Test file not found: $target"
    exit 1
  fi
else
  for f in "$TEST_DIR"/test_*.sh; do
    [[ -f "$f" ]] && run_test_file "$f"
  done
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━"
echo "Results: $(green "$PASS passed"), $(red "$FAIL failed"), $(yellow "$SKIP skipped")"
[[ "$FAIL" -eq 0 ]] && green "All tests passed!" || red "Some tests failed."
exit "$FAIL"
