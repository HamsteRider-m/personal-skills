# Deep Learning Workflow

Complete step-by-step process for orchestrating deep learning tasks.

## Phase 1: Material Collection (1-5 minutes)

### Step 1.1: Identify Content Type

Analyze user input to determine source type:

| Input Pattern | Content Type | Handler |
|--------------|--------------|---------|
| `mp.weixin.qq.com` | WeChat article | `anything-to-notebooklm` (MCP) |
| `youtube.com`, `youtu.be` | YouTube video | `anything-to-notebooklm` |
| `bilibili.com`, `BV*` | Bilibili video | `bilibili-subtitle` |
| `http://`, `https://` | Web article | `jina-reader` or `web_fetch` |
| File path (`.pdf`, `.docx`, etc.) | Document | `anything-to-notebooklm` |
| Plain text (no URL) | Search keyword | `ultimate-search` + NotebookLM research |

### Step 1.2: Collect Materials

**For URLs/files:**
```bash
# Use anything-to-notebooklm or specific handlers
# Output: cleaned markdown/text content
```

**For keywords:**
```bash
# 1. Search with ultimate-search
~/.openclaw/skills/ultimate-search/scripts/dual-search.sh --query "keyword"

# 2. Extract top 3-5 URLs from results
# 3. Fetch each URL with jina-reader
```

### Step 1.3: Create Notebook

```bash
notebooklm create "深度学习：[主题]" --json
# Parse notebook_id from output
```

### Step 1.4: Upload Sources

```bash
# For each material:
notebooklm source add [URL or file path] --json -n [notebook_id]
# Parse source_id from each output
```

### Step 1.5: Wait for Processing

**Spawn subagent** to wait for all sources:
```
Task: "Wait for sources [source_ids] in notebook [notebook_id] to be ready.
       For each: notebooklm source wait [id] -n [notebook_id] --timeout 600
       Report when all ready or if any fail."
```

## Phase 2: Knowledge Synthesis (Optional, 2-30 minutes)

**For open-ended topics** (keywords without specific sources):

```bash
notebooklm source add-research "[topic]" --mode deep --no-wait -n [notebook_id]
```

**Spawn subagent** to wait and import:
```
Task: "Wait for research in notebook [notebook_id] to complete.
       Use: notebooklm research wait -n [notebook_id] --import-all --timeout 1800
       Report source count when done."
```

## Phase 3: Artifact Generation (5-45 minutes, parallel)

Generate all artifacts simultaneously:

```bash
# Report (fastest, 5-15 min)
notebooklm generate report --format study-guide -n [notebook_id] --json

# Podcast (10-20 min)
notebooklm generate audio --format deep-dive --length default -n [notebook_id] --json

# Slides (15-30 min)
notebooklm generate slide-deck --format detailed -n [notebook_id] --json

# Mind map (instant)
notebooklm generate mind-map -n [notebook_id] --json

# Quiz (5-15 min)
notebooklm generate quiz --difficulty medium -n [notebook_id] --json
```

**Parse artifact IDs** from each `--json` output.

**Spawn subagent** for each artifact:
```
Task: "Wait for artifact [artifact_id] in notebook [notebook_id].
       Use: notebooklm artifact wait [artifact_id] -n [notebook_id] --timeout 2700
       Then download to: ~/.openclaw/workspace/deep-learning-output/[notebook_id]/
       Report when complete."
```

## Phase 4: Delivery (1-2 minutes)

### Step 4.1: Download Artifacts

```bash
# Audio
notebooklm download audio ./podcast.mp3 -a [audio_artifact_id] -n [notebook_id]

# Slides (PDF)
notebooklm download slide-deck ./slides.pdf -a [slide_artifact_id] -n [notebook_id]

# Report
notebooklm download report ./report.md -a [report_artifact_id] -n [notebook_id]

# Mind map
notebooklm download mind-map ./mindmap.json -a [mindmap_artifact_id] -n [notebook_id]

# Quiz
notebooklm download quiz ./quiz.json -a [quiz_artifact_id] -n [notebook_id]
```

### Step 4.2: Send to User

**Via Feishu:**

1. Upload files as attachments
2. Send summary message with links
3. Format quiz questions as interactive card (if supported)

**Message template:**
```
✅ 深度学习完成：[主题]

📚 学习材料：[source_count] 个来源
📊 生成产物：
- 📄 学习指南报告
- 🎙️ 深度播客 ([duration])
- 📊 PPT 讲义 ([slide_count] 页)
- 🗺️ 思维导图
- ❓ 测试题 ([question_count] 题)

NotebookLM 链接：[notebook_url]
```

## Error Recovery

**Source processing fails:**
- Log warning, continue with successful sources
- Minimum 1 source required to proceed

**Artifact generation fails:**
- Retry once after 5 minutes
- If still fails, skip that artifact and continue
- Report which artifacts succeeded/failed

**Rate limiting:**
- Wait 10 minutes, retry once
- If persistent, suggest manual retry later

## Time Estimates

| Phase | Typical Duration |
|-------|-----------------|
| Material collection | 1-5 min |
| Source processing | 2-10 min |
| Research (if needed) | 2-30 min |
| Report generation | 5-15 min |
| Podcast generation | 10-20 min |
| Slide generation | 15-30 min |
| Mind map | instant |
| Quiz generation | 5-15 min |
| Download & send | 1-2 min |

**Total: 10-60 minutes** (most work happens in parallel via subagents)
