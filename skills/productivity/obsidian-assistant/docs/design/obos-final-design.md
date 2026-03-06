# obos 最终设计方案

> 综合 Epistemologist、Workflow Designer、Skill Architect、Critic 四份文档
> 生成日期：2026-02-08
> 状态：待用户审核，审核通过后进入实施阶段

---

## 〇、设计原则

在综合四份文档后，确立以下不可妥协的设计原则：

1. **快速优先，深度可选**：每个命令的默认行为是最快路径。深度功能通过参数触发，而非默认启用。
2. **AI 问问题，不给答案**：苏格拉底原则作为可选增强，不作为默认行为。
3. **删繁就简**：用户端保持简单，复杂逻辑后端化。
4. **存入 ≠ 学到**：系统应提供加工路径，但不强制用户走完。

## 一、核心诊断

### 1.1 现状问题

obos 当前是一个 **捕获偏重型** 系统。知识生命周期五阶段的覆盖度：

| 阶段 | 覆盖度 | 对应命令 |
|------|--------|----------|
| 捕获 | ★★★☆☆ | daily, save |
| 加工 | ★☆☆☆☆ | （无） |
| 连接 | ★★☆☆☆ | sync（仅索引） |
| 创造 | ☆☆☆☆☆ | （无） |
| 回顾 | ★★☆☆☆ | weekly |

### 1.2 技术债务

SKILL.md 当前 340 行，其中 63%（~215 行）是与 commands/ 文件的重复内容。每次调用都加载全部命令逻辑，严重浪费 token。

---

## 二、命令体系设计（采纳 Critic 精简建议：9 个命令）

Critic 指出 `quick` 与 `save` 高度重叠、`status` 与 `sync` 重叠。采纳精简建议，从 11 个命令精简为 **9 个**。

### 2.1 最终命令列表

| 命令 | 一句话描述 | 生命周期阶段 | 状态 |
|------|-----------|-------------|------|
| `/obos init` | 初始化 vault 结构 + 交互引导 | 基础设施 | 优化 |
| `/obos daily [date]` | 创建/打开日记，carry-forward | 捕获 | 优化 |
| `/obos save [type]` | 保存对话洞察（默认快速，`--deep` 触发引导） | 捕获+加工 | 优化 |
| `/obos weekly [range]` | 生成周报（默认生成，`--reflect` 触发反思引导） | 回顾 | 优化 |
| `/obos sync` | 同步索引 + 健康报告 + 状态仪表盘 | 维护 | 优化 |
| `/obos refine [note]` | 苏格拉底式笔记精炼（seed → evergreen） | 加工 | **新增** |
| `/obos ask "question"` | 向知识库提问 | 检索 | **新增** |
| `/obos link [note]` | 智能链接建议 | 连接 | **新增** |
| `/obos draft "topic"` | 基于笔记的写作辅助 | 创造 | **新增** |

### 2.2 被合并的命令

| 原命令 | 合并到 | 方式 |
|--------|--------|------|
| `quick` | `save` | `save` 无参数时检测内容长度，短内容自动进入快速模式（零确认） |
| `status` | `sync` | `sync --status` 只读模式，不修改文件只展示仪表盘 |

### 2.3 命令分层展示

`/obos` 无参数时按场景分组展示（解决 Critic 指出的命令发现性问题）：

```
记录：daily, save
加工：refine, link
产出：ask, draft
维护：sync, weekly
设置：init
```

---

## 三、各命令详细设计

### 3.1 /obos init（优化）

**变更摘要**：增加幂等性 + 交互式引导 + 已有 vault 适配

**关键设计决策**：

| 决策点 | 方案 | 依据 |
|--------|------|------|
| 已有 vault 怎么办？ | 扫描已有目录结构，建议映射关系 | Critic M4：迁移场景缺失 |
| CLAUDE.md 占位符 | 交互式引导填写（AskUserQuestion） | Epistemologist：知识管理契约 |
| 重复执行 | 幂等：已存在跳过，缺失补建 | Workflow Designer |

**交互流程**：
1. 检测 vault 路径
2. 扫描已有结构（如发现 `Journal/` 提示映射到 `Daily/`）
3. 创建缺失目录，跳过已有目录
4. 生成 CLAUDE.md（如已存在则不覆盖）
5. AskUserQuestion 引导填写：vault 用途、关注领域（2-3 个）
6. 输出 checklist 格式结果

