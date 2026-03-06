#!/bin/bash
# Deep Learning Orchestrator - Enhanced Version
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_BASE="$HOME/.openclaw/workspace/deep-learning-output"

# Load configuration
source "$SCRIPT_DIR/config_loader.sh"
load_config

# Parse arguments
TOPIC=""
MATERIALS=()
MODE="full"  # full|collect-only|generate-only
RESEARCH_MODE="${DEFAULT_RESEARCH_MODE:-deep}"
ARTIFACTS="${DEFAULT_ARTIFACTS:-report audio slides mindmap quiz}"
PROMPT_CATEGORY=""
DELIVERY_MODE="${DEFAULT_DELIVERY_MODE:-progressive}"  # progressive|batch

while [[ $# -gt 0 ]]; do
  case $1 in
    --topic) TOPIC="$2"; shift 2 ;;
    --material|--materials) MATERIALS+=("$2"); shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --research-mode) RESEARCH_MODE="$2"; shift 2 ;;
    --artifacts) ARTIFACTS="$2"; shift 2 ;;
    --prompt-category) PROMPT_CATEGORY="$2"; shift 2 ;;
    --delivery-mode) DELIVERY_MODE="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -z "$TOPIC" ]]; then
  echo "Error: --topic required"
  exit 1
fi

echo "🚀 Starting enhanced deep learning workflow: $TOPIC"
echo "📦 Materials: ${#MATERIALS[@]}"
echo "🔧 Mode: $MODE"
echo "🔬 Research Mode: $RESEARCH_MODE"
echo "🎨 Artifacts: $ARTIFACTS"
echo ""

# Create notebook
echo "📚 Creating NotebookLM notebook..."
NOTEBOOK_JSON=$(notebooklm create "深度学习：$TOPIC" --json)
NOTEBOOK_ID=$(echo "$NOTEBOOK_JSON" | jq -r '.notebook.id')

if [[ -z "$NOTEBOOK_ID" || "$NOTEBOOK_ID" == "null" ]]; then
  echo "❌ Failed to create notebook"
  exit 1
fi

echo "✅ Notebook created: $NOTEBOOK_ID"
echo "🔗 https://notebooklm.google.com/notebook/$NOTEBOOK_ID"
echo ""

# Create output directory
OUTPUT_DIR="$OUTPUT_BASE/$NOTEBOOK_ID"
mkdir -p "$OUTPUT_DIR"

