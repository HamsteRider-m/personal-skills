# obos — Obsidian Best Practices

AI-powered Obsidian vault management skill. Opinionated system for reducing entropy in your knowledge vault.

Core loop: **收集 → 整理 → 连接 → 回顾**

## Quick Start

### Install

```bash
git clone https://github.com/HamsteRider-m/obsidian-best-pract.git

# Deploy skill files
cp -r skill/SKILL.md ~/.claude/skills/obos/SKILL.md
cp -r skill/commands/ ~/.claude/skills/obos/commands/
```

### First Run

```
/obos init
```

This initializes your vault structure, creates standard directories, and registers your vault.

## Commands

| Command | Description |
|---------|-------------|
| `/obos save ["内容"]` | Quick capture to Inbox (core command) |
| `/obos tidy` | Organize Inbox + stray files into correct directories |
| `/obos sync` | Update index + health report + link suggestions |
| `/obos review` | Vault status overview + next action suggestion |
| `/obos init` | Initialize vault structure |
| `/obos vault` | Manage multiple vault registrations |
| `/obos refine [note]` | Socratic note refinement (advanced) |
| `/obos ask "question"` | Query your knowledge base (advanced) |
| `/obos draft "topic"` | Writing assist from notes (advanced) |

Commands are grouped by purpose:

```
核心：save, tidy, sync, review
设置：init, vault
进阶：refine, ask, draft
```

## Vault Structure

```
Vault/
├── CLAUDE.md          # AI context file
├── Index.md           # AI-readable index (auto-generated)
├── Inbox/             # Capture inbox (save writes here)
├── Notes/             # Evergreen notes
├── Clippings/         # Web clippings
├── References/        # Source materials
├── Attachments/       # Images and files
├── Categories/        # MOC index pages
└── Templates/         # Note templates
```

## Multi-Vault Support

Register and switch between multiple vaults:

```
/obos vault add personal "D:/obsidian/personal"
/obos vault add work "C:/Users/.../work-vault"
/obos vault default personal
```

All commands support `--to <alias>` to target a specific vault.

## Knowledge Maturity Model

Three-level system tracked in frontmatter `status` field:

| Status | Meaning | Set by |
|--------|---------|--------|
| `inbox` | Just captured, not yet organized | `/obos save` |
| `draft` | Organized into correct directory | `/obos tidy` |
| `refined` | Processed through guided reflection | `/obos refine` |

## Typical Workflows

**Capture an idea anytime**:
```
/obos save "函数式编程的核心不是没有副作用，而是控制副作用的边界"
```

**Organize accumulated notes**:
```
/obos tidy              # AI classifies and moves Inbox files
/obos sync              # update index, suggest links
```

**Check vault health**:
```
/obos review            # status overview + next action
```

**Deep processing (advanced)**:
```
/obos refine [[My Note]]              # Socratic refinement
/obos ask "What do I know about X?"   # query knowledge base
/obos draft "Topic"                    # generate outline from notes
```

## Testing

```bash
bash tests/run.sh
bash tests/run.sh save    # run a specific command's tests
```

## License

MIT
