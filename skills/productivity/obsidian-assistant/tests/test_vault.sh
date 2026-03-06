#!/bin/bash
echo "Testing vault command..."
CMD="$SKILL_DIR/commands/vault.md"
assert_file_exists "$CMD" "vault.md exists"
assert_contains "$CMD" "vault add" "supports add subcommand"
assert_contains "$CMD" "vault list" "supports list subcommand"
assert_contains "$CMD" "vault default" "supports default subcommand"
assert_contains "$CMD" "vault remove" "supports remove subcommand"
assert_contains "$CMD" "obos-config.json" "references config file"
