#!/bin/bash
# Run 5 trials for a test case
set -euo pipefail

TEST_CASE=""
TOPIC=""
MATERIALS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --test-case) TEST_CASE="$2"; shift 2 ;;
    --topic) TOPIC="$2"; shift 2 ;;
    --material) MATERIALS+=("$2"); shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

[[ -z "$TEST_CASE" ]] && { echo "Error: --test-case required"; exit 1; }
[[ -z "$TOPIC" ]] && { echo "Error: --topic required"; exit 1; }

EVAL_DIR="$HOME/.openclaw/workspace/skills/deep-learning/eval"
RESULTS_DIR="$EVAL_DIR/results/$TEST_CASE"
mkdir -p "$RESULTS_DIR"

echo "🧪 Running 5 trials for: $TEST_CASE"
echo "📝 Topic: $TOPIC"
echo "📦 Materials: ${#MATERIALS[@]}"
echo ""

PASSES=0
TOTAL_SCORE=0

for i in {1..5}; do
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔬 Trial $i/5"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Build material args
  MATERIAL_ARGS=""
  for mat in "${MATERIALS[@]}"; do
    MATERIAL_ARGS="$MATERIAL_ARGS --material \"$mat\""
  done
  
  # Run orchestration
  eval bash ~/.openclaw/workspace/skills/deep-learning/scripts/orchestrate.sh \
    --topic \"$TOPIC\" $MATERIAL_ARGS
  
  # Get output directory (last created)
  OUTPUT_DIR=$(ls -td ~/.openclaw/workspace/deep-learning-output/*/ | head -1)
  
  # Score trial
  bash "$EVAL_DIR/scripts/score_trial.sh" \
    --output "$OUTPUT_DIR" \
    --test-case "$TEST_CASE" \
    --trial "$i"
  
  # LLM grade
  bash "$EVAL_DIR/scripts/llm_grade.sh" --output "$OUTPUT_DIR"
  
  # Copy results
  cp "$OUTPUT_DIR/score.json" "$RESULTS_DIR/trial-$i.json"
  
  # Update stats
  SCORE=$(jq -r '.scores.total' "$RESULTS_DIR/trial-$i.json")
  PASS=$(jq -r '.pass' "$RESULTS_DIR/trial-$i.json")
  
  TOTAL_SCORE=$((TOTAL_SCORE + SCORE))
  [[ "$PASS" == "true" ]] && PASSES=$((PASSES + 1))
  
  echo ""
  echo "Trial $i: $SCORE/100 (Pass: $PASS)"
  echo ""
done


# Generate aggregate report
AVG_SCORE=$((TOTAL_SCORE / 5))
PASS_RATE=$(echo "scale=2; $PASSES / 5" | bc)

VERDICT="FAIL"
[[ $(echo "$PASS_RATE >= 0.8" | bc) -eq 1 ]] && VERDICT="PASS"

cat > "$RESULTS_DIR/aggregate.json" <<AGG
{
  "test_case": "$TEST_CASE",
  "trials": 5,
  "passes": $PASSES,
  "pass_rate": $PASS_RATE,
  "avg_score": $AVG_SCORE,
  "verdict": "$VERDICT"
}
AGG

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Final Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Case: $TEST_CASE"
echo "Passes: $PASSES/5"
echo "Pass Rate: $PASS_RATE"
echo "Avg Score: $AVG_SCORE/100"
echo "Verdict: $VERDICT"
echo ""
echo "📂 Results: $RESULTS_DIR"
