# obos 技术架构设计与实现路线图

> Agent C: Skill Architect（技术架构师）
> 生成日期：2026-02-08

---

## 一、技术可行性评估

### 1.1 现有命令优化项

以下逐项评估 Agent A/B 对现有 5 个命令提出的优化建议。

#### 1.1.1 /obos init — 交互式引导 + 幂等性

| 优化项 | 难度 | Token 成本 | 框架适配性 | 说明 |
|--------|------|-----------|-----------|------|
| 幂等性（已存在跳过） | Easy | Low | 原生适配 | 命令文件中增加 exists 检查逻辑描述即可，无需改 SKILL.md |
| 交互式引导填写 CLAUDE.md | Easy | Low | 原生适配 | 使用 AskUserQuestion 工具，在 init.md 中增加引导步骤 |
| 扩展模板（Weekly.md, Meeting.md） | Easy | Low | 原生适配 | 在 init.md 的 Step 5 中追加模板定义 |
| checklist 格式输出 | Easy | Low | 原生适配 | 纯输出格式调整，改 init.md 的 Success Message 即可 |

**结论**：init 的所有优化项均为 Easy/Low，可直接在 `commands/init.md` 中实现，不影响 SKILL.md 体积。

#### 1.1.2 /obos daily — Carry-forward + 认知引导

| 优化项 | 难度 | Token 成本 | 框架适配性 | 说明 |
|--------|------|-----------|-----------|------|
| Carry-forward（昨日未完成迁移） | Medium | Low | 原生适配 | 需在 daily.md 中增加"读取昨日笔记 → 提取 `- [ ]` 项"步骤 |
| 本周焦点注入 | Medium | Low | 原生适配 | 需读取最近周报的 Carry Forward 区，逻辑稍复杂 |
| 模板认知引导（blockquote 提问） | Easy | Low | 原生适配 | 修改模板文本即可 |
| 日期参数支持 | Easy | Low | 原生适配 | 在 daily.md 中增加参数解析说明 |
| 已存在时展示状态摘要 | Easy | Low | 原生适配 | 修改 Step 4 的"已存在"分支 |

**结论**：carry-forward 是唯一 Medium 难度项，核心挑战是准确解析昨日笔记中的未完成 checkbox。其余均为 Easy。所有改动限于 `commands/daily.md`。

#### 1.1.3 /obos weekly — 苏格拉底式反思引导

| 优化项 | 难度 | Token 成本 | 框架适配性 | 说明 |
|--------|------|-----------|-----------|------|
| 从"AI 生成"改为"AI 引导反思" | Medium | Medium | 原生适配 | 需重写交互流程，增加 AskUserQuestion 多轮引导 |
| 量化统计（完成率、笔记数） | Easy | Low | 原生适配 | 在分析步骤中增加计数逻辑 |
| 周期灵活（last, W05） | Easy | Low | 原生适配 | 增加参数解析 |
| 趋势对比 | Medium | Low | 原生适配 | 需读取上周周报并对比，增加一个步骤 |
| Carry Forward 生成 checkbox | Easy | Low | 原生适配 | 输出格式调整 |

**结论**：苏格拉底式反思引导是核心修正，将 weekly 从"一键生成"变为"引导式对话"。这会增加 weekly.md 的行数（约 +30 行），但不影响 SKILL.md。Token 成本标记为 Medium 是因为多轮交互会消耗更多运行时 token，但这是设计意图而非浪费。

#### 1.1.4 /obos save — 加工引导 + 成熟度标记

| 优化项 | 难度 | Token 成本 | 框架适配性 | 说明 |
|--------|------|-----------|-----------|------|
| 保存前加工引导（三问） | Medium | Medium | 原生适配 | 增加 AskUserQuestion 引导步骤，save.md 增加约 40 行 |
| `--quick` 跳过引导 | Easy | Low | 原生适配 | 参数解析 + 条件分支 |
| 成熟度标记（seed/seedling/evergreen） | Easy | Low | 原生适配 | 在模板 frontmatter 中添加 `status:` 字段 |
| 关联发现（保存后提示相关笔记） | Medium | Low | 原生适配 | 需扫描 vault 中已有笔记标题/内容，匹配关键词 |
| meeting 类型扩展 | Easy | Low | 原生适配 | 增加一个类型分支和模板 |
| 冲突处理（同名文件） | Easy | Low | 原生适配 | 增加 exists 检查和用户选择 |

**结论**：加工引导是方法论层面最关键的修正。实现上是在 save.md 中插入一个"引导步骤"，技术难度不高但对用户体验影响深远。`--quick` 旁路确保不牺牲快速保存场景。

#### 1.1.5 /obos sync — 健康检查 + 深层上下文