### 3.2 /obos daily [date]（优化）

**变更摘要**：carry-forward + 认知引导模板 + 日期参数

**关键设计决策**：

| 决策点 | 方案 | 依据 |
|--------|------|------|
| 昨日未完成项 | 自动扫描昨日 `- [ ]` 项迁移到今日 Plan | Workflow Designer：晨间规划痛点 |
| 模板引导 | blockquote 格式提问，不影响用户书写 | Epistemologist：提示效应 |
| 日期参数 | 支持 `yesterday`、`YYYY-MM-DD` | Workflow Designer |

**升级后的 Daily 模板**（放入 SKILL.md 共享区）：
```markdown
# {{date}}

## Plan
> 今天最重要的一件事是什么？
-

## Log
-

## Thoughts
> 今天学到了什么？改变了什么看法？

## Meetings
```

### 3.3 /obos save [type]（优化，合并 quick）

**变更摘要**：合并 quick + 成熟度标记 + 可选深度引导 + meeting 类型

**关键设计决策（含 Critic 修正）**：

| 决策点 | 方案 | 依据 |
|--------|------|------|
| 苏格拉底引导默认开还是关？ | **默认关**，`--deep` 触发 | Critic M1：默认开启会劝退用户 |
| 快速捕获 | 短内容自动零确认保存，合并原 quick | Critic N1：quick 独立性不足 |
| 成熟度模型 | **两级**：`draft` / `refined` | Critic N3：三级增加认知负担 |
| 类型与成熟度的关系 | 解耦为两个独立维度 | Critic M2：避免 `save evergreen --quick` 的歧义 |

**两个维度解耦**：
- **类型**（存到哪）：`evergreen`、`daily`、`clip`、`meeting` — 决定文件路径和模板
- **成熟度**（加工程度）：`draft`（未经深度加工）、`refined`（经过引导或 refine） — 记录在 frontmatter

**交互流程**：
1. 提取对话洞察
2. 自动检测类型（或用户指定）
3. **默认路径**：展示预览 → 用户确认 → 写入（status: draft）
4. **`--deep` 路径**：展示预览 → 对话式引导（用自己的话复述、与已有知识的关系）→ 写入（status: refined）
5. 保存后提示可能相关的已有笔记

### 3.4 /obos weekly [range]（优化）

**变更摘要**：量化统计 + 可选反思引导 + 灵活周期

**关键设计决策（含 Critic 修正）**：

| 决策点 | 方案 | 依据 |
|--------|------|------|
| 苏格拉底引导 | **默认生成周报**，`--reflect` 触发反思引导 | Critic M1 |
| 交互方式 | 反思引导用对话轮次（非 AskUserQuestion） | Critic M5：开放式文本需要对话式交互 |
| Phase 优先级 | 反思引导放 Phase 1（非 Phase 2） | Critic M3：核心设计哲学应优先 |

**默认模式**：AI 读取本周日记 → 自动生成周报（Highlights/Insights/Patterns/Carry Forward + 量化统计）

**`--reflect` 模式**：AI 展示本周数据概览 → 对话式引导 3 个问题 → 基于用户回答组织周报

**参数**：`last`（上周）、`YYYY-WNN`（指定周）、`--monthly`（月度，Phase 3）

### 3.5 /obos sync（优化，合并 status）

**变更摘要**：健康检查 + 仪表盘模式 + CLAUDE.md 边界保护

**关键设计决策**：

| 决策点 | 方案 | 依据 |
|--------|------|------|
| status 合并 | `sync --status` 只读模式 | Critic N1 |
| CLAUDE.md 保护 | 只修改 `## Current Context` 区块 | Critic N5 |
| 大型 vault | Index.md 索引最近 50 篇（非 20 篇），全库扫描设上限 | Critic §3.2 |

**默认模式**：扫描 vault → 更新 Index.md + CLAUDE.md → 输出健康报告（孤立笔记、断链、成熟度分布）

**`--status` 模式**：只读扫描 → 输出仪表盘（不修改任何文件）

### 3.6 /obos refine [note]（新增）

**定位**：方法论价值最高、技术风险最低的新命令。将粗笔记精炼为 evergreen note。

