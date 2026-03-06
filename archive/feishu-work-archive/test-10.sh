#!/bin/bash
set -e

PROFILE="$HOME/.openclaw/workspace/skills/feishu-work-archive/profile"
OUTPUT_DIR="$HOME/Library/CloudStorage/OneDrive-个人/obsidian-vault/Projects/工作归档"
BATCHES="$HOME/.openclaw/workspace/skills/feishu-work-archive/batches.json"

# 读取前 10 个文档
docs=$(jq -r '[.batches[][]][0:10] | .[] | @json' "$BATCHES")

count=0
while IFS= read -r doc; do
  count=$((count + 1))
  
  name=$(echo "$doc" | jq -r '.name')
  url=$(echo "$doc" | jq -r '.url')
  category=$(echo "$doc" | jq -r '.category')
  
  echo "[$count/10] $name"
  
  # 访问文档
  agent-browser --profile "$PROFILE" open "$url" > /dev/null 2>&1
  sleep 2
  
  # 提取内容
  content=$(agent-browser eval "document.querySelector('[role=\"main\"]')?.innerText || document.body.innerText" 2>/dev/null || echo "")
  
  if [ -z "$content" ]; then
    echo "  ✗ 内容为空"
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
  
done <<< "$docs"

echo ""
echo "完成！处理了 $count 个文档"