| 优化项 | 难度 | Token 成本 | 框架适配性 | 说明 |
|--------|------|-----------|-----------|------|
| 孤立笔记检测 | Medium | Low | 原生适配 | 需解析所有笔记的 wikilink，构建链接图，找无链接节点 |
| 断链检测 | Medium | Low | 原生适配 | 解析 wikilink 目标，检查文件是否存在 |
| 健康报告输出 | Easy | Low | 原生适配 | 输出格式调整 |
| 成熟度分布统计 | Easy | Low | 原生适配 | 扫描 frontmatter 中的 status 字段并计数 |
| 深层上下文（CLAUDE.md 增强） | Easy | Low | 原生适配 | 扩展 Current Context 模板 |

**结论**：孤立笔记和断链检测是 sync 最有价值的增强。技术上需要 AI 在扫描时构建一个简单的链接图谱，这在 Claude 的能力范围内，但对大型 vault（500+ 笔记）可能需要分批处理。

### 1.2 新增命令评估

Agent B 提出 6 个新子命令。以下从 skill 框架约束出发逐一评估。

#### 1.2.1 /obos quick — 快速捕获

| 维度 | 评估 |
|------|------|
| 实现难度 | **Easy** |
| Token 成本 | **Low** — 新增 `commands/quick.md` 约 50 行，按需加载 |
| 框架适配性 | **原生适配** — 标准命令路由，无特殊需求 |

**技术要点**：
- 参数解析：引号包裹的文本直接提取，无参数时从对话上下文提取
- 自动归类逻辑可复用 save 的类型检测，但简化为二选一（Notes/ seed vs Daily/ 追加）
- 关联提示需扫描 vault 标题列表（可复用 Index.md 数据）
- 无需用户确认（快速优先），这是与 save 的核心区别

**风险**：与 `save` 功能有重叠。需在 SKILL.md 的命令表中明确区分：`quick` = 零摩擦即时捕获，`save` = 带加工引导的深度保存。

#### 1.2.2 /obos ask — 知识检索

| 维度 | 评估 |
|------|------|
| 实现难度 | **Medium** |
| Token 成本 | **Medium** — 命令文件约 60 行；运行时需读取多篇笔记，token 消耗取决于 vault 规模 |
| 框架适配性 | **原生适配** — 但运行时 token 消耗较高 |

**技术要点**：
- 关键词提取 → 利用 Index.md 定位候选笔记 → 读取候选笔记全文 → 综合回答
- Index.md 的 Recent Notes 表只有 top 20，不足以支撑全库检索。需要在 ask.md 中描述"先读 Index.md 定位，不足时用 Glob + Grep 扩展搜索"的策略
- 大型 vault 的 token 消耗是主要风险：如果匹配到 10+ 篇笔记，全部读取会消耗大量 context。需设置上限（如最多读取 5 篇最相关笔记）

**风险**：检索质量高度依赖 AI 的关键词提取和语义匹配能力。对于模糊查询（"我之前关于 X 有什么想法"），效果可能不稳定。

#### 1.2.3 /obos draft — 基于笔记的内容创作

| 维度 | 评估 |
|------|------|
| 实现难度 | **Hard** |
| Token 成本 | **High** — 命令文件约 80 行；运行时需读取多篇素材笔记 + 生成长文 |
| 框架适配性 | **原生适配但重量级** — 多轮交互 + 大量读写 |

**技术要点**：
- 素材检索复用 ask 的搜索逻辑
- 大纲生成需要 AI 理解多篇笔记的关系并组织结构
- 方法论校准后改为"框架 + 写作提示"而非"完整初稿"，这实际上降低了 token 消耗
- `--outline` 模式是轻量版，只输出大纲，适合快速使用

**风险**：这是所有命令中最重量级的。单次执行可能消耗大量 token。建议作为 Phase 3 实现，且默认使用 `--outline` 模式。

#### 1.2.4 /obos link — 智能链接建议

| 维度 | 评估 |
|------|------|
| 实现难度 | **Medium** |
| Token 成本 | **Medium** — 需读取目标笔记 + 扫描候选笔记 |
| 框架适配性 | **原生适配** |

**技术要点**：
- 单笔记模式：读取目标笔记 → 提取关键词 → 在 vault 中搜索匹配笔记 → 建议链接
- 全库模式：遍历所有笔记，找出零链接的孤岛 → 逐一建议。全库模式 token 消耗高，需分批处理
- 链接插入需要精确的文件编辑（在合适位置插入 `[[wikilink]]`）
- 方法论要求附带"理由说明"，增加约 20% 的输出 token

**风险**：全库扫描模式对大型 vault 不实际。建议默认为单笔记模式，全库模式仅在 sync 的健康报告中以摘要形式呈现。

#### 1.2.5 /obos refine — 笔记精炼

| 维度 | 评估 |
|------|------|
| 实现难度 | **Medium** |
| Token 成本 | **Medium** — 多轮对话式交互 |
| 框架适配性 | **原生适配** — 苏格拉底三问模型天然适合 skill 的步骤式描述 |

