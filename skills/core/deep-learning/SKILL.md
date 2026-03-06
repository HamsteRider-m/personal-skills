---
name: deep-learning
description: Orchestrate deep learning workflows using NotebookLM. Triggers when user wants to deeply understand a topic, research a concept, or learn from materials (links, videos, documents, keywords). Automatically collects materials, uploads to NotebookLM, generates multi-format artifacts (report/podcast/slides/video/quiz/flashcards), and delivers all via Feishu.
---

# Deep Learning Orchestrator (Enhanced)

Automated deep learning workflow using NotebookLM as the core engine. Handles material collection, knowledge synthesis, and multi-format artifact generation with intelligent intent detection.

## 🎯 Quick Start

**User provides a topic or materials:**
```
"Help me deeply understand Kubernetes architecture"
"Research this article: https://..."
"Learn from this video: https://youtube.com/..."
"帮我学习 Rust 内存安全"
"总结一下这篇文章的核心观点"
```

**Auto-executed workflow:**
1. Detect learning intent from context and keywords
2. Collect materials (via `jina-reader`, `bilibili-subtitle`, `ultimate-search`, etc.)
3. Create NotebookLM notebook and upload sources
4. Generate all artifacts in parallel (report, podcast, slides, video, quiz, flashcards)
5. Download and send to user via Feishu + save to Obsidian

## 🏗️ Architecture

**deep-learning 是 orchestrator，不是 all-in-one：**

```
deep-learning (orchestrator)
    ↓
content-bridge (内容摄取统一入口)
    ↓
独立摄取 skills (weixin/bilibili/youtube/web/document)
    ↓
NotebookLM (知识合成引擎)
    ↓
多格式产物 (report/podcast/slides/quiz)
```

## 📦 Dependencies

- `content-bridge`: 内容摄取路由层
- `bilibili-subtitle`: B站字幕提取（通过 content-bridge 调用）
- `notebooklm-py`: NotebookLM CLI
- `ultimate-search`: 网络搜索（可选）

## 🔥 Trigger System

### Explicit Triggers
- "帮我学习 X", "深入了解 X", "研究一下 X"
- "深度学习 X", "全面了解 X", "系统学习 X"

### Implicit Triggers
- "总结一下", "听不懂", "解释一下"
- "教程", "入门", "指南"
- User shares long article/URL then asks questions

**When detected:** Ask "是否需要深度学习？我可以生成报告、播客、PPT、测试题等。"

## 📦 Material Collection

**Supported sources:**
| Source Type | Handler | Auto-Detection |
|-------------|---------|----------------|
| Web articles | `jina-reader` | https:// URLs |
| YouTube videos | `anything-to-notebooklm` | youtube.com, youtu.be |
| Bilibili videos | `bilibili-subtitle` | bilibili.com, BV* |
| X/Twitter posts | `jina-reader` | x.com, twitter.com |
| Reddit posts | `jina-reader` | reddit.com |
| Medium articles | `jina-reader` | medium.com |
| LinkedIn posts | `jina-reader` | linkedin.com |
| Documents (PDF/DOCX) | `anything-to-notebooklm` | File paths |
| Search keywords | `ultimate-search` + NotebookLM research | Plain text |

**Social media handling:** All social platform links automatically processed via jina-reader for clean extraction.

## 🎨 Artifact Generation

### Default Artifacts (Always Generated)
- 📄 **Study Guide Report** (5-15 min) - Comprehensive learning guide
- 🎙️ **Audio Podcast** (10-20 min) - Deep-dive audio discussion
- 📊 **Slide Deck** (15-30 min) - Detailed presentation (PDF)
- 🗺️ **Mind Map** (instant) - Visual knowledge structure
- ❓ **Quiz** (5-15 min) - Medium difficulty test questions

### Optional Artifacts (Configurable)
- 🎬 **Video Brief** (10-20 min) - Narrated slideshow video (MP4)
- 📊 **Infographic** (5-10 min) - Visual summary (PNG)
- 🃏 **Flashcards** (5-10 min) - Memory aid cards (JSON)

### Research Modes
| Mode | Duration | Use Case |
|------|----------|----------|
| **Fast Research** | 10-20 seconds | Quick multi-angle source collection |
| **Deep Research** | 2-30 minutes | Comprehensive single-topic deep dive |

**Default:** Deep Research (auto-selected when no materials provided)

## 🛠️ Scripts

```bash
# Main orchestrator
scripts/orchestrate.sh \
  --topic "Kubernetes 架构" \
  --materials "https://..." "https://..." \
  --research-mode deep \
  --artifacts "report audio slides quiz video"

# Config loader
source scripts/config_loader.sh
load_config

# Prompt selector
scripts/prompt_selector.sh --intent summarize
scripts/prompt_selector.sh --category analysis
scripts/prompt_selector.sh --random
```

## 📋 Configuration

Edit `config/default.conf` or set environment variables:

