#!/bin/bash
# Score a single trial based on output directory
set -euo pipefail

OUTPUT_DIR=""
TEST_CASE=""
TRIAL=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --output) OUTPUT_DIR="$2"; shift 2 ;;
    --test-case) TEST_CASE="$2"; shift 2 ;;
    --trial) TRIAL="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

[[ -z "$OUTPUT_DIR" ]] && { echo "Error: --output required"; exit 1; }
[[ -z "$TEST_CASE" ]] && { echo "Error: --test-case required"; exit 1; }
[[ -z "$TRIAL" ]] && { echo "Error: --trial required"; exit 1; }

echo "📊 Scoring trial: $TEST_CASE (trial $TRIAL)"

# Initialize scores
PHASE1=0
PHASE2=0
PHASE3=0

# Phase 1: Material Collection (20 points)
if [[ -f "$OUTPUT_DIR/source_ids.txt" ]]; then
  SOURCE_COUNT=$(wc -w < "$OUTPUT_DIR/source_ids.txt")
  if [[ $SOURCE_COUNT -gt 0 ]]; then
    PHASE1=$((PHASE1 + 15))  # Upload success + processing
    echo "  ✅ Phase 1: Sources uploaded ($SOURCE_COUNT)"
  fi
fi

# Phase 2: Knowledge Synthesis (20 points)
if [[ -f "$OUTPUT_DIR/metadata.json" ]]; then
  NOTEBOOK_ID=$(jq -r '.notebook_id' "$OUTPUT_DIR/metadata.json")
  if [[ -n "$NOTEBOOK_ID" && "$NOTEBOOK_ID" != "null" ]]; then
    PHASE2=$((PHASE2 + 15))  # Notebook creation + indexing
    echo "  ✅ Phase 2: Notebook created ($NOTEBOOK_ID)"
  fi
fi

# Phase 3: Artifact Generation (40 points)
ARTIFACTS=("podcast.mp3" "slides.pdf" "report.md" "mindmap.json" "quiz.json")
ARTIFACT_SCORES=(10 10 10 5 5)
ARTIFACT_COUNT=0

for i in "${!ARTIFACTS[@]}"; do
  if [[ -f "$OUTPUT_DIR/${ARTIFACTS[$i]}" ]]; then
    PHASE3=$((PHASE3 + ${ARTIFACT_SCORES[$i]}))
    ARTIFACT_COUNT=$((ARTIFACT_COUNT + 1))
    echo "  ✅ Artifact: ${ARTIFACTS[$i]}"
  else
    echo "  ❌ Missing: ${ARTIFACTS[$i]}"
  fi
done

# Calculate subtotal (before quality assessment)
SUBTOTAL=$((PHASE1 + PHASE2 + PHASE3))

echo ""
echo "📈 Scores (before quality assessment):"
echo "  Phase 1 (Collection): $PHASE1/20"
echo "  Phase 2 (Synthesis): $PHASE2/20"
echo "  Phase 3 (Generation): $PHASE3/40"
echo "  Subtotal: $SUBTOTAL/80"
echo ""
echo "⏳ Phase 4 (Quality) requires LLM grading..."
echo "   Run: llm_grade.sh --output $OUTPUT_DIR"

# Save preliminary results
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
cat > "$OUTPUT_DIR/score.json" <<SCORE
{
  "test_case": "$TEST_CASE",
  "trial": $TRIAL,
  "timestamp": "$TIMESTAMP",
  "scores": {
    "phase1_collection": $PHASE1,
    "phase2_synthesis": $PHASE2,
    "phase3_generation": $PHASE3,
    "phase4_quality": null,
    "total": null
  },
  "artifacts_generated": $ARTIFACT_COUNT,
  "pass": null
}
SCORE

echo "💾 Saved to: $OUTPUT_DIR/score.json"