**技术要点**：
- 读取目标笔记 → 提取要点 → 苏格拉底三问（复述/评判/关联）→ 基于用户回答生成 evergreen note
- 三问模型可结构化为三个明确步骤，每步使用 AskUserQuestion
- 生成的 evergreen note 使用升级后的模板（Core Idea / My Understanding / Open Questions / Related）
- 需在原笔记中添加指向精炼版的反向链接

**风险**：低。这是方法论价值最高、技术风险最低的新命令。强烈建议优先实现。

#### 1.2.6 /obos status — 知识库仪表盘

| 维度 | 评估 |
|------|------|
| 实现难度 | **Easy** |
| Token 成本 | **Low** — 只读操作，扫描文件元数据即可 |
| 框架适配性 | **原生适配** |

**技术要点**：
- 纯只读命令，不修改任何文件
- 统计数据：各目录文件计数、本周新增/修改数、待办完成率
- 成熟度分布：扫描 frontmatter 中的 status 字段
- 健康指标：复用 sync 的孤立笔记/断链检测逻辑（轻量版）
- 可利用 Index.md 的 Statistics 区加速，避免全量扫描

**风险**：极低。建议作为 Phase 1 快速实现。

### 1.3 跨命令机制评估

Agent A/B 提出了若干贯穿多个命令的横切机制，这些机制的实现方式直接影响架构设计。

#### 1.3.1 知识成熟度模型（seed/seedling/evergreen）

| 维度 | 评估 |
|------|------|
| 涉及命令 | quick, save, refine, status, sync |
| 实现难度 | **Easy** — 纯约定，无需代码 |
| Token 成本 | **Low** — 仅在 SKILL.md 中增加约 10 行共享约定 |
| 框架适配性 | **原生适配** |

**实现方案**：
- 在笔记 frontmatter 中使用 `status: seed|seedling|evergreen` 标记
- `quick` 创建的笔记默认 `status: seed`
- `save` 未经加工引导的默认 `status: seedling`，经过引导的为 `status: evergreen`
- `refine` 完成后将目标笔记升级为 `status: evergreen`
- `status` 和 `sync` 读取此字段进行统计
- 这是一个**纯约定层**的机制，不需要任何运行时逻辑，只需在各命令文件中统一描述

**架构决策**：成熟度模型的定义放在 SKILL.md 的共享约定区（约 10 行），各命令引用此约定。这是合理的 SKILL.md 膨胀——它是真正的共享逻辑。

#### 1.3.2 Vault Path Discovery（已有，需标准化）

| 维度 | 评估 |
|------|------|
| 涉及命令 | 全部 11 个命令 |
| 当前状态 | 已在 SKILL.md 中定义，各命令文件中重复描述 |
| 优化空间 | 消除命令文件中的重复描述 |

**现状问题**：当前 SKILL.md 中有 Vault Path Discovery 的定义（约 5 行），但 5 个命令文件中各自又重复了一遍（每个约 6 行）。这是 30 行的冗余。

**优化方案**：命令文件中统一使用"按 SKILL.md 中的 Vault Path Discovery 确定路径"一句话引用，不再重复完整逻辑。新增的 6 个命令也遵循此模式。节省约 30 行 on-demand token。

#### 1.3.3 Evergreen Note 模板（升级版）

| 维度 | 评估 |
|------|------|
| 涉及命令 | save, quick, refine, draft |
| 实现难度 | **Easy** |
| Token 成本 | **Low** — 模板定义约 15 行，放在 SKILL.md 共享区 |

**实现方案**：
- 升级后的模板（Core Idea / My Understanding / Open Questions / Related + frontmatter）定义在 SKILL.md 的共享模板区
- save、refine、draft 在生成 evergreen note 时引用此模板
- quick 使用简化版（仅 frontmatter + Core Idea + Related）

#### 1.3.4 关联发现机制

| 维度 | 评估 |
|------|------|
| 涉及命令 | save, quick, link, refine |
| 实现难度 | **Medium** |
| Token 成本 | **Medium** — 运行时需扫描 vault |

**实现方案**：
- 关联发现的核心逻辑是"给定一段文本，在 vault 中找到语义相关的笔记"
- 轻量版：基于标题关键词匹配（利用 Index.md）
- 重量版：读取候选笔记内容进行语义匹配
- save/quick 使用轻量版（快速提示），link/refine 使用重量版（深度分析）
- 不在 SKILL.md 中定义共享逻辑（避免膨胀），而是在各命令文件中分别描述适合自己的匹配策略

### 1.4 可行性评估总览

| 改进项 | 难度 | Token 成本 | 优先级建议 |
|--------|------|-----------|-----------|
| init 幂等性 + 引导 | Easy | Low | P1 |
| daily carry-forward | Medium | Low | P1 |
| daily 模板引导 | Easy | Low | P1 |
| weekly 苏格拉底引导 | Medium | Medium | P2 |
| save 加工引导 | Medium | Medium | P1 |
| save 成熟度标记 | Easy | Low | P1 |
| sync 健康检查 | Medium | Low | P2 |
| **新命令 quick** | Easy | Low | **P1** |
| **新命令 status** | Easy | Low | **P1** |
| **新命令 refine** | Medium | Medium | **P2** |
| **新命令 link** | Medium | Medium | **P2** |
| **新命令 ask** | Medium | Medium | **P2** |
| **新命令 draft** | Hard | High | **P3** |
| 成熟度模型（跨命令） | Easy | Low | P1 |
| Evergreen 模板升级 | Easy | Low | P1 |

