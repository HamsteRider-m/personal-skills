# Troubleshooting Guide

Common issues and solutions for deep learning workflows.

## Authentication Issues

**Symptom:** `notebooklm` commands fail with auth errors

**Solution:**
```bash
notebooklm auth check
notebooklm login
```

## Source Processing Failures

**Symptom:** Source stuck in "processing" or shows "error" status

**Causes & Solutions:**

| Cause | Solution |
|-------|----------|
| Invalid URL | Verify URL is accessible, try alternative source |
| Unsupported format | Check NotebookLM supported formats, convert if needed |
| File too large | Split large files, or use excerpts |
| Network timeout | Retry with `notebooklm source add [url] --json` |

**Check status:**
```bash
notebooklm source list --json -n [notebook_id]
```

## Rate Limiting

**Symptom:** Generation fails with "GENERATION_FAILED" or "No result found for RPC ID"

**Solution:**
- Wait 10 minutes
- Retry once
- If persistent, use NotebookLM web UI as fallback

**Affected operations:**
- Audio/video generation
- Quiz/flashcard generation
- Slide deck generation

**Reliable operations** (no rate limits):
- Report generation
- Mind map generation
- Chat/queries

## Artifact Generation Timeout

**Symptom:** `artifact wait` returns exit code 2

**Solution:**
- Check status manually: `notebooklm artifact list -n [notebook_id]`
- If still "in_progress", extend timeout and retry
- If "completed", proceed to download
- If "unknown", regenerate artifact

## Download Failures

**Symptom:** Download command fails

**Check:**
1. Artifact status: `notebooklm artifact list -n [notebook_id]`
2. Must be "completed" before download
3. Verify artifact ID is correct

## Subagent Issues

**Symptom:** Subagent doesn't report back

**Debug:**
```bash
# Check running subagents
openclaw sessions list

# Check specific subagent logs
# (use session key from list output)
```

## Parallel Context Conflicts

**Symptom:** "No notebook context" errors in parallel workflows

**Solution:**
Always use explicit notebook IDs with `-n` flag:
```bash
notebooklm artifact wait [id] -n [notebook_id]
notebooklm download audio ./out.mp3 -a [id] -n [notebook_id]
```

**Never rely on** `notebooklm use` in parallel workflows.

## Material Collection Failures

**WeChat articles:**
- Verify MCP server is running
- Check `openclaw status` for MCP connection

**Bilibili videos:**
- Verify `bilibili-subtitle` skill is installed
- Check video is publicly accessible

**YouTube videos:**
- Verify `yt-dlp` is installed
- Check video has captions available

## Feishu Delivery Issues

**File upload fails:**
- Check file size limits (Feishu has 200MB limit per file)
- Verify Feishu channel is configured
- Check network connectivity

**Message send fails:**
- Verify user ID in allowlist
- Check Feishu app permissions

## Emergency Fallback

If automation fails completely:

1. Get notebook URL from logs
2. Share URL with user
3. User accesses NotebookLM web UI directly
4. Manual generation and download

## Debugging Commands

```bash
# Check NotebookLM auth
notebooklm auth check --test

# List all notebooks
notebooklm list --json

# Check specific notebook sources
notebooklm source list --json -n [notebook_id]

# Check artifact status
notebooklm artifact list --json -n [notebook_id]

# Check OpenClaw status
openclaw status

# Check running sessions
openclaw sessions list
```
