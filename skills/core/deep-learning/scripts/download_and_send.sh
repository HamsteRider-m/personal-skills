#!/bin/bash
# Download artifacts and send via Feishu
set -euo pipefail

NOTEBOOK_ID=""
OUTPUT_DIR=""
ARTIFACT_ID=""
ARTIFACT_TYPE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --notebook) NOTEBOOK_ID="$2"; shift 2 ;;
    --output) OUTPUT_DIR="$2"; shift 2 ;;
    --artifact) ARTIFACT_ID="$2"; shift 2 ;;
    --type) ARTIFACT_TYPE="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

[[ -z "$NOTEBOOK_ID" ]] && { echo "Error: --notebook required"; exit 1; }
[[ -z "$OUTPUT_DIR" ]] && { echo "Error: --output required"; exit 1; }
[[ -z "$ARTIFACT_ID" ]] && { echo "Error: --artifact required"; exit 1; }
[[ -z "$ARTIFACT_TYPE" ]] && { echo "Error: --type required"; exit 1; }

echo "⬇️  Downloading $ARTIFACT_TYPE artifact..."

cd "$OUTPUT_DIR"

case "$ARTIFACT_TYPE" in
  audio)
    notebooklm download audio ./podcast.mp3 -a "$ARTIFACT_ID" -n "$NOTEBOOK_ID"
    echo "✅ Downloaded: podcast.mp3"
    ;;
  slides)
    notebooklm download slide-deck ./slides.pdf -a "$ARTIFACT_ID" -n "$NOTEBOOK_ID"
    echo "✅ Downloaded: slides.pdf"
    ;;
  report)
    notebooklm download report ./report.md -a "$ARTIFACT_ID" -n "$NOTEBOOK_ID"
    echo "✅ Downloaded: report.md"
    ;;
  mindmap)
    notebooklm download mind-map ./mindmap.json -a "$ARTIFACT_ID" -n "$NOTEBOOK_ID"
    echo "✅ Downloaded: mindmap.json"
    ;;
  quiz)
    notebooklm download quiz ./quiz.json -a "$ARTIFACT_ID" -n "$NOTEBOOK_ID"
    notebooklm download quiz --format markdown ./quiz.md -a "$ARTIFACT_ID" -n "$NOTEBOOK_ID"
    echo "✅ Downloaded: quiz.json, quiz.md"
    ;;
  *)
    echo "❌ Unknown artifact type: $ARTIFACT_TYPE"
    exit 1
    ;;
esac

echo "📦 Artifact ready: $OUTPUT_DIR"