**交互方式**：对话式（非 AskUserQuestion），因为需要开放式文本输入。

**流程**：
1. 读取目标笔记（参数指定或从对话推断）
2. 提取要点并展示
3. 苏格拉底三问（对话轮次）：
   - 复述："用你自己的话，核心观点是什么？"
   - 评判："你同意吗？有什么保留意见？"
   - 关联："这和你已有的哪些知识相关？"
4. 基于用户回答生成 evergreen note（升级模板）
5. 标记 status: refined，添加反向链接

### 3.7 /obos ask "question"（新增）

**定位**：填补知识检索的完全空白（当前覆盖度 0%）。

**已知限制**（Critic 指出）：基于关键词匹配 + AI 语义理解，非真正的语义搜索。对精确查询效果好，模糊查询效果不可预测。

**流程**：
1. 解析问题，提取关键词
2. 先读 Index.md 定位候选 → 不足时 Glob + Grep 扩展
3. 最多读取 5 篇最相关笔记全文
4. 综合回答，每条引用标注 `[[wikilink]]` 来源
5. 无匹配时优雅降级："知识库中暂无相关内容"

### 3.8 /obos link [note]（新增）

**定位**：降低手动链接成本，释放知识网络效应。

**模式**：
- **单笔记模式**（默认）：分析指定笔记 → 建议链接并说明理由 → 用户逐条确认
- **全库模式**（`--all`）：扫描孤岛笔记，最多处理 10 篇，避免 token 爆炸

**关键设计**：建议链接时附带理由（Epistemologist 要求），促进用户认知判断。

### 3.9 /obos draft "topic"（新增，Phase 3）

**定位**：基于笔记的写作辅助，填补创造阶段空白。

**关键设计决策（含 Critic 修正）**：

| 决策点 | 方案 | 依据 |
|--------|------|------|
| 代写 vs 辅助 | **默认输出框架 + 写作提示**，`--assist` 可让 AI 生成某节草稿 | Critic §1.1：draft 定位冲突 |
| 默认模式 | `--outline` 仅大纲 | Skill Architect：token 消耗最高的命令 |

**流程**：
1. 检索相关笔记（复用 ask 的搜索逻辑）
2. 展示素材列表，用户可增删
3. 生成大纲（每节标注素材来源 + 写作提示）
4. 用户自己写，`--assist` 可选让 AI 辅助某节

---

## 四、共享机制设计

### 4.1 知识成熟度模型（两级制）

采纳 Critic 建议，从三级简化为两级：

| 状态 | 含义 | 设置时机 |
|------|------|----------|
| `draft` | 未经深度加工的笔记 | save 默认、快速捕获 |
| `refined` | 经过引导或 refine 处理 | save --deep、refine 完成 |

实现方式：笔记 frontmatter 中 `status: draft|refined`。

### 4.2 升级后的 Evergreen Note 模板

```markdown
---
status: {{draft|refined}}
source: {{来源归属}}
created: {{YYYY-MM-DD}}
---
# {{title}}

## Core Idea
用自己的话，一句话表述

## My Understanding
为什么重要？同意/不同意什么？

## Open Questions
引发了什么新问题？

## Related
- [[]]
```

---

## 五、技术架构

### 5.1 SKILL.md 瘦身方案

**核心决策**：SKILL.md 只保留"路由表 + 共享约定"，所有命令实现细节移入 commands/ 文件。

| 指标 | 重构前 | 重构后 |
|------|--------|--------|
| SKILL.md 行数 | 340 行 | ~90 行 |
| 重复内容 | 63% | 0% |
| 新增命令的 SKILL.md 成本 | +30 行/命令 | +1 行/命令 |
| 单次调用 token 加载 | 399~483 行 | 140~250 行 |

### 5.2 重构后文件结构

```
~/.claude/skills/obos/
├── SKILL.md              # ~90 行：路由表 + 共享约定
└── commands/
    ├── init.md           # ~160 行
    ├── daily.md          # ~90 行
    ├── save.md           # ~150 行
    ├── weekly.md         # ~110 行
    ├── sync.md           # ~120 行
    ├── refine.md         # ~75 行（新增）
    ├── ask.md            # ~60 行（新增）
    ├── link.md           # ~70 行（新增）
    └── draft.md          # ~80 行（新增）
```