# Save metadata
cat > "$OUTPUT_DIR/metadata.json" <<EOF
{
  "topic": "$TOPIC",
  "notebook_id": "$NOTEBOOK_ID",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "materials_count": ${#MATERIALS[@]},
  "research_mode": "$RESEARCH_MODE",
  "artifacts": "$ARTIFACTS"
}
EOF

# Phase 1: Collect materials
if [[ "$MODE" == "full" || "$MODE" == "collect-only" ]]; then
  echo "📥 Collecting materials..."
  SOURCE_IDS=()
  
  # Check if no materials provided (Deep Research mode)
  if [[ ${#MATERIALS[@]} -eq 0 ]]; then
    echo "  🔬 No materials provided, activating research mode: $RESEARCH_MODE"
    echo "  🔍 Searching for sources on: $TOPIC"
    
    if [[ "$RESEARCH_MODE" == "fast" ]]; then
      # Fast Research: 10-20 seconds
      echo "  ⚡ Fast Research mode (10-20 seconds)"
      notebooklm source add-research "$TOPIC" -n "$NOTEBOOK_ID" --mode fast --no-wait 2>&1 | tee -a "$OUTPUT_DIR/research.log"
      echo "  ⏳ Waiting for fast research to complete..."
      notebooklm research wait -n "$NOTEBOOK_ID" --import-all --timeout 60 2>&1 | tee -a "$OUTPUT_DIR/research.log"
    else
      # Deep Research: 2-30 minutes
      echo "  🧠 Deep Research mode (2-30 minutes)"
      notebooklm source add-research "$TOPIC" -n "$NOTEBOOK_ID" --mode deep --no-wait 2>&1 | tee -a "$OUTPUT_DIR/research.log"
      echo "  ⏳ Waiting for deep research to complete (this may take a while)..."
      notebooklm research wait -n "$NOTEBOOK_ID" --import-all --timeout 1800 2>&1 | tee -a "$OUTPUT_DIR/research.log"
    fi
    
    echo "  ✅ Research completed"
    echo "0" > "$OUTPUT_DIR/source_ids.txt"
  else
    # Process provided materials
    for material in "${MATERIALS[@]}"; do
      echo "  Processing: $material"
      
      # Detect if material needs preprocessing with jina-reader
      NEEDS_JINA=false
      if [[ "$material" =~ ^https?://(x\.com|twitter\.com|reddit\.com|medium\.com|linkedin\.com)/ ]]; then
        NEEDS_JINA=true
        echo "  🔄 Social media link detected, using jina-reader..."
      fi
      
      if [[ "$NEEDS_JINA" == "true" ]]; then
        # Use jina-reader to extract content
        MARKDOWN=$(curl -s "https://r.jina.ai/$material" || echo "")
        if [[ -n "$MARKDOWN" ]]; then
          TITLE=$(echo "$MARKDOWN" | head -1 | sed 's/^# //')
          # Add as text source
          SOURCE_JSON=$(notebooklm source add "$MARKDOWN" --type text --title "$TITLE" -n "$NOTEBOOK_ID" --json 2>&1 || echo '{"error": true}')
        else
          echo "  ⚠️  jina-reader failed, trying direct add..."
          SOURCE_JSON=$(notebooklm source add "$material" --json -n "$NOTEBOOK_ID" 2>&1 || echo '{"error": true}')
        fi
      else
        # Add directly
        SOURCE_JSON=$(notebooklm source add "$material" --json -n "$NOTEBOOK_ID" 2>&1 || echo '{"error": true}')
      fi
      
      if echo "$SOURCE_JSON" | jq -e '.error' > /dev/null 2>&1; then
        echo "  ⚠️  Failed to add source, continuing..."
        continue
      fi
      
      SOURCE_ID=$(echo "$SOURCE_JSON" | jq -r '.source.id // .id')
      if [[ -n "$SOURCE_ID" && "$SOURCE_ID" != "null" ]]; then
        SOURCE_IDS+=("$SOURCE_ID")
        echo "  ✅ Added: $SOURCE_ID"
      fi
    done
  fi
  
  echo ""
  echo "✅ Collected ${#SOURCE_IDS[@]} sources"
  
  if [[ ${#SOURCE_IDS[@]} -eq 0 ]]; then
    echo "❌ No sources collected, exiting"
    exit 1
  fi
  
  echo "${SOURCE_IDS[@]}" > "$OUTPUT_DIR/source_ids.txt"
fi

# Phase 2: Generate artifacts
if [[ "$MODE" == "full" || "$MODE" == "generate-only" ]]; then
  echo ""
  echo "🎨 Generating artifacts..."
  
  bash "$SCRIPT_DIR/generate_artifacts.sh" \
    --notebook "$NOTEBOOK_ID" \
    --output "$OUTPUT_DIR" \
    --artifacts "$ARTIFACTS" \
    --enable-video "${ENABLE_VIDEO:-true}" \
    --enable-infographic "${ENABLE_INFOGRAPHIC:-false}" \
    --enable-flashcards "${ENABLE_FLASHCARDS:-true}"
  
  # Wait and download artifacts
  echo ""
  echo "⏳ Waiting for artifacts to complete..."
  
  cd "$OUTPUT_DIR"
  
  # Load artifact IDs
  [[ -f artifacts.json ]] || { echo "❌ artifacts.json not found"; exit 1; }
  
  REPORT_ID=$(jq -r '.report // empty' artifacts.json)
  AUDIO_ID=$(jq -r '.audio // empty' artifacts.json)
  SLIDES_ID=$(jq -r '.slides // empty' artifacts.json)
  QUIZ_ID=$(jq -r '.quiz // empty' artifacts.json)
  VIDEO_ID=$(jq -r '.video // empty' artifacts.json)
  INFOGRAPHIC_ID=$(jq -r '.infographic // empty' artifacts.json)
  FLASHCARDS_ID=$(jq -r '.flashcards // empty' artifacts.json)
  
  # Wait up to 10 minutes for artifacts
  for i in {1..60}; do
    sleep 10
    COMPLETED=0
    TOTAL=0
    
    [[ -n "$REPORT_ID" && "$REPORT_ID" != "null" ]] && TOTAL=$((TOTAL+1))
    [[ -n "$AUDIO_ID" && "$AUDIO_ID" != "null" ]] && TOTAL=$((TOTAL+1))
    [[ -n "$SLIDES_ID" && "$SLIDES_ID" != "null" ]] && TOTAL=$((TOTAL+1))
    [[ -n "$QUIZ_ID" && "$QUIZ_ID" != "null" ]] && TOTAL=$((TOTAL+1))
    [[ -n "$VIDEO_ID" && "$VIDEO_ID" != "null" ]] && TOTAL=$((TOTAL+1))
    [[ -n "$INFOGRAPHIC_ID" && "$INFOGRAPHIC_ID" != "null" ]] && TOTAL=$((TOTAL+1))
    [[ -n "$FLASHCARDS_ID" && "$FLASHCARDS_ID" != "null" ]] && TOTAL=$((TOTAL+1))
    
    # Try downloading
    [[ -n "$REPORT_ID" ]] && notebooklm download report ./report.md -a "$REPORT_ID" -n "$NOTEBOOK_ID" 2>/dev/null && COMPLETED=$((COMPLETED+1))
    [[ -n "$AUDIO_ID" ]] && notebooklm download audio ./podcast.mp3 -a "$AUDIO_ID" -n "$NOTEBOOK_ID" 2>/dev/null && COMPLETED=$((COMPLETED+1))
    [[ -n "$SLIDES_ID" ]] && notebooklm download slide-deck ./slides.pdf -a "$SLIDES_ID" -n "$NOTEBOOK_ID" 2>/dev/null && COMPLETED=$((COMPLETED+1))
    [[ -n "$QUIZ_ID" ]] && notebooklm download quiz ./quiz.json -a "$QUIZ_ID" -n "$NOTEBOOK_ID" 2>/dev/null && COMPLETED=$((COMPLETED+1))
    [[ -n "$VIDEO_ID" ]] && notebooklm download video ./video.mp4 -a "$VIDEO_ID" -n "$NOTEBOOK_ID" 2>/dev/null && COMPLETED=$((COMPLETED+1))
    [[ -n "$INFOGRAPHIC_ID" ]] && notebooklm download infographic ./infographic.png -a "$INFOGRAPHIC_ID" -n "$NOTEBOOK_ID" 2>/dev/null && COMPLETED=$((COMPLETED+1))
    [[ -n "$FLASHCARDS_ID" ]] && notebooklm download flashcards ./flashcards.json -a "$FLASHCARDS_ID" -n "$NOTEBOOK_ID" 2>/dev/null && COMPLETED=$((COMPLETED+1))
    
    [[ $COMPLETED -gt 0 ]] && echo "  Progress: $COMPLETED/$TOTAL artifacts ready"
    [[ $COMPLETED -eq $TOTAL && $TOTAL -gt 0 ]] && break
  done
  
  echo "  ✅ Downloaded $COMPLETED/$TOTAL artifacts"
fi

echo ""
echo "✅ Workflow complete!"
echo "📂 Output: $OUTPUT_DIR"

# Phase 3: Save to Obsidian & Send summary to Feishu
if [[ "$ENABLE_OBSIDIAN_INTEGRATION" == "true" ]]; then
  if [[ -f "$OUTPUT_DIR/report.md" ]] || [[ -f "$OUTPUT_DIR/slides.pdf" ]]; then
    echo ""
    echo "💾 Saving to Obsidian Inbox..."
    
    OBSIDIAN_INBOX="${OBSIDIAN_INBOX_PATH:-$HOME/Library/CloudStorage/OneDrive-个人/obsidian-vault/Inbox}"
    mkdir -p "$OBSIDIAN_INBOX"
    
    TIMESTAMP=$(date +"%Y-%m-%d")
    SAFE_TOPIC=$(echo "$TOPIC" | tr ' ' '-' | tr -cd '[:alnum:]-')
    INBOX_FILE="$OBSIDIAN_INBOX/${TIMESTAMP}__notebooklm__${SAFE_TOPIC}.md"
    
    # Create inbox entry
    cat > "$INBOX_FILE" <<EOF
# $TOPIC

> 学习时间：$TIMESTAMP
> NotebookLM：https://notebooklm.google.com/notebook/$NOTEBOOK_ID
> Research Mode: $RESEARCH_MODE

## 学习材料

EOF
    
    # Append report content
    [[ -f "$OUTPUT_DIR/report.md" ]] && cat "$OUTPUT_DIR/report.md" >> "$INBOX_FILE"
    
    # Copy attachments
    [[ -f "$OUTPUT_DIR/slides.pdf" ]] && cp "$OUTPUT_DIR/slides.pdf" "$OBSIDIAN_INBOX/"
    [[ -f "$OUTPUT_DIR/podcast.mp3" ]] && cp "$OUTPUT_DIR/podcast.mp3" "$OBSIDIAN_INBOX/"
    [[ -f "$OUTPUT_DIR/quiz.json" ]] && cp "$OUTPUT_DIR/quiz.json" "$OBSIDIAN_INBOX/"
    [[ -f "$OUTPUT_DIR/video.mp4" ]] && cp "$OUTPUT_DIR/video.mp4" "$OBSIDIAN_INBOX/"
    [[ -f "$OUTPUT_DIR/infographic.png" ]] && cp "$OUTPUT_DIR/infographic.png" "$OBSIDIAN_INBOX/"
    
    echo "  ✅ Saved to: $INBOX_FILE"
  fi
fi

# Send summary to Feishu
echo ""
echo "📤 Sending summary to Feishu..."

SUMMARY="📚 深度学习完成：$TOPIC

✅ 已保存到 Obsidian Inbox
📂 Research Mode: $RESEARCH_MODE

产物：
$([ -f "$OUTPUT_DIR/report.md" ] && echo "📄 学习报告")
$([ -f "$OUTPUT_DIR/slides.pdf" ] && echo "📊 PPT 讲义")
$([ -f "$OUTPUT_DIR/podcast.mp3" ] && echo "🎙️ 音频播客")
$([ -f "$OUTPUT_DIR/quiz.json" ] && echo "❓ 测试题")
$([ -f "$OUTPUT_DIR/video.mp4" ] && echo "🎬 视频解说")
$([ -f "$OUTPUT_DIR/infographic.png" ] && echo "📊 信息图")
$([ -f "$OUTPUT_DIR/flashcards.json" ] && echo "🃏 闪卡")

🔗 NotebookLM: https://notebooklm.google.com/notebook/$NOTEBOOK_ID"

message action=send channel=feishu target=current message="$SUMMARY" 2>/dev/null || echo "  ⚠️  Failed to send to Feishu"
echo "  ✅ Summary sent"