---

## 二、Skill 架构重构方案

### 2.1 Token 预算分析

#### 2.1.1 当前 Token 消耗

Claude Code skill 系统的 token 消耗模型：

```
每次 /obos 调用的 token 消耗 = SKILL.md（始终加载）+ 匹配的 command.md（按需加载）
```

当前文件行数统计：

| 文件 | 行数 | 加载时机 |
|------|------|---------|
| SKILL.md | 340 行 | **始终加载** |
| commands/init.md | 143 行 | 按需 |
| commands/save.md | 115 行 | 按需 |
| commands/sync.md | 87 行 | 按需 |
| commands/weekly.md | 81 行 | 按需 |
| commands/daily.md | 59 行 | 按需 |

**核心问题**：SKILL.md 当前 340 行，其中包含了所有 5 个命令的完整实现细节。这意味着即使用户只执行 `/obos daily`，也会加载 init、save、sync、weekly 的全部逻辑。这是严重的 token 浪费。

更关键的是：`commands/` 目录下的文件也包含了各自命令的完整实现。SKILL.md 中的命令描述与 commands/ 文件存在**大量重复**。

#### 2.1.2 重复内容分析

SKILL.md 中每个命令的"Steps"区块与对应 commands/ 文件几乎完全一致：

| 命令 | SKILL.md 中占用行数 | commands/ 文件行数 | 重复率 |
|------|--------------------|--------------------|--------|
| init | ~55 行 | 143 行 | SKILL.md 是 commands/ 的精简版 |
| daily | ~25 行 | 59 行 | 高度重复 |
| weekly | ~35 行 | 81 行 | 高度重复 |
| save | ~60 行 | 115 行 | 高度重复 |
| sync | ~40 行 | 87 行 | 高度重复 |

SKILL.md 中约 **215 行**（63%）是命令实现细节的重复。这些内容在 commands/ 文件中已有完整版本，SKILL.md 中不需要保留。

#### 2.1.3 扩展后的 Token 预算预测

如果不重构，新增 6 个命令后的 SKILL.md 预测：

```
当前 SKILL.md: 340 行
+ 6 个新命令的 Steps 区块: ~180 行（按每命令 30 行估算）
+ 成熟度模型共享约定: ~15 行
+ 升级后的模板定义: ~20 行
= 预计 555 行（始终加载）
```

这是不可接受的膨胀。必须先瘦身再扩展。

### 2.2 SKILL.md 瘦身策略

#### 2.2.1 核心原则

**SKILL.md 只保留两类内容**：
1. **命令路由表**：告诉 AI "有哪些命令、每个命令做什么"（一句话描述）
2. **共享约定**：所有命令都需要的公共逻辑（vault path discovery、成熟度模型、模板定义）

**所有命令的实现细节全部移入 commands/ 文件**。SKILL.md 不再包含任何 Steps 区块。

#### 2.2.2 瘦身后的 SKILL.md 结构

```markdown
---
name: obos
description: "Obsidian vault management..."
metadata:
  short-description: Obsidian vault management
---

# Obsidian Best Practices (obos)

Manage an Obsidian vault with AI-friendly structure.

## Commands

| Command | Description |
|---------|-------------|
| `/obos init` | Initialize vault structure |
| `/obos daily` | Create/open today's daily note |
| `/obos weekly` | Generate weekly review |
| `/obos save [type]` | Save conversation insight |
| `/obos sync` | Sync AI index files |
| `/obos quick "text"` | Quick capture a thought |
| `/obos ask "question"` | Search and query your vault |
| `/obos draft "topic"` | Draft content from notes |
| `/obos link [note]` | Suggest links for a note |
| `/obos refine [note]` | Refine a note to evergreen |
| `/obos status` | Vault health dashboard |

## Command Routing

Parse the first argument after `/obos` and load the matching
command file from `commands/`. If no argument, show the command
table and ask what the user wants to do.

## Shared Conventions

### Vault Path Discovery

Determine vault path in this order:
1. Current working directory (if contains CLAUDE.md or .obsidian/)
2. Fallback: `/Users/hansonmei/OneDrive/obsidian-vault/`
3. If neither exists, ask user with AskUserQuestion

### Vault Structure

(保留当前的目录树，约 10 行)

### Knowledge Maturity Model

Notes have a maturity status tracked in frontmatter:

| Status | Meaning | Set by |
|--------|---------|--------|
| `seed` | Raw capture, unprocessed | quick |
| `seedling` | Saved but not deeply processed | save (without guidance) |
| `evergreen` | Fully processed and internalized | save (with guidance), refine |

### Evergreen Note Template

(升级后的模板定义，约 15 行)

### Daily Note Template

(升级后的模板定义，约 12 行)
```

