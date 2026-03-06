#!/bin/bash
# LLM-based quality grading for Phase 4
set -euo pipefail

OUTPUT_DIR=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --output) OUTPUT_DIR="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

[[ -z "$OUTPUT_DIR" ]] && { echo "Error: --output required"; exit 1; }

echo "🤖 LLM Quality Grading (Phase 4)"

# Check required files
REPORT="$OUTPUT_DIR/report.md"
QUIZ="$OUTPUT_DIR/quiz.md"

if [[ ! -f "$REPORT" ]]; then
  echo "❌ Missing report.md, cannot grade"
  exit 1
fi

# Read report content (first 3000 chars for context)
REPORT_CONTENT=$(head -c 3000 "$REPORT")

# Prepare grading prompt
GRADING_PROMPT="You are evaluating a NotebookLM-generated study guide.

Rate the following aspects (0-8 for accuracy, 0-6 for completeness and coherence):

**Content Accuracy (0-8):**
- Factual correctness
- No hallucinations
- Relevance to topic

**Completeness (0-6):**
- Coverage of major topics
- Adequate explanations
- Comprehensive quiz

**Coherence (0-6):**
- Logical organization
- Clear language
- Consistent flow

Report excerpt:
\`\`\`
$REPORT_CONTENT
\`\`\`

Respond ONLY with JSON:
{
  \"accuracy\": <0-8>,
  \"completeness\": <0-6>,
  \"coherence\": <0-6>,
  \"reasoning\": \"brief explanation\"
}"


# Call LLM (using OpenClaw's default model)
echo "🔄 Calling LLM for grading..."

RESPONSE=$(echo "$GRADING_PROMPT" | openclaw agent send --model anthropic/claude-sonnet-4-6 --json 2>/dev/null || echo '{"accuracy":0,"completeness":0,"coherence":0}')

# Parse scores
ACCURACY=$(echo "$RESPONSE" | jq -r '.accuracy // 0')
COMPLETENESS=$(echo "$RESPONSE" | jq -r '.completeness // 0')
COHERENCE=$(echo "$RESPONSE" | jq -r '.coherence // 0')
REASONING=$(echo "$RESPONSE" | jq -r '.reasoning // "N/A"')

PHASE4=$((ACCURACY + COMPLETENESS + COHERENCE))

echo ""
echo "📊 Quality Scores:"
echo "  Accuracy: $ACCURACY/8"
echo "  Completeness: $COMPLETENESS/6"
echo "  Coherence: $COHERENCE/6"
echo "  Phase 4 Total: $PHASE4/20"
echo ""
echo "💭 Reasoning: $REASONING"

# Update score.json
if [[ -f "$OUTPUT_DIR/score.json" ]]; then
  PREV_SCORES=$(cat "$OUTPUT_DIR/score.json")
  PHASE1=$(echo "$PREV_SCORES" | jq -r '.scores.phase1_collection')
  PHASE2=$(echo "$PREV_SCORES" | jq -r '.scores.phase2_synthesis')
  PHASE3=$(echo "$PREV_SCORES" | jq -r '.scores.phase3_generation')
  
  TOTAL=$((PHASE1 + PHASE2 + PHASE3 + PHASE4))
  PASS="false"
  [[ $TOTAL -ge 70 ]] && PASS="true"
  
  jq ".scores.phase4_quality = $PHASE4 | .scores.total = $TOTAL | .pass = $PASS" \
    "$OUTPUT_DIR/score.json" > "$OUTPUT_DIR/score.json.tmp"
  mv "$OUTPUT_DIR/score.json.tmp" "$OUTPUT_DIR/score.json"
  
  echo ""
  echo "✅ Final Score: $TOTAL/100 (Pass: $PASS)"
  echo "💾 Updated: $OUTPUT_DIR/score.json"
fi
