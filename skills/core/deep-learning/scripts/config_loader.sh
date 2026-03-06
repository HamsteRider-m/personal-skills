#!/bin/bash
# Config loader for deep-learning skill
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"

# Default values
DEEP_LEARNING_CONFIG_OBSIDIAN_PATH="${DEEP_LEARNING_CONFIG_OBSIDIAN_PATH:-$HOME/Library/CloudStorage/OneDrive-个人/obsidian-vault/Inbox}"
DEEP_LEARNING_CONFIG_ENABLE_OBSIDIAN="${DEEP_LEARNING_CONFIG_ENABLE_OBSIDIAN:-true}"
DEEP_LEARNING_CONFIG_DEFAULT_RESEARCH_MODE="${DEEP_LEARNING_CONFIG_DEFAULT_RESEARCH_MODE:-deep}"
DEEP_LEARNING_CONFIG_ARTIFACT_TIMEOUT="${DEEP_LEARNING_CONFIG_ARTIFACT_TIMEOUT:-1800}"
DEEP_LEARNING_CONFIG_ENABLE_VIDEO="${DEEP_LEARNING_CONFIG_ENABLE_VIDEO:-true}"
DEEP_LEARNING_CONFIG_ENABLE_INFOGRAPHIC="${DEEP_LEARNING_CONFIG_ENABLE_INFOGRAPHIC:-false}"
DEEP_LEARNING_CONFIG_ENABLE_FLASHCARDS="${DEEP_LEARNING_CONFIG_ENABLE_FLASHCARDS:-true}"

load_config() {
    local config_file="${CONFIG_DIR}/default.conf"
    
    if [[ -f "$config_file" ]]; then
        # Source the config file
        source "$config_file"
    fi
    
    # Environment variables override config file
    OBSIDIAN_INBOX_PATH="${OBSIDIAN_INBOX_PATH:-$DEEP_LEARNING_CONFIG_OBSIDIAN_PATH}"
    ENABLE_OBSIDIAN="${ENABLE_OBSIDIAN:-$DEEP_LEARNING_CONFIG_ENABLE_OBSIDIAN}"
    DEFAULT_RESEARCH_MODE="${DEFAULT_RESEARCH_MODE:-$DEEP_LEARNING_CONFIG_DEFAULT_RESEARCH_MODE}"
    ARTIFACT_TIMEOUT="${ARTIFACT_TIMEOUT:-$DEEP_LEARNING_CONFIG_ARTIFACT_TIMEOUT}"
    ENABLE_VIDEO="${ENABLE_VIDEO:-$DEEP_LEARNING_CONFIG_ENABLE_VIDEO}"
    ENABLE_INFOGRAPHIC="${ENABLE_INFOGRAPHIC:-$DEEP_LEARNING_CONFIG_ENABLE_INFOGRAPHIC}"
    ENABLE_FLASHCARDS="${ENABLE_FLASHCARDS:-$DEEP_LEARNING_CONFIG_ENABLE_FLASHCARDS}"
}

get_prompt_template() {
    local category="$1"
    local template_file="${CONFIG_DIR}/prompts/${category}.md"
    
    if [[ -f "$template_file" ]]; then
        cat "$template_file"
    else
        echo "# Default Prompt\n\n请总结这个主题的要点，并提供深入的分析。"
    fi
}

list_prompt_categories() {
    ls -1 "${CONFIG_DIR}/prompts/" 2>/dev/null | sed 's/\.md$//' || echo "basic"
}

export -f load_config get_prompt_template list_prompt_categories
