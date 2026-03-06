#!/bin/bash
# Test sync command file

echo "Testing sync command..."

CMD="$SKILL_DIR/commands/sync.md"

assert_file_exists "$CMD" "sync.md exists"
assert_contains "$CMD" -- "--status" "supports --status flag"
assert_contains "$CMD" -- "--to" "supports --to flag for vault selection"
assert_contains "$CMD" "Index.md" "updates Index.md"
assert_contains "$CMD" "CLAUDE.md" "updates CLAUDE.md"
assert_contains "$CMD" "Current Context" "boundary protection for CLAUDE.md"
assert_contains "$CMD" "孤岛" "detects orphan notes"
assert_contains "$CMD" "断链" "detects broken links"
assert_contains "$CMD" "review_needed\\|待复核" "reports review-needed notes"
assert_contains "$CMD" "目录审计\\|dir-audit\\.json\\|directory audit" "reports directory audit summary when available"
assert_contains "$CMD" "链接建议" "provides link suggestions"
assert_contains "$CMD" "AskUserQuestion" "uses AskUserQuestion for link confirmation"
