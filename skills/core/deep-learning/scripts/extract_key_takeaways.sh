#!/bin/bash
# Key Takeaways Extractor
# 从各种产物中提取核心价值摘要

set -euo pipefail

extract_from_report() {
  local file=$1
  
  if [[ ! -f "$file" ]]; then
    echo "• 报告生成中..."
    return
  fi
  
  # 提取标题和主要章节
  local title=$(head -5 "$file" | grep "^# " | head -1 | sed 's/^# //')
  
  # 提取关键要点（前3个H2/H3标题）
  local key_points=$(grep -E "^#{2,3} " "$file" | head -3 | sed 's/^#* //' | sed 's/^/- /')
  
  # 提取总结段落（如果有）
  local summary=""
  if grep -q "## 总结\|## Summary\|## 要点\|## Key Points" "$file"; then
    summary=$(sed -n '/## 总结/,/## /p;/## Summary/,/## /p' "$file" | grep -v "^##" | head -5)
  fi
  
  cat <<EOF
📄 **${title:-学习报告}**

核心要点：
$key_points

${summary:+快速理解：
$summary}
EOF
}

extract_from_mindmap() {
  local file=$1
  
  if [[ ! -f "$file" ]]; then
    echo "• 思维导图生成中..."
    return
  fi
  
  # 解析 JSON 提取核心节点
  local central_topic=$(jq -r '.centralTopic.text // .nodes[0].text // "主题"' "$file" 2>/dev/null)
  local main_branches=$(jq -r '.nodes[1:4].text // empty' "$file" 2>/dev/null | sed 's/^/- /')
  
  cat <<EOF
🗺️ **知识地图：$central_topic**

核心分支：
${main_branches:-• 知识结构清晰呈现}

适合：快速建立整体认知框架
EOF
}

extract_from_quiz() {
  local file=$1
  
  if [[ ! -f "$file" ]]; then
    echo "• 测试题生成中..."
    return
  fi
  
  # 统计题目数量和类型
  local total_questions=$(jq '.questions | length' "$file" 2>/dev/null || echo "0")
  local question_types=$(jq -r '.questions[].type // empty' "$file" 2>/dev/null | sort | uniq -c | sort -rn | head -3)
  local sample_question=$(jq -r '.questions[0].question // empty' "$file" 2>/dev/null | cut -c1-100)
  
  cat <<EOF
❓ **自测练习 ($total_questions 题)**

题型分布：
$(echo "$question_types" | sed 's/^/• /')

示例：
${sample_question}...

💡 建议：先做题再对照报告查漏补缺
EOF
}

extract_from_audio() {
  local file=$1
  local notebook_id=$2
  
  if [[ ! -f "$file" ]]; then
    echo "• 播客生成中..."
    return
  fi
  
  # 获取音频时长
  local duration=""
  if command -v ffprobe &>/dev/null; then
    duration=$(ffprobe -i "$file" -show_entries format=duration -v quiet -of csv="p=0" 2>/dev/null | awk '{printf "%d:%02d", $1/60, $1%60}')
  fi
  
  cat <<EOF
🎙️ **深度播客 ${duration:+($duration)}**

本期内容：
• 两位AI主持人的深度对话
• 从多个角度解析核心概念
• 结合实际案例讲解

🎧 适合场景：通勤、运动、休息时收听
🔗 NotebookLM 可查看完整对话文本
EOF
}

extract_from_slides() {
  local file=$1
  
  if [[ ! -f "$file" ]]; then
    echo "• PPT生成中..."
    return
  fi
  
  local size=$(du -h "$file" 2>/dev/null | cut -f1)
  
  cat <<EOF
📊 **PPT讲义 (${size})**

内容特点：
• 结构化知识点呈现
• 图文结合易于理解
• 可直接用于分享或演讲

💼 适用：团队分享、学习笔记、演讲素材
EOF
}

extract_from_video() {
  local file=$1
  
  if [[ ! -f "$file" ]]; then
    echo "• 视频生成中..."
    return
  fi
  
  local size=$(du -h "$file" 2>/dev/null | cut -f1)
  
  cat <<EOF
🎬 **视频解说 (${size})**

视频特点：
• 带旁白的幻灯片演示
• 视觉+听觉双重学习
• 节奏适中便于理解

📺 适合：喜欢视频学习的用户
EOF
}

# 主函数
main() {
  local artifact_type=$1
  local artifact_file=$2
  local notebook_id=${3:-}
  
  case $artifact_type in
    report)
      extract_from_report "$artifact_file"
      ;;
    mindmap)
      extract_from_mindmap "$artifact_file"
      ;;
    quiz)
      extract_from_quiz "$artifact_file"
      ;;
    audio|podcast)
      extract_from_audio "$artifact_file" "$notebook_id"
      ;;
    slides|ppt)
      extract_from_slides "$artifact_file"
      ;;
    video)
      extract_from_video "$artifact_file"
      ;;
    *)
      echo "• 产物已就绪，点击查看详情"
      ;;
  esac
}

# 如果直接运行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <artifact_type> <artifact_file> [notebook_id]"
    echo "Types: report, mindmap, quiz, audio, slides, video"
    exit 1
  fi
  main "$@"
fi
