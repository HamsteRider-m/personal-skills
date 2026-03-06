# /obos tidy

整理笔记并批量归位。默认增量执行，内置幂等保护，避免重复整理和重复重命名。

## Usage

```
/obos tidy                  # 整理默认 vault
/obos tidy --to work        # 整理指定 vault
/obos tidy --dry-run        # 只预览不执行
/obos tidy --mode strong --priority structure --dry-run
/obos tidy --force-retidy
/obos tidy --force-rename
```

## Parameters

| Param | Description |
|------|-------------|
| `--mode standard` | 默认模式。仅整理 Inbox + vault 根目录散落文件 |
| `--mode strong` | 强整理模式。先做目录必要性评估，再做文件迁移 |
| `--dry-run` | 输出迁移方案，不做写入 |
| `--priority links` | 链接优先（默认）：优先避免断链 |
| `--priority structure` | 结构优先：先完成归位，断链在后续报告修复 |
| `--project-policy contain` | 默认。项目目录结构冻结：不改内部层级与文件名，只允许整体平移容器路径 |
| `--project-policy split` | 覆盖策略。允许项目目录文件按语义打散到全局目录 |
| `--force-retidy` | 仅本次忽略迁移锁，重新生成迁移决策 |
| `--force-rename` | 仅本次忽略名称锁，允许再次自动重命名 |

## Tidy State Files

`tidy` 使用 `.obos` 目录持久化状态：

- `/.obos/tidy-state.json`：内容指纹、上次目标目录、名称锁等幂等状态
- `/.obos/tidy-config.json`：可选配置（含目录必要性评估参数）
- `/.obos/dir-audit.json`：目录评分、建议动作、执行动作、时间戳

`tidy-config.json` 示例：
```json
{
  "projectRootsExtra": [
    "private/capitalistAnthropologyDiary"
  ],
  "dirEvaluation": {
    "enabled": true,
    "protectedRoots": [".obsidian", ".obos", "Templates", "Attachments", "Excalidraw"],
    "projectDecisionMode": "interactive",
    "thresholds": { "keep": 70, "reorganize": 40 },
    "archiveRoot": "_archive",
    "deleteMarkdown": false,
    "autoDeleteEmptyDirs": true
  }
}
```

## Step 1: 确定目标 Vault

使用 SKILL.md 中的 Vault Path Discovery 逻辑。

## Step 2: 安全检查（strong 模式必做）

当 `--mode strong`：

1. 检查 vault 是否为 git 仓库
2. 非 git 仓库时，提示先执行基线保护：
   - `git init`
   - `git add -A`
   - `git commit -m "chore: vault baseline before obos tidy strong"`
3. 若工作区有未提交变更，用 AskUserQuestion 询问：
   - "继续并自动提交快照（推荐）"
   - "继续但不提交"
   - "取消"

## Step 3: 加载幂等状态与配置

1. 读取 `/.obos/tidy-state.json`（不存在则初始化空状态）
2. 读取 `/.obos/tidy-config.json`（不存在则用默认配置）
3. 若状态文件损坏：强制切换为 `--dry-run` 并重建状态草案，不直接执行迁移
4. 初始化目录审计输出 `/.obos/dir-audit.json`

## Step 4: 目录必要性评估（strong 模式先执行）

### 4.1 评估范围

- 评估 legacy 和业务目录必要性（例如 `digital-hub/`、`private/`、`_drafts/`、`projects/`）
- `dirEvaluation.protectedRoots` 命中的强保护目录默认不参与清理迁移，仅记录评分并 `KEEP`

### 4.2 评分规则（0-100）

按 6 个维度加权评分：

1. 结构角色（0-25）：是否承担系统/模板/附件/项目容器职能
2. 内容活跃（0-20）：近 90 天是否有修改
3. 内容密度（0-15）：目录内文档数与非空率
4. 链接中心性（0-15）：是否被大量 `[[wikilink]]` 引用
5. 冗余程度（0-15，反向）：与其他目录职责是否重叠
6. 命名可理解性（0-10）：目录名是否清晰表达用途

### 4.3 三档动作

- `>= 70` → `KEEP`：保留目录，仅轻量规范化
- `40-69` → `REORGANIZE`：重组并迁移到更合理目录结构
- `< 40` → `ARCHIVE_DIR`：归档到 `_archive/YYYY-MM-DD/<old-path>/`，迁移后删除空目录

### 4.4 项目目录交互决策（必须）

项目目录识别：
- 默认识别：`*/projects/*`
- 额外识别：`tidy-config.json.projectRootsExtra`

当命中项目目录且 `projectDecisionMode=interactive`：

1. 输出决策卡片：评分、理由、预计迁移数、潜在断链数
2. 用 AskUserQuestion 逐目录询问：
   - "保留"（KEEP）
   - "冻结结构（推荐）"（保持项目内部结构不变）
   - "允许拆散"（split）
3. 未经用户确认，不执行项目目录拆散

### 4.5 删除边界

- 默认 `deleteMarkdown=false`：不自动删除任何 markdown 文档
- “先归档后删除”针对目录结构与空目录，不删除笔记内容
- 若 `autoDeleteEmptyDirs=true`，迁移后自动删除空目录并写审计日志

### 4.6 评估输出

将每个目录写入 `/.obos/dir-audit.json`：

- `dir`
- `score`
- `reasons`
- `suggestedAction`（KEEP/REORGANIZE/ARCHIVE_DIR）
- `finalAction`
- `timestamp`

## Step 5: 扫描待整理文件

扫描以下位置的 .md 文件：

### standard 模式
1. `Inbox/` 目录下所有文件
2. Vault 根目录下散落的 .md 文件（排除 CLAUDE.md、Index.md、README.md）