#### 2.2.3 瘦身效果预测

| 指标 | 重构前 | 重构后 | 变化 |
|------|--------|--------|------|
| SKILL.md 行数 | 340 行 | ~90 行 | **-74%** |
| 命令实现细节 | 在 SKILL.md 中重复 | 仅在 commands/ 中 | 消除重复 |
| 新增命令的 SKILL.md 成本 | 每命令 +30 行 | 每命令 +1 行（表格行） | **-97%** |
| 共享约定 | 分散在各处 | 集中在 SKILL.md | 统一管理 |

重构后，新增 6 个命令只需在命令表中增加 6 行，SKILL.md 总量仍控制在 ~100 行。这为未来扩展留出了充足的 token 预算。

### 2.3 命令文件组织

#### 2.3.1 目录结构

重构后的完整文件树：

```
~/.claude/skills/obos/
├── SKILL.md                    # ~90 行，共享约定 + 路由表
└── commands/
    ├── init.md                 # 初始化（优化后 ~160 行）
    ├── daily.md                # 日记（优化后 ~90 行）
    ├── weekly.md               # 周回顾（优化后 ~110 行）
    ├── save.md                 # 保存（优化后 ~150 行）
    ├── sync.md                 # 同步（优化后 ~120 行）
    ├── quick.md                # 快速捕获（新增 ~50 行）
    ├── ask.md                  # 知识检索（新增 ~60 行）
    ├── draft.md                # 内容创作（新增 ~80 行）
    ├── link.md                 # 链接建议（新增 ~70 行）
    ├── refine.md               # 笔记精炼（新增 ~75 行）
    └── status.md               # 仪表盘（新增 ~50 行）
```

**总计**：SKILL.md ~90 行 + 11 个命令文件 ~1015 行。
**单次调用加载量**：~90 行（SKILL.md）+ 50~160 行（单个命令）= **140~250 行**。
**对比重构前**：340 行（SKILL.md）+ 59~143 行（命令）= 399~483 行。
**节省**：每次调用减少约 **40-50%** 的 token 加载量。

#### 2.3.2 命令文件编写规范

每个命令文件应遵循统一结构：

```markdown
# /obos {command}

{一句话描述}

## Usage

{语法和参数说明}

## Behavior

### Step 1: {步骤名}
{具体逻辑}

### Step N: Output
{输出格式}

## Success Message
{成功提示}
```

**关键约定**：
- 不在命令文件中重复 Vault Path Discovery 逻辑，统一写"按 SKILL.md 的 Vault Path Discovery 确定路径"
- 不在命令文件中重复模板定义，统一写"使用 SKILL.md 中的 Evergreen Note Template"
- 每个命令文件自包含其完整行为描述，不依赖其他命令文件

### 2.4 共享逻辑提取

以下是从各命令中提取到 SKILL.md 的共享逻辑清单：

| 共享逻辑 | 当前位置 | 提取后位置 | 行数 |
|----------|---------|-----------|------|
| Vault Path Discovery | SKILL.md + 5 个 commands/ | 仅 SKILL.md | ~6 行 |
| Vault Structure（目录树） | SKILL.md + init.md | 仅 SKILL.md | ~10 行 |
| Knowledge Maturity Model | 不存在（新增） | SKILL.md | ~10 行 |
| Evergreen Note Template | save.md + init.md | SKILL.md（定义）+ commands/（引用） | ~15 行 |
| Daily Note Template | daily.md + init.md | SKILL.md（定义）+ commands/（引用） | ~12 行 |
| 命令路由表 | SKILL.md | SKILL.md（保留） | ~15 行 |

**提取原则**：只有被 3 个以上命令引用的逻辑才放入 SKILL.md。被 1-2 个命令使用的逻辑留在命令文件中。

---

## 三、生态集成设计

### 3.1 现有 Skill 生态概览

扫描 `~/.claude/skills/` 目录，识别出与 obos 存在潜在集成关系的 skill：

| Skill | 与 obos 的关系 | 集成可能性 |
|-------|---------------|-----------|
| `skill-evolution-manager` | obos 自身的迭代优化 | **高** — 直接适用 |
| `brainstorming` | 创意发散 → 捕获到 vault | 中 — 输出可接入 save/quick |
| `writing-skills` | skill 编写规范 | 间接 — 指导 obos 自身开发 |
| `verification-before-completion` | 质量验证 | 低 — obos 非代码项目 |
| `anything-to-notebooklm` | 内容转换 | 中 — vault 内容可导出 |
| `bilibili-subtitle` | 视频字幕提取 | 低 — 字幕可作为 clip 来源 |

### 3.2 与 skill-evolution-manager 的深度集成

`skill-evolution-manager` 是 obos 最重要的生态伙伴。它通过 `evolution.json` + `smart_stitch.py` 机制实现 skill 的持续进化。