```bash
# Artifact generation
DEFAULT_ARTIFACTS="report audio slides mindmap quiz"
ENABLE_VIDEO=true
ENABLE_INFOGRAPHIC=false
ENABLE_FLASHCARDS=true

# Research mode
DEFAULT_RESEARCH_MODE="deep"  # fast | deep

# Obsidian integration
OBSIDIAN_VAULT_PATH="$HOME/obsidian-vault"
ENABLE_OBSIDIAN_INTEGRATION=true

# Timeouts (seconds)
ARTIFACT_TIMEOUT=1800
RESEARCH_TIMEOUT_DEEP=1800
RESEARCH_TIMEOUT_FAST=60
```

## 🧠 Prompt Templates

Located in `config/prompts/`:

### Basic (基础提问)
- Summarize key points
- Explain in simple terms
- Relate to known concepts
- Provide practical examples
- Create teaching outline

### Analysis (深度分析)
- Identify core controversies
- Compare different schools of thought
- Trace historical evolution
- Predict future trends
- Clarify common misconceptions

### Practical (实用场景)
- Workplace application
- Personalized advice
- Learning path design
- Resource recommendations

### Creative (创意生成)
- Training curriculum design
- Beginner-friendly adaptation
- Test question generation
- Analogy-based explanations

**Usage:**
```bash
# Select prompt by intent
./prompt_selector.sh --intent summarize
./prompt_selector.sh --intent compare
./prompt_selector.sh --intent teach

# Select by category
./prompt_selector.sh --category analysis

# Random prompt for inspiration
./prompt_selector.sh --random
```

## ⚡ Execution Pattern

**Use subagents for long-running tasks:**
- Source processing (30s-10min per source)
- Artifact generation (5-45min per artifact)
- Research (2-30min for deep mode)

**Main conversation continues while subagents work in background.**

## 📤 Output & Delivery

**All artifacts are:**
1. Downloaded to `~/.openclaw/workspace/deep-learning-output/<notebook-id>/`
2. Sent to user via Feishu with formatted summary
3. Saved to Obsidian Inbox (if enabled)
4. Quiz questions sent as interactive message (if supported)

**Feishu message template:**
```
📚 深度学习完成：[主题]

✅ 已保存到 Obsidian Inbox
📂 Research Mode: deep

产物：
📄 学习报告
📊 PPT 讲义
🎙️ 音频播客
❓ 测试题
🎬 视频解说

🔗 NotebookLM: https://notebooklm.google.com/notebook/[id]
```

## 🔧 Error Handling

**Source processing fails:**
- Log warning, continue with successful sources
- Minimum 1 source required to proceed
- Retry once for transient failures

**Artifact generation fails:**
- Retry once after 5 minutes
- If still fails, skip that artifact and continue
- Report which artifacts succeeded/failed

**Rate limiting:**
- Wait 10 minutes, retry once
- If persistent, suggest manual retry later
- Provide notebook URL for manual access

## 📊 Time Estimates

| Phase | Typical Duration |
|-------|-----------------|
| Material collection | 1-5 min |
| Source processing | 2-10 min |
| Fast Research | 10-20 sec |
| Deep Research | 2-30 min |
| Report generation | 5-15 min |
| Podcast generation | 10-20 min |
| Slide generation | 15-30 min |
| Video generation | 10-20 min |
| Quiz generation | 5-15 min |
| Download & send | 1-2 min |

**Total: 10-60 minutes** (most work happens in parallel via subagents)

## 📝 Dependencies

**Required skills:**
- `notebooklm` - Core NotebookLM operations
- `jina-reader` - Web page extraction (social media support)

**Optional skills (auto-detected):**
- `bilibili-subtitle` - Bilibili video transcription
- `ultimate-search` - Web search enhancement
- `anything-to-notebooklm` - Multi-format document support

## 🎯 Best Practices

1. **Always specify topic clearly** - Better input = better output
2. **Provide materials when available** - More control over sources
3. **Use Fast Research for quick overviews** - Save time on simple topics
4. **Use Deep Research for complex subjects** - Comprehensive coverage
5. **Enable video for visual learners** - Great for presentations
6. **Review quiz questions** - Adjust difficulty if needed

## 🚀 Examples

### Example 1: Learn from URL
```
User: "帮我学习这篇文章 https://example.com/kubernetes
Assistant: 🚀 Starting deep learning workflow...
[Collects article, creates notebook, generates artifacts]
✅ 深度学习完成：Kubernetes 架构
```

### Example 2: Keyword Research
```
User: "我想深入了解 Rust 的所有权机制"
Assistant: 🔬 No materials provided, activating Deep Research mode...
[Searches for 15+ sources, creates comprehensive notebook]
✅ 深度学习完成：Rust 所有权机制
```

### Example 3: Video Tutorial
```
User: "把这个 B 站视频做成学习材料 https://bilibili.com/video/BV1xx"
Assistant: 📥 Collecting materials...
[Extracts subtitles, generates video brief + slides + quiz]
✅ 深度学习完成：[Video topic]
```

### Example 4: Quick Summary
```
User: "总结一下这个概念，太快了看不懂"
Assistant: ⚡ Fast Research mode activated...
[Quick 10-20 second research, generates summary report]
✅ 快速总结完成
```
