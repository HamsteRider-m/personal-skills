# /obos sync

扫描 vault，更新索引文件，输出健康报告，并为孤岛笔记建议链接。

## Usage

```
/obos sync                # 全量同步：更新 Index.md + CLAUDE.md + 健康报告 + 链接建议
/obos sync --status       # 只读模式：仅输出健康报告
/obos sync --to work      # 同步指定 vault
```

## Step 1: 确定目标 Vault

使用 SKILL.md 中的 Vault Path Discovery 逻辑。

## Step 2: 扫描 Vault

扫描标准目录（`Inbox/`、`Notes/`、`Clippings/`、`References/`、`Categories/`）中的所有 .md 文件。

对每个文件提取：
- 标题（文件名或第一个 H1）
- 首行摘要（跳过 frontmatter/标题，截取 60 字符）
- frontmatter `status` 字段（inbox/draft/refined）
- frontmatter `review_needed` 字段（true/false）
- 所有 `[[wikilink]]` 引用（出链和目标）
- 修改日期

**构建链接图**：内存中建立 `笔记 → [出链]` 和 `笔记 → [入链]` 的映射。

**性能保护**：vault 超过 500 个文件时，Recent Notes 只扫描最近 90 天。Categories 和统计始终覆盖全量。

## Step 3: 更新 Index.md

`--status` 模式跳过此步。

写入 vault 根目录的 `Index.md`：

```markdown
# Index
Last synced: {YYYY-MM-DD HH:MM}

## Recent Notes
| Note | Summary | Status | Dir | Updated |
|------|---------|--------|-----|---------|
| [[note]] | First line... | draft | Notes | 2026-01-27 |
(top 50 by modified date)

## Categories
- [[Category/Topic]] - {count} notes

## Statistics
- Total notes: {count}
- Inbox: {n} | Notes: {n} | Clippings: {n} | References: {n}
- Maturity: {n} inbox, {n} draft, {n} refined
```

## Step 4: 更新 CLAUDE.md

`--status` 模式跳过此步。

**边界保护**：只修改 `## Current Context` 段落，其他段落原样保留。

1. 读取 CLAUDE.md
2. 定位 `## Current Context`（从标题到下一个 `## ` 或 EOF）
3. 替换（或追加）为：

```markdown
## Current Context
Last synced: {date}

### Recent Activity
- {recent note 1}
- {recent note 2}
(up to 5 most recently modified notes)

### Active Topics
- {topic with most recent notes}
(up to 3 topics from Categories with most recent activity)
```

## Step 5: 健康报告

在所有模式下输出。

### 孤岛笔记

无入链的笔记（排除 Index.md、CLAUDE.md、Templates/、Inbox/ 中的文件）。

### 断链

指向不存在文件的 `[[wikilink]]`。

### 成熟度分布

各 status 的笔记数量。

### 待复核笔记

`review_needed: true` 的笔记数量与列表（最多显示 10 条）。

### 目录审计摘要

如果存在 `/.obos/dir-audit.json`，读取并输出目录动作摘要：
- `KEEP` 数量
- `REORGANIZE` 数量
- `ARCHIVE_DIR` 数量
- 最近一次目录评估时间

输出格式：

```
Vault 健康报告
──────────────
总笔记: {count}
  Inbox: {n} | Notes: {n} | Clippings: {n} | References: {n}
成熟度: {n} inbox, {n} draft, {n} refined
待复核: {n}
目录动作: {n} KEEP, {n} REORGANIZE, {n} ARCHIVE_DIR
孤岛笔记: {n}
断链: {n}
Last synced: {timestamp}
```

## Step 6: 链接建议（新增，合并原 link 功能）

`--status` 模式跳过此步。

对每个孤岛笔记（最多处理 10 个，按修改时间倒序）：

1. 读取笔记内容，提取主题和关键词
2. 在 Index.md + vault 中搜索内容相关的笔记
3. 按相关度排序，建议 2-3 个链接

输出格式：

```
链接建议（{n} 篇孤岛笔记）：
- Notes/函数式编程.md
  → [[编程范式]], [[Haskell学习笔记]]
- Notes/GTD方法论.md
  → [[生产力工具]], [[时间管理]]
```

如果有建议，用 AskUserQuestion 询问：
- "应用所有建议" — 批量添加到各笔记的 `## Related` 段落
- "逐条选择" — 逐个笔记确认
- "跳过" — 不添加链接
