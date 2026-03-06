#!/bin/bash
echo "Testing review command..."
CMD="$SKILL_DIR/commands/review.md"
assert_file_exists "$CMD" "review.md exists"
assert_contains "$CMD" -- "--to" "supports --to flag"
assert_contains "$CMD" "Inbox" "reports Inbox status"
assert_contains "$CMD" "孤岛" "reports orphan notes"
assert_contains "$CMD" "下一步\|建议" "provides next action suggestion"
assert_contains "$CMD" "tidy\|sync\|refine" "suggests follow-up commands"
