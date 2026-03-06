#!/bin/bash
# Prompt Template Selector for Deep Learning
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"

show_help() {
  cat <<EOF
Usage: prompt_selector.sh [OPTIONS]

Select and display NotebookLM chat prompts based on intent.

Options:
  --category CATEGORY    Select prompt category (basic|analysis|practical|creative)
  --intent INTENT        Select by specific intent (summarize|explain|compare|apply|teach|analyze|timeline|misconception|workflow|resources|training|beginner|quiz|analogy)
  --list                 List all available prompts
  --random               Pick a random prompt from all categories
  --help                 Show this help

Examples:
  prompt_selector.sh --category basic --intent summarize
  prompt_selector.sh --intent compare
  prompt_selector.sh --random
EOF
}

list_prompts() {
  echo "📚 Available Prompt Categories:"
  echo ""
  
  for cat_file in "$CONFIG_DIR"/prompts/*.md; do
    [[ -f "$cat_file" ]] || continue
    cat_name=$(basename "$cat_file" .md)
    echo "## $cat_name"
    grep "^### " "$cat_file" | sed 's/^### /  - /'
    echo ""
  done
}

get_prompt_by_intent() {
  local intent="$1"
  
  # Map intent to file and prompt name
  case "$intent" in
    summarize|explain|relate|examples|teach)
      cat_file="$CONFIG_DIR/prompts/basic.md"
      ;;
    analyze|controversy|compare|timeline|future|misconception)
      cat_file="$CONFIG_DIR/prompts/analysis.md"
      ;;
    apply|situation|workflow|resources)
      cat_file="$CONFIG_DIR/prompts/practical.md"
      ;;
    training|beginner|quiz|analogy)
      cat_file="$CONFIG_DIR/prompts/creative.md"
      ;;
    *)
      echo "Unknown intent: $intent" >&2
      return 1
      ;;
  esac
  
  # Extract the specific prompt
  awk -v intent="$intent" '
    /^### / {
      gsub(/^### /, "")
      current = tolower($0)
      gsub(/[^a-z]/, "", current)
      if (index(current, intent) > 0) {
        found = 1
        print
        next
      }
      found = 0
    }
    found && /^>/ { print substr($0, 3); exit }
  ' "$cat_file"
}

get_random_prompt() {
  local all_prompts=()
  
  for cat_file in "$CONFIG_DIR"/prompts/*.md; do
    [[ -f "$cat_file" ]] || continue
    while IFS= read -r line; do
      [[ -n "$line" ]] && all_prompts+=("$line")
    done < <(grep "^> " "$cat_file" | sed 's/^> //')
  done
  
  if [[ ${#all_prompts[@]} -eq 0 ]]; then
    echo "No prompts found" >&2
    return 1
  fi
  
  # Random selection
  local idx=$((RANDOM % ${#all_prompts[@]}))
  echo "${all_prompts[$idx]}"
}

# Main
CATEGORY=""
INTENT=""
LIST=false
RANDOM_PICK=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --category) CATEGORY="$2"; shift 2 ;;
    --intent) INTENT="$2"; shift 2 ;;
    --list) LIST=true; shift ;;
    --random) RANDOM_PICK=true; shift ;;
    --help) show_help; exit 0 ;;
    *) echo "Unknown option: $1"; show_help; exit 1 ;;
  esac
done

if $LIST; then
  list_prompts
elif $RANDOM_PICK; then
  get_random_prompt
elif [[ -n "$INTENT" ]]; then
  get_prompt_by_intent "$INTENT"
elif [[ -n "$CATEGORY" ]]; then
  cat_file="$CONFIG_DIR/prompts/$CATEGORY.md"
  if [[ -f "$cat_file" ]]; then
    cat "$cat_file"
  else
    echo "Category not found: $CATEGORY" >&2
    exit 1
  fi
else
  # Default: show basic summary prompt
  get_prompt_by_intent "summarize"
fi