**集成方案**：

1. **obos 作为被管理对象**：用户使用 obos 过程中的反馈（如"save 的加工引导问题太多了"）可通过 `/evolve` 沉淀到 obos 的 `evolution.json` 中，自动优化 SKILL.md
2. **evolution.json 的兼容性**：重构后的 SKILL.md 瘦身为 ~90 行，`smart_stitch.py` 追加的 `## User-Learned Best Practices & Constraints` 章节不会造成过度膨胀
3. **命令级反馈**：建议在 `evolution.json` 中按命令分组记录反馈，便于精准优化

```json
{
  "preferences": ["weekly 的引导问题保持 3 个以内"],
  "fixes": ["save meeting 类型需要支持中文参会人名"],
  "per_command": {
    "save": {"preferences": ["--quick 应该是默认模式"]},
    "weekly": {"preferences": ["趋势对比默认关闭"]}
  }
}
```

### 3.3 跨 Skill 工作流集成点

obos 不直接调用其他 skill（框架限制），但可以通过**输出提示**引导用户串联使用：

| 场景 | obos 输出提示 | 目标 Skill |
|------|-------------|-----------|
| save clip 保存了视频笔记 | "来源是 B 站视频？试试 `/bilibili-subtitle` 提取完整字幕" | bilibili-subtitle |
| draft 生成了长文初稿 | "想转为播客？试试 `/anything-to-notebooklm`" | anything-to-notebooklm |
| 对话中产生了新的 skill 改进想法 | "想记录这个改进？试试 `/evolve`" | skill-evolution-manager |

**实现方式**：在相关命令的 Success Message 中增加条件性提示。不增加 SKILL.md 体积，仅在命令文件中添加 1-2 行。

### 3.4 obos 作为其他 Skill 的知识后端

obos 管理的 vault 可以成为其他 skill 的知识来源：

- **brainstorming skill**：头脑风暴结束后，用户可通过 `/obos save` 或 `/obos quick` 将成果存入 vault
- **ask/codex 系列 skill**：与外部 AI 对话后，有价值的结论可通过 `/obos save` 沉淀
- **任何产出型 skill**：产出的文档、报告等可通过 `/obos save clip` 归档到 vault

这种集成是**用户驱动**的（用户主动调用 obos 命令），而非自动化的。这符合方法论中"AI 不替代用户决策"的原则。

---

## 四、实现路线图

### 4.1 Phase 1: 快速见效（架构重构 + 低成本高回报改进）

**目标**：瘦身 SKILL.md、消除重复、实现最简单但最有价值的改进。

**依赖**：无，可立即开始。

#### Step 1.1: SKILL.md 瘦身（最高优先级）

**改动文件**：`~/.claude/skills/obos/SKILL.md`

**具体操作**：
- 删除 SKILL.md 中所有命令的 Steps 区块（约 215 行）
- 保留 frontmatter、命令路由表、Vault Path Discovery、Vault Structure
- 新增 Knowledge Maturity Model 共享约定（~10 行）
- 新增升级后的 Evergreen Note Template（~15 行）
- 新增升级后的 Daily Note Template（~12 行）
- 更新命令路由表为 11 个命令

**预期结果**：SKILL.md 从 340 行降至 ~90 行

#### Step 1.2: 现有命令文件自包含化

**改动文件**：5 个现有 `commands/*.md`

**具体操作**：
- 确保每个命令文件包含完整的行为描述（当前已基本满足）
- 删除各命令文件中重复的 Vault Path Discovery 描述，替换为"按 SKILL.md 的 Vault Path Discovery 确定路径"
- 删除各命令文件中重复的模板定义，替换为"使用 SKILL.md 中的 {模板名}"

**预期结果**：每个命令文件减少约 6-10 行冗余

#### Step 1.3: init 优化

**改动文件**：`commands/init.md`

**具体操作**：
- 增加幂等性检查（已存在的目录/文件跳过）
- 增加交互式引导步骤（AskUserQuestion 填写 CLAUDE.md 的 Key Topics 和 About）
- 增加 Templates/Weekly.md 和 Templates/Meeting.md
- 更新 Success Message 为 checklist 格式
- 引用 SKILL.md 中的升级版模板定义

#### Step 1.4: daily 模板升级 + carry-forward

**改动文件**：`commands/daily.md`

**具体操作**：
- 引用 SKILL.md 中升级后的 Daily Note Template（含 blockquote 引导提问）
- 新增 Step: 读取昨日笔记，提取未完成的 `- [ ]` 项，迁移到今日 Plan
- 新增 Step: 读取最近周报的 Carry Forward 区，在顶部展示本周焦点
- 增加日期参数支持（`yesterday`, `YYYY-MM-DD`）
- 已存在时展示状态摘要（待办完成情况）

#### Step 1.5: save 加工引导 + 成熟度标记

**改动文件**：`commands/save.md`

