# /obos ask "question"

Query your knowledge base using keyword search and AI synthesis.

## Usage

```
/obos ask "question"
```

## Vault Path Discovery

Resolve vault location per shared logic in SKILL.md:
1. Current working directory (if has CLAUDE.md or .obsidian/)
2. Fallback path
3. Ask user

## Behavior

### Step 1: Parse Question

Extract keywords and key phrases from the user's question.
Identify the core intent: factual lookup, conceptual exploration, or cross-reference.

### Step 2: Search Index.md

Read `Index.md` at vault root to locate candidate notes.
Scan the Recent Notes table and Categories section for keyword matches.

If Index.md yields fewer than 3 candidates, expand search:
- Use Glob to scan `Notes/`, `Clippings/`, `References/` for filename matches
- Use Grep to search file contents for keyword hits

Rank candidates by relevance (title match > content match > category match).

### Step 3: Read Top Notes

Read up to 5 most relevant notes in full.
Extract key passages that address the question.

### Step 4: Synthesize Answer

Compose a concise answer that:
- Directly addresses the question
- Cites each source with `[[wikilink]]` notation
- Distinguishes between direct quotes and paraphrased content

Format:

```
{answer text} ([[Source Note 1]], [[Source Note 2]])

**Sources**:
- [[Source Note 1]] - {why relevant}
- [[Source Note 2]] - {why relevant}
```

### Step 5: No Match Handling

If no relevant notes are found, respond with graceful degradation:

> 知识库中暂无相关内容。

Suggest next steps:
- Rephrase the question with different keywords
- Use `/obos save` to capture new knowledge on this topic
- Use `/obos sync` to ensure Index.md is up to date
