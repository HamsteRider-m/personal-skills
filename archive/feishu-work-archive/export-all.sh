#!/bin/bash
set -e

PROFILE="$HOME/.openclaw/workspace/skills/feishu-work-archive/profile"
OUTPUT_DIR="$HOME/Library/CloudStorage/OneDrive-个人/obsidian-vault/Projects/工作归档"
BATCHES="$HOME/.openclaw/workspace/skills/feishu-work-archive/batches.json"
PROGRESS="$HOME/.openclaw/workspace/skills/feishu-work-archive/progress-final.json"

# 初始化进度
if [ ! -f "$PROGRESS" ]; then
  echo '{"completed":0,"failed":[]}' > "$PROGRESS"
fi

completed=$(jq -r '.completed' "$PROGRESS")
total=$(jq '[.batches[][]] | length' "$BATCHES")

echo "继续从第 $((completed + 1)) 个开始，共 $total 个"
echo ""

# 读取所有文档，跳过已完成的
docs=$(jq -r "[.batches[][]][$completed:] | .[] | @json" "$BATCHES")

count=$completed
while IFS= read -r doc; do
  count=$((count + 1))
  
  name=$(echo "$doc" | jq -r '.name')
  url=$(echo "$doc" | jq -r '.url')
  category=$(echo "$doc" | jq -r '.category')
  
  echo "[$count/$total] $name"
  
  # 访问文档
  if ! agent-browser --profile "$PROFILE" open "$url" > /dev/null 2>&1; then
    echo "  ✗ 访问失败"
    jq ".failed += [{\"name\": \"$name\", \"error\": \"访问失败\"}]" "$PROGRESS" > "$PROGRESS.tmp" && mv "$PROGRESS.tmp" "$PROGRESS"
    continue
  fi
  sleep 2
  
  # 提取内容
  content=$(agent-browser eval "document.querySelector('[role=\"main\"]')?.innerText || document.body.innerText" 2>/dev/null || echo "")
  
  if [ -z "$content" ]; then
    echo "  ✗ 内容为空"
    jq ".failed += [{\"name\": \"$name\", \"error\": \"内容为空\"}]" "$PROGRESS" > "$PROGRESS.tmp" && mv "$PROGRESS.tmp" "$PROGRESS"
    jq ".completed = $count" "$PROGRESS" > "$PROGRESS.tmp" && mv "$PROGRESS.tmp" "$PROGRESS"
    continue
  fi
  
  # 保存
  category_dir="$OUTPUT_DIR/$category"
  mkdir -p "$category_dir"
  
  filename=$(echo "$name" | sed 's/[\/\\:*?"<>|]/_/g' | cut -c1-100).md
  filepath="$category_dir/$filename"
  
  cat > "$filepath" <<EOF
---
title: $name
category: $category
source: 工作飞书
url: $url
exported_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
---

$content
EOF
  
  echo "  ✓ 已保存"
  
  # 更新进度
  jq ".completed = $count" "$PROGRESS" > "$PROGRESS.tmp" && mv "$PROGRESS.tmp" "$PROGRESS"
  
  # 每 20 个报告一次
  if [ $((count % 20)) -eq 0 ]; then
    failed=$(jq '.failed | length' "$PROGRESS")
    echo ""
    echo "进度: $count/$total (失败: $failed)"
    echo ""
  fi
  
done <<< "$docs"

failed=$(jq '.failed | length' "$PROGRESS")
echo ""
echo "全部完成！成功: $((count - failed)) 失败: $failed"
