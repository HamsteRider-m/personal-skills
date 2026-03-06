#!/bin/bash
# Progressive Delivery Orchestrator
# 实现产物逐步交付，不等待全部完成

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_BASE="$HOME/.openclaw/workspace/deep-learning-output"

# 加载配置
source "$SKILL_DIR/scripts/config_loader.sh" 2>/dev/null || true
load_config

NOTEBOOK_ID=""
TOPIC=""
OUTPUT_DIR=""
FEISHU_TARGET="current"

# 解析参数
while [[ $# -gt 0 ]]; do
  case $1 in
    --notebook) NOTEBOOK_ID="$2"; shift 2 ;;
    --topic) TOPIC="$2"; shift 2 ;;
    --output) OUTPUT_DIR="$2"; shift 2 ;;
    --feishu-target) FEISHU_TARGET="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

[[ -z "$NOTEBOOK_ID" ]] && { echo "Error: --notebook required"; exit 1; }
[[ -z "$TOPIC" ]] && { echo "Error: --topic required"; exit 1; }
[[ -z "$OUTPUT_DIR" ]] && { echo "Error: --output required"; exit 1; }

echo "🚀 Starting progressive delivery for: $TOPIC"
echo "   Notebook: $NOTEBOOK_ID"
echo ""

# 产物优先级队列（按交付速度排序）
ARTIFACT_QUEUE=(
  "mindmap:instant:🗺️ 思维导图"
  "report:fast:📄 学习报告"
  "quiz:medium:❓ 测试题"
  "audio:slow:🎙️ 深度播客"
  "slides:slow:📊 PPT讲义"
  "video:slow:🎬 视频解说"
)

# 跟踪已交付产物
declare -A DELIVERED
declare -A ARTIFACT_IDS

# 生成并等待单个产物
generate_and_wait() {
  local artifact_type=$1
  local timeout=$2
  
  echo "  🎨 Generating $artifact_type..."
  
  local generate_json
  case $artifact_type in
    mindmap)
      generate_json=$(notebooklm generate mind-map -n "$NOTEBOOK_ID" --json 2>&1 || echo '{}')
      ;;
    report)
      generate_json=$(notebooklm generate report --format study-guide -n "$NOTEBOOK_ID" --json 2>&1 || echo '{}')
      ;;
    quiz)
      generate_json=$(notebooklm generate quiz --difficulty medium -n "$NOTEBOOK_ID" --json 2>&1 || echo '{}')
      ;;
    audio)
      generate_json=$(notebooklm generate audio --format deep-dive -n "$NOTEBOOK_ID" --json 2>&1 || echo '{}')
      ;;
    slides)
      generate_json=$(notebooklm generate slide-deck --format detailed -n "$NOTEBOOK_ID" --json 2>&1 || echo '{}')
      ;;
    video)
      generate_json=$(notebooklm generate video -n "$NOTEBOOK_ID" --json 2>&1 || echo '{}')
      ;;
  esac
  
  local artifact_id=$(echo "$generate_json" | jq -r '.task_id // .id // empty')
  [[ -z "$artifact_id" ]] && return 1
  
  ARTIFACT_IDS[$artifact_type]=$artifact_id
  
  # 等待完成
  local waited=0
  local interval=10
  local max_wait=$timeout
  
  while [[ $waited -lt $max_wait ]]; do
    sleep $interval
    waited=$((waited + interval))
    
    # 尝试下载
    local download_result=1
    cd "$OUTPUT_DIR"
    
    case $artifact_type in
      mindmap)
        notebooklm download mind-map ./mindmap.json -a "$artifact_id" -n "$NOTEBOOK_ID" 2>/dev/null && download_result=0
        ;;
      report)
        notebooklm download report ./report.md -a "$artifact_id" -n "$NOTEBOOK_ID" 2>/dev/null && download_result=0
        ;;
      quiz)
        notebooklm download quiz ./quiz.json -a "$artifact_id" -n "$NOTEBOOK_ID" 2>/dev/null && download_result=0
        ;;
      audio)
        notebooklm download audio ./podcast.mp3 -a "$artifact_id" -n "$NOTEBOOK_ID" 2>/dev/null && download_result=0
        ;;
      slides)
        notebooklm download slide-deck ./slides.pdf -a "$artifact_id" -n "$NOTEBOOK_ID" 2>/dev/null && download_result=0
        ;;
      video)
        notebooklm download video ./video.mp4 -a "$artifact_id" -n "$NOTEBOOK_ID" 2>/dev/null && download_result=0
        ;;
    esac
    
    if [[ $download_result -eq 0 ]]; then
      echo "  ✅ $artifact_type ready (${waited}s)"
      return 0
    fi
  done
  
  echo "  ⚠️  $artifact_type timeout after ${max_wait}s"
  return 1
}

