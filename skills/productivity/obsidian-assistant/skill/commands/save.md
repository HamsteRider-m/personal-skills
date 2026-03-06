# /obos save

核心命令。快速收集想法到 vault 的 Inbox 目录。

## Usage

```
/obos save "想法或内容"        # 直接存入默认 vault
/obos save "内容" --to work    # 存入指定 vault
/obos save                     # 从当前对话上下文自动提取
```

## Step 1: 确定目标 Vault

按优先级：
1. `--to <alias>` 参数指定
2. obos-config.json 中的 default vault
3. 如果无配置，用 AskUserQuestion 引导注册（参考 vault.md）

确定后更新 `lastUsedVault`。

## Step 2: 提取内容

**有参数**：使用用户传入的文本作为原始内容。

**无参数**：分析当前对话上下文，提取：
- 关键结论或洞见
- 决策和理由
- 值得记录的想法

如果对话中没有明显可提取的内容，用 AskUserQuestion 询问："你想保存什么？"

## Step 3: 生成笔记

AI 自动处理：
1. **生成标题**：从内容中提炼简洁的名词短语标题（中文或英文，跟随内容语言）
2. **生成摘要**：一句话概括核心内容
3. **识别关键词**：提取 2-3 个关键词，用于后续 tidy 分类参考

生成文件内容：

```markdown
---
status: inbox
source: "AI conversation"
created: {YYYY-MM-DD}
keywords: [关键词1, 关键词2]
---
# {title}

{整理后的内容}

## 原始上下文

{如果是从对话提取的，保留关键上下文片段，方便日后回溯}
```

文件路径：`Inbox/{YYYY-MM-DD}-{title}.md`

标题中的特殊字符（`/\:*?"<>|`）替换为 `-`。

## Step 4: 写入文件

**短内容（< 5 行）**：零确认直接写入。

**长内容（>= 5 行）**：展示预览后写入：
```
预览：
  标题: {title}
  路径: Inbox/{filename}
  摘要: {summary}
  ---
  {前 200 字}...
```

使用 Write 工具写入文件。

## Step 5: 确认输出

```
✅ 已保存到: {vault_alias} → Inbox/{filename}
   摘要: {summary}

💡 运行 /obos tidy 将 Inbox 中的笔记整理到正确目录
```