**具体操作**：
- 在 Step 4（Generate Content）前插入"加工引导"步骤
- 引导步骤使用 AskUserQuestion 提出两个核心问题
- 增加 `--quick` 参数跳过引导（笔记标记为 seedling）
- 所有模板增加 frontmatter `status:` 字段
- 增加 meeting 类型分支和模板
- 保存后增加关联提示（基于 Index.md 标题匹配）

#### Step 1.6: 新增 /obos quick 命令

**新增文件**：`commands/quick.md`

**具体操作**：
- 创建 ~50 行的命令文件
- 参数解析：引号文本直接提取，无参数时从对话上下文提取
- 自动生成简短标题
- 默认存入 Notes/ 并标记 `status: seed`
- 保存后基于 Index.md 提示可能相关的笔记
- 无需用户确认（零摩擦优先）

#### Step 1.7: 新增 /obos status 命令

**新增文件**：`commands/status.md`

**具体操作**：
- 创建 ~50 行的命令文件
- 纯只读操作，不修改任何文件
- 统计各目录文件数、本周新增/修改数
- 扫描 frontmatter 展示成熟度分布（seed/seedling/evergreen）
- 轻量健康指标（孤立笔记数、断链数）
- 展示上次 sync 时间

#### Phase 1 总结

| Step | 改动文件 | 行数变化 |
|------|---------|---------|
| 1.1 SKILL.md 瘦身 | SKILL.md | 340 → ~90 |
| 1.2 命令自包含化 | 5 个 commands/*.md | 各减 6-10 行 |
| 1.3 init 优化 | commands/init.md | 143 → ~160 |
| 1.4 daily 优化 | commands/daily.md | 59 → ~90 |
| 1.5 save 优化 | commands/save.md | 115 → ~150 |
| 1.6 新增 quick | commands/quick.md（新） | +50 |
| 1.7 新增 status | commands/status.md（新） | +50 |

**Phase 1 完成后的系统状态**：
- 7 个可用命令（init, daily, weekly, save, sync, quick, status）
- SKILL.md ~90 行（含成熟度模型和升级模板）
- 知识成熟度追踪已启用
- save 具备加工引导能力
- daily 具备 carry-forward 能力

### 4.2 Phase 2: 核心增强（深度加工 + 连接 + 回顾）

**目标**：填补知识生命周期中"加工"和"连接"阶段的空白，强化回顾机制。

**依赖**：Phase 1 完成（SKILL.md 瘦身 + 成熟度模型就绪）。

#### Step 2.1: 新增 /obos refine 命令

**新增文件**：`commands/refine.md`

**具体操作**：
- 创建 ~75 行的命令文件
- 读取目标笔记（参数指定或从对话推断）
- 提取要点并展示给用户
- 苏格拉底三问交互（复述 → 评判 → 关联），每步使用 AskUserQuestion
- 基于用户回答生成 evergreen note（使用 SKILL.md 中的升级模板）
- 将目标笔记的 status 升级为 evergreen
- 在原笔记中添加指向精炼版的反向链接

#### Step 2.2: 新增 /obos link 命令

**新增文件**：`commands/link.md`

**具体操作**：
- 创建 ~70 行的命令文件
- 单笔记模式（默认）：读取指定笔记 → 提取关键词 → 搜索 vault 匹配 → 建议链接并说明理由
- 全库模式（`/obos link --all`）：扫描所有笔记，列出孤岛笔记，逐一建议
- 用户逐条确认后，自动在笔记的 Related 区插入 `[[wikilink]]`
- 全库模式设置上限（最多处理 10 篇孤岛笔记），避免 token 爆炸

#### Step 2.3: weekly 苏格拉底式改造

**改动文件**：`commands/weekly.md`

**具体操作**：
- 重写交互流程：AI 先展示本周数据概览（事实），再通过 AskUserQuestion 引导用户反思
- 引导问题固定为 3 个：最有价值的收获、下周想改变什么、哪些笔记值得深化
- 最终周报基于用户回答组织，而非 AI 自动生成
- 增加量化统计（待办完成率、笔记产出数）
- 增加周期参数支持（`last`, `YYYY-WNN`）
- Carry Forward 生成 `- [ ]` checkbox 格式

#### Step 2.4: sync 健康检查增强

**改动文件**：`commands/sync.md`

**具体操作**：
- 在 Step 2（Scan Vault）中增加链接图谱构建
- 新增 Step: 孤立笔记检测（无入链且无出链的笔记）
- 新增 Step: 断链检测（wikilink 指向不存在的文件）
- 新增 Step: 成熟度分布统计（扫描 frontmatter status 字段）
- 更新输出格式为结构化健康报告
- CLAUDE.md 的 Current Context 增加知识库结构特征

#### Step 2.5: 新增 /obos ask 命令

**新增文件**：`commands/ask.md`

**具体操作**：
- 创建 ~60 行的命令文件
- 解析用户问题，提取关键词
- 先读 Index.md 定位候选笔记，不足时用 Glob + Grep 扩展
- 最多读取 5 篇最相关笔记全文
- 综合回答，每条引用标注 `[[wikilink]]` 来源
- 若无匹配笔记，提示"知识库中暂无相关内容"

#### Phase 2 总结

| Step | 改动文件 | 行数变化 |
|------|---------|---------|
| 2.1 新增 refine | commands/refine.md（新） | +75 |
| 2.2 新增 link | commands/link.md（新） | +70 |
| 2.3 weekly 改造 | commands/weekly.md | 81 → ~110 |
| 2.4 sync 增强 | commands/sync.md | 87 → ~120 |
| 2.5 新增 ask | commands/ask.md（新） | +60 |

**Phase 2 完成后的系统状态**：
- 10 个可用命令（+refine, link, ask）
- 知识生命周期覆盖：捕获 ★★★★☆ / 加工 ★★★★☆ / 连接 ★★★☆☆ / 创造 ☆☆☆☆☆ / 回顾 ★★★★☆
- 苏格拉底式交互模式在 save、weekly、refine 中全面启用
- vault 健康检查能力就绪

### 4.3 Phase 3: 高级功能（创造 + 生态集成）

**目标**：填补"创造"阶段的空白，完善生态集成。

**依赖**：Phase 2 完成（ask 的搜索逻辑是 draft 的基础）。

#### Step 3.1: 新增 /obos draft 命令

**新增文件**：`commands/draft.md`

**具体操作**：
- 创建 ~80 行的命令文件
- 复用 ask 的搜索逻辑检索相关笔记
- 展示素材笔记列表，用户可增删
- 生成写作大纲（每节标注素材来源）
- 方法论校准：默认生成"框架 + 写作提示"而非完整初稿
- `--assist` 参数可让 AI 为指定章节生成草稿
- 输出到 Notes/ 目录，标题带 `[Draft]` 前缀

#### Step 3.2: 生态集成提示

**改动文件**：`commands/save.md`, `commands/draft.md`

**具体操作**：
- save clip 的 Success Message 中增加条件提示（如来源为视频时提示 bilibili-subtitle）
- draft 的 Success Message 中增加 anything-to-notebooklm 提示
- 各命令的 Success Message 中增加 `/evolve` 提示（当用户表达不满时）

#### Step 3.3: 多周期回顾扩展

**改动文件**：`commands/weekly.md`

**具体操作**：
- 增加月度回顾模式：`/obos weekly --monthly`
- 月度回顾从本月所有周报中提取趋势和模式
- 输出到 `Daily/YYYY-MM-review.md`
- 季度/年度回顾暂不实现，留作远期规划

#### Phase 3 总结

| Step | 改动文件 | 行数变化 |
|------|---------|---------|
| 3.1 新增 draft | commands/draft.md（新） | +80 |
| 3.2 生态集成提示 | save.md, draft.md | 各 +2-3 行 |
| 3.3 多周期回顾 | commands/weekly.md | ~110 → ~130 |

**Phase 3 完成后的系统状态**：
- 11 个可用命令（全部就绪）
- 知识生命周期全覆盖：捕获 ★★★★☆ / 加工 ★★★★☆ / 连接 ★★★☆☆ / 创造 ★★★☆☆ / 回顾 ★★★★★
- 生态集成提示就绪
- 多周期回顾体系建立

### 4.4 路线图总览

```
Phase 1: 快速见效
├── 1.1 SKILL.md 瘦身 ←── 最高优先级，所有后续工作的前提
├── 1.2 命令自包含化 ←── 依赖 1.1
├── 1.3 init 优化
├── 1.4 daily 优化（carry-forward）
├── 1.5 save 优化（加工引导）
├── 1.6 新增 quick
└── 1.7 新增 status

Phase 2: 核心增强
├── 2.1 新增 refine ←── 依赖 1.5（成熟度模型）
├── 2.2 新增 link
├── 2.3 weekly 苏格拉底改造
├── 2.4 sync 健康检查
└── 2.5 新增 ask

Phase 3: 高级功能
├── 3.1 新增 draft ←── 依赖 2.5（ask 的搜索逻辑）
├── 3.2 生态集成提示
└── 3.3 多周期回顾
```

### 4.5 关键依赖关系

```
1.1 SKILL.md 瘦身
 ├──→ 1.2 命令自包含化
 ├──→ 1.3~1.7 所有 Phase 1 改动
 └──→ Phase 2 & 3 全部

1.5 save 加工引导（成熟度模型启用）
 └──→ 2.1 refine（依赖成熟度升级机制）

2.5 ask（搜索逻辑）
 └──→ 3.1 draft（复用搜索逻辑）
```

**无依赖可并行的工作**：
- Phase 1 中：1.3、1.4、1.5、1.6、1.7 互不依赖，可并行实施
- Phase 2 中：2.1、2.2、2.3、2.4 互不依赖，可并行实施（2.5 也可并行，但 draft 依赖它）
