# /obos refine

Socratic note refinement: transform draft notes into refined evergreen notes through guided conversation.

## Usage

```
/obos refine [note]
```

- `note` — filename or wikilink (e.g. `My Note` or `[[My Note]]`)
- If omitted, infer target from current conversation context

## Interaction Mode

This command uses **conversational dialogue (对话式交互)**, NOT AskUserQuestion.
Open-ended text input requires natural conversation turns.

## Behavior

### Step 1: Identify Vault Path

Use **Vault Path Discovery from SKILL.md**:
1. Current working directory (if has CLAUDE.md or `.obsidian/`)
2. Fallback: `/Users/hansonmei/OneDrive/obsidian-vault/`
3. If neither exists, ask user

### Step 2: Read Target Note

- If `[note]` parameter provided, locate file in vault (search `Notes/`, `Daily/`, `Clippings/`)
- If omitted, infer from conversation context
- If not found, list recent draft notes and let user pick

Display the note content to the user.

### Step 3: Extract Key Points

Analyze the note and present a brief summary:
- Main argument or idea
- Supporting points
- Current gaps or ambiguities

### Step 4: Socratic Three Questions

Conduct three conversation turns. Wait for user response after each question.

**Turn 1 — Restate (复述)**:
> 用你自己的话，核心观点是什么？

**Turn 2 — Evaluate (评判)**:
> 你同意吗？有什么保留意见？

**Turn 3 — Connect (关联)**:
> 这和你已有的哪些知识相关？

### Step 5: Generate Refined Evergreen Note

Based on user's three answers, generate a note using the **Evergreen Note Template from SKILL.md**:

```markdown
---
status: refined
source: {original note attribution}
created: {YYYY-MM-DD}
---
# {Title}

## Core Idea
{User's own restatement from Turn 1}

## My Understanding
{User's evaluation from Turn 2}

## Open Questions
{New questions raised during dialogue}

## Related
- [[{connections from Turn 3}]]
- [[{original note backlink}]]
```

### Step 6: Write and Update

1. Write refined note to `Notes/{title}.md`
2. Update frontmatter status to `refined` per **Knowledge Maturity Model from SKILL.md**
3. Add backlink in original note pointing to the new evergreen note
4. Suggest running `/obos sync` to update Index.md

## Success Message

- Refined note created: `Notes/{title}.md`
- Status: draft → refined
- Backlinks: added
- Tip: Run `/obos sync` to update your index