### strong 模式
1. `Inbox/` + vault 根目录散落 .md
2. `REORGANIZE/ARCHIVE_DIR` 目录下的 .md
3. 递归扫描时保留原相对路径，供迁移方案展示

排除项（不参与整理）：
- 已在标准目录中的文件（Notes/、Clippings/、References/、Categories/、Templates/）
- Attachments/ 下的文件
- `.obsidian/` 下的文件
- 所有 hidden / dot 目录（`./.*`，如 `.agent/`、`.cursor/`、`.claude/`）
- frontmatter 中 `status` 不是 `inbox` 且已在标准目录中的文件

如果没有待整理文件，输出提示并结束：
```
Inbox 为空，没有需要整理的文件。
运行 /obos save 收集新想法。
```

## Step 6: 双重幂等判定（核心）

每个候选文件按以下顺序判定：

1. **Frontmatter 锁**：已整理且无新变更时默认跳过
2. **状态指纹锁**：比较 `tidy-state.json` 中的 `lastContentHash + lastTargetDir + lastKnownName`
3. 指纹一致且无 `--force-retidy` 时，跳过该文件（不重复整理）
4. 若检测到文件名被手工修改（与上次自动命名不同），自动写入 `name_locked: true`

## Step 7: AI 分类

逐个读取文件内容，分析后判断目标目录：

| 目标目录 | 判断信号 |
|----------|----------|
| `Notes/` | 个人观点、独立概念、原创想法、方法论总结 |
| `Clippings/` | 外部内容摘录、网页剪藏、他人观点引用 |
| `References/` | 书摘、论文笔记、课程笔记、系统性参考资料 |
| `Categories/` | 主题索引、多篇笔记的汇总页 |
| `（原地保留）` | 内容太短、置信度低或无法判断，标记为 `review_needed: true` |

分类依据优先级：
1. frontmatter 中的 `keywords` 或 `source` 字段
2. 文件内容语义分析
3. 文件名模式（如含日期、含 "clip-" 前缀等）
4. 原路径信号（如 `clippings/`、`references/`、`projects/`）

低置信度策略（默认）：
- 不迁移，原地保留
- 标记 `review_needed: true`
- 在方案与最终报告中列出

## Step 8: 自动重命名策略（strong 模式默认开启）

命中文件名模式时，生成语义化新文件名：

- `未命名*.md`
- `Untitled*.md`
- `draft-*.md`

重命名规则：
1. 优先使用首个 H1
2. 无 H1 时使用第一段核心句
3. 归一化非法字符并去重（冲突时追加 `-2`, `-3`）
4. 自动重命名默认只执行一次；后续命中 `name_locked: true` 时不再改名
5. `--force-rename` 仅对本次执行覆盖 `name_locked`
6. 在方案中显示 `旧文件名 -> 新文件名`

## Step 9: 生成整理方案

输出方案表：

```
整理方案（共 N 个文件）：

| # | 文件 | 当前位置 | → 目标 | 新文件名（可选） | 目录动作 | 项目边界 | 理由 |
|---|------|----------|--------|------------------|----------|----------|------|
| 1 | AI工具对比.md | Inbox/ | Clippings/ | - | REORGANIZE | n/a | 外部信息汇总 |
| 2 | 函数式编程思考.md | Inbox/ | Notes/ | - | REORGANIZE | n/a | 个人观点 |
| 3 | 未命名 1.md | projects/赤耘课/ | projects/赤耘课/notes/ | 财务会议总结.md | KEEP | contain | 项目内归位，不外抛 |
| 4 | 碎片想法.md | Inbox/ | （原地保留） | - | KEEP | n/a | 低置信度，待复核 |
```

**`--dry-run` 模式**：输出方案表后结束，不执行任何操作。

## Step 10: 用户确认

用 AskUserQuestion 询问：
- "全部执行" — 按方案批量移动
- "逐条确认" — 逐个文件询问是否移动
- "取消" — 不做任何操作

## Step 11: 执行移动与目录动作

对每个确认的文件：

1. 如文件属于项目目录且 `project-policy=contain`：
   - 目标路径必须仍在该项目目录内
   - 不改项目内部目录结构
   - 不改项目内文件名（除非显式覆盖）
2. 如有命名建议，先重命名再移动（或原地移动后重命名，二者效果一致）
3. 更新 frontmatter：
   - `status`: `inbox` → `draft`
   - 添加 `moved_from: {原路径}`
   - 添加 `tidied: {YYYY-MM-DD}`
   - 低置信度保留项：`review_needed: true`
   - 检测到手工改名：`name_locked: true`
4. `--priority links`：优先更新 `[[wikilink]]` 再落盘
5. `--priority structure`：先完成迁移，随后输出断链清单供批量修复
6. 对目录动作执行：
   - `KEEP`：仅记录，不迁移目录结构
   - `REORGANIZE`：执行目录重组
   - `ARCHIVE_DIR`：先归档目录结构再清理空目录
7. 持久化 `tidy-state.json` 与 `dir-audit.json`

## Step 12: 输出结果 + 自动触发 sync

```
✅ 整理完成

目录评估：
  KEEP: {n}
  REORGANIZE: {n}
  ARCHIVE_DIR: {n}
  空目录清理: {n}

已移动：
  Inbox/AI工具对比.md → Clippings/AI工具对比.md
  Inbox/函数式编程思考.md → Notes/函数式编程思考.md
  projects/赤耘课/未命名 1.md → projects/赤耘课/notes/财务会议总结.md

原地保留（待复核）：
  Inbox/碎片想法.md（review_needed: true）

目录审计已写入：
  /.obos/dir-audit.json

正在更新索引...
```

整理完成后自动执行 sync 逻辑（更新 Index.md + 健康报告），无需用户手动运行。
