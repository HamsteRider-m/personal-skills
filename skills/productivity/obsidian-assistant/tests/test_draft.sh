#!/bin/bash
# Test draft command file

echo "Testing draft command..."

CMD="$SKILL_DIR/commands/draft.md"

assert_file_exists "$CMD" "draft.md exists"

assert_contains "$CMD" "Vault Path Discovery" "references shared Vault Path Discovery"

# Key features per design doc §3.9
assert_contains "$CMD" -i "outline\|大纲" "generates outline"
assert_contains "$CMD" -i "\-\-assist" "supports --assist flag"
assert_contains "$CMD" -i "ask\|search\|搜索\|检索" "reuses search logic from ask"
assert_contains "$CMD" -i "素材\|source\|Source" "presents source materials"
assert_contains "$CMD" -i "写作提示\|writing prompt" "includes writing prompts"