# 提取 Key Takeaways
extract_key_takeaways() {
  local artifact_file=$1
  local artifact_type=$2
  
  case $artifact_type in
    report)
      # 从报告中提取前3个要点
      if [[ -f "$artifact_file" ]]; then
        head -50 "$artifact_file" | grep -E "^#{1,3} " | head -3 | sed 's/^#* //' | while read line; do
          echo "• $line"
        done
      fi
      ;;
    mindmap)
      # 提取思维导图核心节点
      if [[ -f "$artifact_file" ]]; then
        jq -r '.nodes[0:3].text // empty' "$artifact_file" 2>/dev/null | while read line; do
          [[ -n "$line" ]] && echo "• $line"
        done
      fi
      ;;
    quiz)
      # 提取测试题主题
      if [[ -f "$artifact_file" ]]; then
        jq -r '.questions[0].question // empty' "$artifact_file" 2>/dev/null | head -1
      fi
      ;;
    *)
      echo "• 新鲜出炉，立即查看！"
      ;;
  esac
}

# 发送渐进交付通知
send_progressive_notification() {
  local artifact_type=$1
  local emoji=$2
  local artifact_file=$3
  
  # 提取关键信息
  local takeaways=$(extract_key_takeaways "$artifact_file" "$artifact_type")
  local file_size=""
  [[ -f "$artifact_file" ]] && file_size=$(du -h "$artifact_file" | cut -f1)
  
  # 构建消息
  local message="${emoji} ${TOPIC} - 新产物就绪！

Key Takeaways:
${takeaways:-• 新鲜出炉，立即查看！}

文件：$(basename "$artifact_file") (${file_size})
NotebookLM：https://notebooklm.google.com/notebook/$NOTEBOOK_ID

---
⏳ 更多产物生成中，完成后会继续通知..."

  # 发送到 Feishu
  message action=send channel=feishu target="$FEISHU_TARGET" message="$message" 2>/dev/null || echo "  ⚠️ Failed to send notification"
}

# 主流程
echo "📦 Progressive Delivery Queue:"
printf '%s\n' "${ARTIFACT_QUEUE[@]}" | while IFS=: read type speed label; do
  echo "   $label ($speed)"
done
echo ""

# 启动所有产物生成（后台并行）
echo "🎨 Starting all artifact generation in parallel..."
for item in "${ARTIFACT_QUEUE[@]}"; do
  IFS=: read type speed label <<< "$item"
  
  # 根据类型设置超时
  case $speed in
    instant) timeout=60 ;;
    fast) timeout=300 ;;
    medium) timeout=600 ;;
    slow) timeout=1800 ;;
    *) timeout=300 ;;
  esac
  
  # 后台生成
  (
    if generate_and_wait "$type" "$timeout"; then
      DELIVERED[$type]=true
      
      # 确定文件路径
      case $type in
        mindmap) file="$OUTPUT_DIR/mindmap.json" ;;
        report) file="$OUTPUT_DIR/report.md" ;;
        quiz) file="$OUTPUT_DIR/quiz.json" ;;
        audio) file="$OUTPUT_DIR/podcast.mp3" ;;
        slides) file="$OUTPUT_DIR/slides.pdf" ;;
        video) file="$OUTPUT_DIR/video.mp4" ;;
      esac
      
      # 发送通知
      send_progressive_notification "$type" "$label" "$file"
    else
      DELIVERED[$type]=false
      echo "  ❌ $type failed"
    fi
  ) &
done

# 等待所有后台任务完成
wait

# 生成最终总结
echo ""
echo "✅ Progressive delivery complete!"
echo ""
echo "📊 Delivery Summary:"
for item in "${ARTIFACT_QUEUE[@]}"; do
  IFS=: read type speed label <<< "$item"
  status="${DELIVERED[$type]:-false}"
  if [[ "$status" == "true" ]]; then
    echo "   ✅ $label"
  else
    echo "   ❌ $label (failed)"
  fi
done

# 保存交付记录
cat > "$OUTPUT_DIR/progressive_delivery.json" <<EOF
{
  "topic": "$TOPIC",
  "notebook_id": "$NOTEBOOK_ID",
  "completed_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "artifacts": {
    "mindmap": ${DELIVERED[mindmap]:-false},
    "report": ${DELIVERED[report]:-false},
    "quiz": ${DELIVERED[quiz]:-false},
    "audio": ${DELIVERED[audio]:-false},
    "slides": ${DELIVERED[slides]:-false},
    "video": ${DELIVERED[video]:-false}
  }
}
EOF
