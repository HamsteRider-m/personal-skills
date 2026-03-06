#!/bin/bash
# Generate all NotebookLM artifacts in parallel (Enhanced Version)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration
source "$SCRIPT_DIR/config_loader.sh" 2>/dev/null || true
load_config

NOTEBOOK_ID=""
OUTPUT_DIR=""
ARTIFACTS_TO_GENERATE="${ARTIFACTS_TO_GENERATE:-report audio slides mindmap quiz}"
ENABLE_VIDEO="${ENABLE_VIDEO:-true}"
ENABLE_INFOGRAPHIC="${ENABLE_INFOGRAPHIC:-false}"
ENABLE_FLASHCARDS="${ENABLE_FLASHCARDS:-true}"

while [[ $# -gt 0 ]]; do
  case $1 in
    --notebook) NOTEBOOK_ID="$2"; shift 2 ;;
    --output) OUTPUT_DIR="$2"; shift 2 ;;
    --artifacts) ARTIFACTS_TO_GENERATE="$2"; shift 2 ;;
    --enable-video) ENABLE_VIDEO="$2"; shift 2 ;;
    --enable-infographic) ENABLE_INFOGRAPHIC="$2"; shift 2 ;;
    --enable-flashcards) ENABLE_FLASHCARDS="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

[[ -z "$NOTEBOOK_ID" ]] && { echo "Error: --notebook required"; exit 1; }
[[ -z "$OUTPUT_DIR" ]] && { echo "Error: --output required"; exit 1; }

echo "🎨 Starting artifact generation..."
echo "   Notebook: $NOTEBOOK_ID"
echo "   Artifacts: $ARTIFACTS_TO_GENERATE"

# Initialize artifact IDs
REPORT_ID=""
AUDIO_ID=""
SLIDE_ID=""
MINDMAP_ID=""
QUIZ_ID=""
VIDEO_ID=""
INFOGRAPHIC_ID=""
FLASHCARDS_ID=""

# Generate requested artifacts
if [[ "$ARTIFACTS_TO_GENERATE" == *"report"* ]]; then
  echo "  📄 Report..."
  REPORT_JSON=$(notebooklm generate report --format study-guide -n "$NOTEBOOK_ID" --json 2>&1 || echo '{}')
  REPORT_ID=$(echo "$REPORT_JSON" | jq -r '.task_id // .id // empty')
fi

if [[ "$ARTIFACTS_TO_GENERATE" == *"audio"* ]]; then
  echo "  🎙️ Podcast..."
  AUDIO_JSON=$(notebooklm generate audio --format deep-dive -n "$NOTEBOOK_ID" --json 2>&1 || echo '{}')
  AUDIO_ID=$(echo "$AUDIO_JSON" | jq -r '.task_id // .id // empty')
fi

if [[ "$ARTIFACTS_TO_GENERATE" == *"slides"* ]]; then
  echo "  📊 Slides..."
  SLIDE_JSON=$(notebooklm generate slide-deck --format detailed -n "$NOTEBOOK_ID" --json 2>&1 || echo '{}')
  SLIDE_ID=$(echo "$SLIDE_JSON" | jq -r '.task_id // .id // empty')
fi

if [[ "$ARTIFACTS_TO_GENERATE" == *"mindmap"* ]]; then
  echo "  🗺️ Mind map..."
  MAP_JSON=$(notebooklm generate mind-map -n "$NOTEBOOK_ID" --json 2>&1 || echo '{}')
  MINDMAP_ID=$(echo "$MAP_JSON" | jq -r '.task_id // .id // empty')
fi

if [[ "$ARTIFACTS_TO_GENERATE" == *"quiz"* ]]; then
  echo "  ❓ Quiz..."
  QUIZ_JSON=$(notebooklm generate quiz --difficulty medium -n "$NOTEBOOK_ID" --json 2>&1 || echo '{}')
  QUIZ_ID=$(echo "$QUIZ_JSON" | jq -r '.task_id // .id // empty')
fi

if [[ "$ENABLE_VIDEO" == "true" && "$ARTIFACTS_TO_GENERATE" == *"video"* ]]; then
  echo "  🎬 Video Brief..."
  VIDEO_JSON=$(notebooklm generate video -n "$NOTEBOOK_ID" --json 2>&1 || echo '{}')
  VIDEO_ID=$(echo "$VIDEO_JSON" | jq -r '.task_id // .id // empty')
  [[ -n "$VIDEO_ID" && "$VIDEO_ID" != "null" ]] && echo "  ✅ Video generation started"
fi

if [[ "$ENABLE_INFOGRAPHIC" == "true" && "$ARTIFACTS_TO_GENERATE" == *"infographic"* ]]; then
  echo "  📊 Infographic..."
  INFOGRAPHIC_JSON=$(notebooklm generate infographic -n "$NOTEBOOK_ID" --json 2>&1 || echo '{}')
  INFOGRAPHIC_ID=$(echo "$INFOGRAPHIC_JSON" | jq -r '.task_id // .id // empty')
  [[ -n "$INFOGRAPHIC_ID" && "$INFOGRAPHIC_ID" != "null" ]] && echo "  ✅ Infographic generation started"
fi

if [[ "$ENABLE_FLASHCARDS" == "true" && "$ARTIFACTS_TO_GENERATE" == *"flashcards"* ]]; then
  echo "  🃏 Flashcards..."
  FLASHCARDS_JSON=$(notebooklm generate flashcards -n "$NOTEBOOK_ID" --json 2>&1 || echo '{}')
  FLASHCARDS_ID=$(echo "$FLASHCARDS_JSON" | jq -r '.task_id // .id // empty')
  [[ -n "$FLASHCARDS_ID" && "$FLASHCARDS_ID" != "null" ]] && echo "  ✅ Flashcards generation started"
fi

# Save artifact IDs
cat > "$OUTPUT_DIR/artifacts.json" <<EOF
{
  "report": "$REPORT_ID",
  "audio": "$AUDIO_ID",
  "slides": "$SLIDE_ID",
  "mindmap": "$MINDMAP_ID",
  "quiz": "$QUIZ_ID",
  "video": "$VIDEO_ID",
  "infographic": "$INFOGRAPHIC_ID",
  "flashcards": "$FLASHCARDS_ID"
}
EOF

echo "✅ Generation started. Artifact IDs saved to artifacts.json"
echo "⏳ Use subagents to wait and download each artifact"
