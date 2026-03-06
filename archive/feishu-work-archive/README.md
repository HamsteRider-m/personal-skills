# 飞书文档批量导出 - 最终方案

## 成功验证

✅ agent-browser + 持久化 profile 可以保持登录状态
✅ 登录一次后，后续访问文档无需重新登录
✅ 可以正常提取文档内容

## 使用方法

### 1. 首次登录（已完成）
```bash
agent-browser --profile ~/.openclaw/workspace/skills/feishu-work-archive/profile --headed open https://ottno-cd.feishu.cn/drive/home/
# 手动登录后，登录状态会保存到 profile 目录
```

### 2. 批量导出（待执行）

创建 todo list，交给 kimi/qwen agent 处理：

**任务清单：** 229 个文档（见 batches.json）

**每个文档的处理步骤：**
1. `agent-browser --profile <path> open <doc_url>`
2. `agent-browser --profile <path> snapshot -i -c` 或 `get text 'body'`
3. 保存到 Obsidian：`~/Library/CloudStorage/OneDrive-个人/obsidian-vault/Projects/工作归档/<category>/<filename>.md`
4. 添加 frontmatter（title, category, url, exported_at）

### 3. 关键命令

```bash
# 访问文档
agent-browser --profile ~/.openclaw/workspace/skills/feishu-work-archive/profile open <url>

# 提取内容（交互元素）
agent-browser snapshot -i -c

# 提取全文
agent-browser eval "document.body.innerText"

# 关闭
agent-browser close
```

## 文档分类

- 财务预算管理: 36 个
- 会议纪要: 37 个
- 工作汇报: 48 个
- 运营管理: 18 个
- 技术工具: 3 个
- 其他文档: 87 个

## 下一步

将 batches.json 转换为 agent 可执行的 todo list，交给 kimi/qwen 处理。