### 5.3 命令文件编写规范

- 不重复 Vault Path Discovery，统一写"按 SKILL.md 的 Vault Path Discovery 确定路径"
- 不重复模板定义，统一写"使用 SKILL.md 中的 {模板名}"
- 每个命令文件自包含完整行为描述，不依赖其他命令文件

---

## 六、实现路线图（含 Critic 修正）

### 6.1 Phase 1：快速见效

**目标**：瘦身 SKILL.md + 让现有命令更好用 + 加入 refine 和 ask

**Critic 修正**：Phase 1 只加 `refine`（方法论核心）和 `ask`（填补真空），其余新命令留到用户反馈验证需求后再实现。weekly 的 `--reflect` 模式也放入 Phase 1（Critic M3）。

| Step | 内容 | 改动文件 |
|------|------|---------|
| 1.1 | SKILL.md 瘦身（340→~90 行） | SKILL.md |
| 1.2 | 命令文件自包含化，消除重复引用 | 5 个 commands/*.md |
| 1.3 | init 优化：幂等性 + 已有 vault 检测 + 交互引导 | commands/init.md |
| 1.4 | daily 优化：carry-forward + 认知引导模板 + 日期参数 | commands/daily.md |
| 1.5 | save 优化：成熟度标记 + `--deep` 引导 + meeting 类型 | commands/save.md |
| 1.6 | weekly 优化：量化统计 + `--reflect` 引导 + 灵活周期 | commands/weekly.md |
| 1.7 | sync 优化：健康检查 + `--status` 仪表盘 | commands/sync.md |
| 1.8 | 新增 refine | commands/refine.md |
| 1.9 | 新增 ask | commands/ask.md |

**可并行**：1.3~1.9 互不依赖，可并行实施（均依赖 1.1+1.2 先完成）

### 6.2 Phase 2：连接与维护

**目标**：填补"连接"阶段空白，强化维护能力。

**依赖**：Phase 1 完成。

| Step | 内容 | 改动文件 |
|------|------|---------|
| 2.1 | 新增 link | commands/link.md |
| 2.2 | sync 增强：孤立笔记检测 + 断链检测 | commands/sync.md |
| 2.3 | 趋势对比（weekly 读取上周周报对比） | commands/weekly.md |

### 6.3 Phase 3：创造与生态

**目标**：填补"创造"阶段空白，完善多周期回顾。

**依赖**：Phase 2 中 ask 的搜索逻辑是 draft 的基础。

| Step | 内容 | 改动文件 |
|------|------|---------|
| 3.1 | 新增 draft（默认大纲+写作提示，`--assist` 可选 AI 辅助） | commands/draft.md |
| 3.2 | 月度回顾模式（`weekly --monthly`） | commands/weekly.md |

**注**：采纳 Critic 建议，砍掉原 Phase 3 的"生态集成提示"（Step 3.2），因为提示级别的集成价值低、增加输出噪声。

### 6.4 关键依赖关系

```
1.1 SKILL.md 瘦身
 ├──→ 1.2 命令自包含化
 ├──→ 1.3~1.9 所有 Phase 1 改动
 └──→ Phase 2 & 3 全部

1.5 save 优化（成熟度模型启用）
 └──→ 1.8 refine（依赖成熟度升级机制）

1.9 ask（搜索逻辑）
 └──→ 3.1 draft（复用搜索逻辑）
```

**无依赖可并行**：
- Phase 1：1.3、1.4、1.5、1.6、1.7、1.8、1.9 互不依赖
- Phase 2：2.1、2.2、2.3 互不依赖

---

## 七、已知限制与可接受的取舍

以下问题确实存在，但在当前阶段是合理的妥协：

| # | 问题 | 为什么可以接受 |
|---|------|--------------:|
| A1 | ask 的检索质量依赖关键词匹配 | Claude 的语义理解能力可部分弥补文本搜索的局限。先上线再迭代 |
| A2 | draft 的 `--assist` 模式本质是代写 | 默认模式是"框架+提示"，`--assist` 作为可选项是合理的用户选择权 |
| A3 | 大型 vault 性能未做定量分析 | Phase 1 目标用户大概率是中小型 vault（<200 篇）。性能问题可在用户反馈后针对性优化 |
| A4 | 多语言支持缺失 | obos 当前目标用户明确，多语言是远期需求。模板语言可在 init 时配置 |
| A5 | 方法论框架过于学术化 | 理论深度对设计决策有指导价值，最终文档已精简为可操作的设计方案 |

### 补充限制说明

- **Obsidian 插件兼容性**：obos 未考虑与 Templater、Dataview、Daily Notes 核心插件的潜在冲突。建议 `init` 时检测 `.obsidian/plugins/` 目录，发现已启用的 Daily Notes 插件时提示用户。
- **Token 预算的会话级累积**：当前分析只考虑单次调用，未考虑一次会话中连续使用多个命令的累积消耗。典型晨间工作流（sync → daily）约加载 ~300 行，在可接受范围内。
- **sync 更新 CLAUDE.md 的边界保护**：已在 3.5 节明确只修改 `## Current Context` 区块，不触碰用户手动编辑的内容。

---

## 八、验证清单

### 8.1 四个改进方向覆盖度

| 改进方向 | 覆盖情况 | 对应章节 |
|----------|----------|----------|
| 优化现有命令 | ✓ 5 个命令全部优化 | 三§3.1~3.5 |
| 新增子命令 | ✓ 4 个新命令（refine, ask, link, draft） | 三§3.6~3.9 |
| 融入方法论 | ✓ 成熟度模型、苏格拉底原则（可选增强） | 四§4.1~4.2 |
| 生态集成 | ✓ skill-evolution-manager 协同（命令级反馈） | 五§5.1 注 |

### 8.2 Critic 必须修正项处理情况

| # | 问题 | 处理方式 | 对应章节 |
|---|------|----------|----------|
| M1 | 苏格拉底引导默认开启会劝退用户 | ✓ 已反转：默认快速，`--deep`/`--reflect` 触发 | 〇§1, 三§3.3/3.4 |
| M2 | save 类型与成熟度标记冲突 | ✓ 已解耦为两个独立维度（类型 vs 成熟度） | 三§3.3 |
| M3 | weekly 苏格拉底改造被错误排到 Phase 2 | ✓ `--reflect` 模式已纳入 Phase 1 | 六§6.1 Step 1.6 |
| M4 | 已有 vault 迁移场景缺失 | ✓ init 增加已有结构扫描和目录映射 | 三§3.1 |
| M5 | AskUserQuestion 不支持开放式文本 | ✓ 区分选项式（AskUserQuestion）和对话式交互 | 三§3.4/3.6 |

### 8.3 设计原则验证

| 原则 | 验证 |
|------|------|
| 快速优先，深度可选 | ✓ 所有命令默认走最快路径，深度功能通过参数触发 |
| AI 问问题，不给答案 | ✓ 苏格拉底原则作为可选增强（`--deep`、`--reflect`），不作为默认 |
| 删繁就简 | ✓ 11→9 命令，3→2 级成熟度，SKILL.md 340→~90 行 |
| 存入 ≠ 学到 | ✓ refine 命令提供加工路径，save 的 `--deep` 提供可选引导 |

### 8.4 知识生命周期覆盖度对比

| 阶段 | 重构前 | Phase 1 后 | 全部完成后 |
|------|--------|-----------|-----------|
| 捕获 | ★★★☆☆ | ★★★★☆ | ★★★★☆ |
| 加工 | ★☆☆☆☆ | ★★★☆☆ | ★★★★☆ |
| 连接 | ★★☆☆☆ | ★★☆☆☆ | ★★★☆☆ |
| 创造 | ☆☆☆☆☆ | ☆☆☆☆☆ | ★★★☆☆ |
| 回顾 | ★★☆☆☆ | ★★★★☆ | ★★★★★ |

---

## 九、参考文档索引

本方案综合以下四份设计文档：

| 文档 | 角色 | 路径 |
|------|------|------|
| 方法论框架 + 命令审计 | Epistemologist | `~/Downloads/obos-design-epistemologist.md` |
| 场景地图 + 工作流设计 | Workflow Designer | `~/Downloads/obos-design-workflow.md` |
| 技术架构 + 实现路线图 | Skill Architect | `~/Downloads/obos-design-architecture.md` |
| 批判性审查 | Critic | `~/Downloads/obos-design-critique.md` |
