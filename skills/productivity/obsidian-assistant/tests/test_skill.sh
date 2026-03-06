#!/bin/bash
# Test SKILL.md structure and constraints

echo "Testing SKILL.md..."

SKILL="$SKILL_DIR/SKILL.md"

assert_file_exists "$SKILL" "SKILL.md exists"
assert_contains "$SKILL" "^name: obos" "has name in frontmatter"
assert_contains "$SKILL" "^description:" "has description in frontmatter"
assert_contains "$SKILL" "/obos save" "command table: save"
assert_contains "$SKILL" "/obos tidy" "command table: tidy"
assert_contains "$SKILL" "/obos sync" "command table: sync"
assert_contains "$SKILL" "/obos review" "command table: review"
assert_contains "$SKILL" "/obos init" "command table: init"
assert_contains "$SKILL" "/obos vault" "command table: vault"
assert_contains "$SKILL" "/obos refine" "command table: refine"
assert_contains "$SKILL" "/obos ask" "command table: ask"
assert_contains "$SKILL" "/obos draft" "command table: draft"
assert_contains "$SKILL" "Vault Path Discovery" "has Vault Path Discovery section"
assert_contains "$SKILL" "Knowledge Maturity Model" "has maturity model"
assert_contains "$SKILL" "Evergreen Note Template" "has Evergreen template"
assert_contains "$SKILL" "Command Routing" "has routing section"
assert_contains "$SKILL" "Multi-Vault" "has Multi-Vault config section"
assert_contains "$SKILL" "obos-config.json" "references config file"
assert_contains "$SKILL" "Inbox/" "vault structure includes Inbox"
