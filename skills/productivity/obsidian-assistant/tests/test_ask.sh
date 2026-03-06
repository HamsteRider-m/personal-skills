#!/bin/bash
# Test ask command file

echo "Testing ask command..."

CMD="$SKILL_DIR/commands/ask.md"

assert_file_exists "$CMD" "ask.md exists"

assert_contains "$CMD" "Vault Path Discovery" "references shared Vault Path Discovery"

# Key features per design doc §3.7
assert_contains "$CMD" -i "Index.md" "reads Index.md for candidates"
assert_contains "$CMD" -i "Glob\|Grep\|search" "uses search tools"
assert_contains "$CMD" -i "wikilink\|\[\[" "cites sources with wikilinks"
assert_contains "$CMD" -i "no.*match\|无.*相关\|not found" "handles no-match gracefully"
