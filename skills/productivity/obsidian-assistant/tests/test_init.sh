#!/bin/bash
# Test init command file

echo "Testing init command..."

CMD="$SKILL_DIR/commands/init.md"

assert_file_exists "$CMD" "init.md exists"
assert_contains "$CMD" "obos-config\|\.obsidian" "references vault discovery"
assert_not_contains "$CMD" "Fallback.*OneDrive" "does not duplicate fallback path details"
assert_contains "$CMD" -i "idempoten\|幂等" "supports idempotent execution"
assert_contains "$CMD" -i "existing\|已有\|detect\|扫描" "handles existing vault detection"
assert_contains "$CMD" "AskUserQuestion" "uses AskUserQuestion for onboarding"
assert_contains "$CMD" "CLAUDE.md" "generates CLAUDE.md"
assert_contains "$CMD" "Index.md" "generates Index.md"
assert_contains "$CMD" "Inbox/" "includes Inbox directory"
assert_contains "$CMD" "obos-config" "registers vault to config"
