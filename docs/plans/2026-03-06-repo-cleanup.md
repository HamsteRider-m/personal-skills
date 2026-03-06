# Repository Cleanup Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove tracked runtime artifacts from `archive/feishu-work-archive` and prevent them from re-entering the repo.

**Architecture:** Keep the repository limited to source code, package metadata, and documentation. Remove generated browser profiles, caches, installed dependencies, logs, cookies, and export progress artifacts from version control, then ignore those paths at the repo root.

**Tech Stack:** Git, shell utilities, `.gitignore`

---

### Task 1: Add ignore rules for generated archive artifacts

**Files:**
- Create: `.gitignore`

**Step 1: Add precise ignore entries**

Add rules for:

```gitignore
archive/feishu-work-archive/node_modules/
archive/feishu-work-archive/browser-data/
archive/feishu-work-archive/profile/
archive/feishu-work-archive/*.log
archive/feishu-work-archive/cookies.txt
archive/feishu-work-archive/batches.json
archive/feishu-work-archive/export-manifest.json
archive/feishu-work-archive/progress*.json
```

**Step 2: Verify the ignore file content**

Run: `sed -n '1,120p' .gitignore`
Expected: Only the targeted archive runtime artifacts are ignored.

### Task 2: Remove tracked generated artifacts from version control

**Files:**
- Modify: `archive/feishu-work-archive`

**Step 1: Remove tracked runtime directories**

Run:

```bash
git rm -r --cached archive/feishu-work-archive/node_modules \
  archive/feishu-work-archive/browser-data \
  archive/feishu-work-archive/profile
```

Expected: Git stages mass deletions under those runtime-only directories.

**Step 2: Remove tracked generated files**

Run:

```bash
git rm --cached archive/feishu-work-archive/*.log \
  archive/feishu-work-archive/cookies.txt \
  archive/feishu-work-archive/batches.json \
  archive/feishu-work-archive/export-manifest.json \
  archive/feishu-work-archive/progress*.json
```

Expected: Logs, cookies, and progress/export manifests are staged for deletion.

### Task 3: Verify the cleanup result

**Files:**
- Modify: `.gitignore`
- Modify: `archive/feishu-work-archive`

**Step 1: Check git status**

Run: `git status --short`
Expected: Only the planned deletions and `.gitignore`/plan file additions appear.

**Step 2: Check remaining tracked archive files**

Run: `git ls-files archive/feishu-work-archive | sed -n '1,120p'`
Expected: Source files such as `README.md`, `SKILL.md`, scripts, and `package.json` remain tracked.
