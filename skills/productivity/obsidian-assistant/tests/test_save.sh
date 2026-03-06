#!/bin/bash
# Test save command file

echo "Testing save command..."

CMD="$SKILL_DIR/commands/save.md"

assert_file_exists "$CMD" "save.md exists"
assert_contains "$CMD" "obos-config" "references vault config"
assert_contains "$CMD" "Inbox" "saves to Inbox directory"
assert_contains "$CMD" -- "--to" "supports --to flag for vault selection"
assert_contains "$CMD" "status: inbox" "sets status to inbox"
assert_contains "$CMD" "keywords" "extracts keywords for tidy"
assert_contains "$CMD" "AskUserQuestion\|零确认" "has confirmation logic"
