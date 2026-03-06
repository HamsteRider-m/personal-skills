# /obos draft "topic"

Writing assist: generate outlines and drafts based on your existing notes.

## Usage

```
/obos draft "topic"             # generate outline with writing prompts
/obos draft "topic" --assist    # AI generates draft sections
```

## Parameters

| Param | Description |
|-------|-------------|
| `"topic"` | The writing topic or title (required) |
| `--assist` | Let AI generate prose for selected sections |

## Vault Path Discovery

Use **Vault Path Discovery from SKILL.md** to determine vault root.

## Behavior

### Step 1: Search Related Notes

Reuse the search logic from `/obos ask`:

1. Extract keywords from the topic
2. Read `Index.md` to locate candidate notes
3. If fewer than 3 candidates, expand with Glob + Grep across `Notes/`, `Clippings/`, `References/`
4. Rank by relevance (title match > content match > category match)
5. Read up to 5 most relevant notes in full

### Step 2: Present Source Materials

Display found materials for user review:

```
找到以下相关素材：

1. [[Note A]] - {brief summary, why relevant}
2. [[Note B]] - {brief summary, why relevant}
3. [[Note C]] - {brief summary, why relevant}

是否需要增删素材？
```

Use AskUserQuestion:
- "继续生成大纲" (Recommended)
- "增加素材" — user specifies additional notes to include
- "移除素材" — user picks notes to exclude

### Step 3: Generate Outline (Default Mode)

Create a structured outline with writing prompts for each section:

```markdown
# {Topic}

## 1. {Section Title}
> 素材来源：[[Note A]]
> 写作提示：{what to cover, key argument to develop}

## 2. {Section Title}
> 素材来源：[[Note B]], [[Note C]]
> 写作提示：{what to cover, how sources connect}

## 3. {Section Title}
> 素材来源：[[Note A]]
> 写作提示：{what to cover, open questions to address}

## Conclusion
> 写作提示：{how to tie sections together, key takeaway}
```

Each section includes:
- A clear heading
- Source attribution (`素材来源`) with `[[wikilinks]]`
- A writing prompt (`写作提示`) guiding what to write

### Step 4: Assist Mode (`--assist`)

When `--assist` is provided, after generating the outline:

1. Ask user which section(s) to draft via AskUserQuestion
   - List section titles as options
   - Allow multiple selection
2. For each selected section, generate prose:
   - Draw from the source notes' content
   - Maintain the user's voice (match style of existing notes)
   - Mark AI-generated content clearly:
     ```
     <!-- AI-assisted draft — review and revise -->
     ```
3. Present the draft for user review before writing to file

### Step 5: Save Draft

Write the outline (or outline + drafted sections) to `Notes/{topic}.md`:

```markdown
---
status: draft
source: draft from vault notes
created: {YYYY-MM-DD}
---
# {Topic}

{outline or drafted content}

## Sources
- [[Note A]] - {contribution}
- [[Note B]] - {contribution}
```

## Success Message

- Draft outline created: `Notes/{topic}.md`
- Sections: {count}
- Source notes used: {count}
- Status: draft
- Tip: Use `--assist` to generate prose for specific sections, then `/obos refine` when ready
