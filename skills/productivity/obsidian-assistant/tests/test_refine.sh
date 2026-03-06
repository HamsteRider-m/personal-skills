#!/bin/bash
# Test refine command file

echo "Testing refine command..."

CMD="$SKILL_DIR/commands/refine.md"

assert_file_exists "$CMD" "refine.md exists"

assert_contains "$CMD" "Vault Path Discovery" "references shared Vault Path Discovery"

# Key features per design doc §3.6
assert_contains "$CMD" -i "socrat" "uses Socratic method"
assert_contains "$CMD" -i "refined" "upgrades to refined status"
assert_contains "$CMD" -i "Core Idea\|core idea" "references Evergreen template"
assert_contains "$CMD" -i "dialog\|conversation\|对话" "uses conversational interaction"
