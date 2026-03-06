#!/bin/bash
# 使用 agent-browser 批量导出飞书文档

PROFILE_DIR="$HOME/.openclaw/workspace/skills/feishu-work-archive/agent-browser-profile"
BATCHES_FILE="$HOME/.openclaw/workspace/skills/feishu-work-archive/batches.json"
PROGRESS_FILE="$HOME/.openclaw/workspace/skills/feishu-work-archive/progress-agent.json"
OUTPUT_DIR="$HOME/Library/CloudStorage/OneDrive-个人/obsidian-vault/Projects/工作归档"

# 初始化进度
if [ ! -f "$PROGRESS_FILE" ]; then
  echo '{"completed":0,"failed":[],"results":[]}' > "$PROGRESS_FILE"
fi

# 读取进度
COMPLETED=$(jq -r '.completed' "$PROGRESS_FILE")
TOTAL=$(jq '[.batches[][]] | length' "$BATCHES_FILE")

echo "进度: $COMPLETED/$TOTAL"
echo "首次运行需要手动登录飞书..."
echo ""

# 打开飞书首页让用户登录
agent-browser --profile "$PROFILE_DIR" open https://ottno-cd.feishu.cn/drive/home/

echo ""
echo "请在浏览器中登录飞书，登录完成后按回车继续..."
read

echo "开始批量导出..."
