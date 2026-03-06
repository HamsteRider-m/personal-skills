---
name: obos
description: "Obsidian vault management. Use when user runs /obos commands to manage vault structure, save insights, tidy files, or sync index."
metadata:
  short-description: Obsidian vault management
---

# Obsidian Best Practices (obos)

有主见的 Obsidian vault 管理系统。核心循环：收集 → 整理 → 连接 → 回顾。

## Commands

| Command | Description |
|---------|-------------|
| `/obos save ["内容"]` | 快速收集想法到 Inbox（核心命令） |
| `/obos tidy` | 整理笔记归位（支持 standard/strong 模式） |
| `/obos sync` | 更新索引 + 健康报告 + 链接建议 |
| `/obos review` | Vault 状态回顾 + 下一步建议 |
| `/obos init` | 初始化 vault 结构 |
| `/obos vault` | 管理多个 vault 注册 |
| `/obos refine [note]` | 深度加工笔记（进阶） |
| `/obos ask "question"` | 查询知识库（进阶） |
| `/obos draft "topic"` | 基于笔记起草文章（进阶） |

No argument → show grouped command list:
```
核心：save, tidy, sync, review
设置：init, vault
进阶：refine, ask, draft
```

## Tidy 默认策略

`/obos tidy` 默认按 `standard` 模式运行，并启用幂等增量整理：

- 重复执行时，已整理且未变更的文件会被跳过，不重复迁移
- 自动重命名默认只执行一次；检测到手动改名后自动锁定（`name_locked: true`）
- 项目目录默认 `project-policy=contain`：项目结构冻结，不打散且不改内部层级/文件名
- 通过 `/.obos/tidy-state.json` 与 frontmatter 双重判定稳定性
- 通过 `/.obos/tidy-config.json` 可扩展项目目录白名单（`projectRootsExtra`）
- strong 模式先进行目录必要性评估（KEEP / REORGANIZE / ARCHIVE_DIR）
- 目录评估审计输出到 `/.obos/dir-audit.json`
- 默认不删除 markdown 文档（`deleteMarkdown=false`），仅清理空目录

## Multi-Vault 配置

配置文件：`~/.proma/agent-workspaces/obsidian/obos-config.json`

```json
{
  "vaults": {
    "personal": { "path": "D:/obsidian/personal", "default": true },
    "work": { "path": "C:/Users/.../work-vault" }
  },
  "lastUsedVault": "personal"
}
```

## Vault Path Discovery

所有命令共享此逻辑（按优先级）：

1. 命令参数 `--to <alias>` 指定的 vault
2. obos-config.json 中的 default vault
3. 当前工作目录（如果包含 `.obsidian/` 或 vault CLAUDE.md）
4. 如果以上都不存在，用 AskUserQuestion 引导用户注册 vault

## Vault Structure

```
Vault/
├── CLAUDE.md          # AI context file
├── Index.md           # AI-readable index (auto-generated)
├── Inbox/             # 收集入口（save 写入此处）
├── Notes/             # Evergreen notes
├── Clippings/         # Web clippings
├── References/        # Source materials
├── Attachments/       # Images and files
├── Categories/        # MOC index pages
└── Templates/         # Note templates
```

## Knowledge Maturity Model

Frontmatter `status` 字段：
- `inbox` — 刚收集，未整理
- `draft` — 已分类，未深度加工
- `refined` — 经过 `/obos refine` 深度加工

## Evergreen Note Template

```markdown
---
status: {{inbox|draft|refined}}
source: {{attribution}}
created: {{YYYY-MM-DD}}
---
# {{title}}

## Core Idea
One sentence in your own words.

## My Understanding
Why it matters. What you agree/disagree with.

## Open Questions
What new questions does this raise?

## Related
- [[]]
```

## Command Routing

Parse the first argument after `/obos` and load the matching `commands/{command}.md` file. If no argument, show the grouped command list above and ask what the user wants to do.
