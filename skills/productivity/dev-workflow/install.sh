#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
SKILL_NAME="issue-driven"
SKILL_DST="$HOME/.claude/skills/$SKILL_NAME"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"

START_MARKER="<!-- ISSUE_DRIVEN_START -->"
END_MARKER="<!-- ISSUE_DRIVEN_END -->"

# --- i18n ---
detect_lang() {
  case "${LANG:-}${LC_ALL:-}" in zh_CN*|zh_TW*) echo "zh" ;; *) echo "en" ;; esac
}
L="$(detect_lang)"

msg() {
  local k="$1"
  if [[ "$L" == "zh" ]]; then
    case "$k" in
      installing)    echo "正在安装 issue-driven skill..." ;;
      uninstalling)  echo "正在卸载 issue-driven skill..." ;;
      skill_ok)      echo "✓ Skill 已安装到 $SKILL_DST" ;;
      skill_rm)      echo "✓ Skill 目录已删除" ;;
      injected)      echo "✓ CLAUDE.md 已注入 ISSUE_DRIVEN 配置" ;;
      updated)       echo "✓ CLAUDE.md 已更新 ISSUE_DRIVEN 配置" ;;
      removed)       echo "✓ CLAUDE.md 已移除 ISSUE_DRIVEN 配置" ;;
      no_marker)     echo "⚠ CLAUDE.md 中未找到 ISSUE_DRIVEN 标记" ;;
      done)          echo "✓ 完成！" ;;
      usage)         echo "用法: $0 [install|uninstall]" ;;
    esac
  else
    case "$k" in
      installing)    echo "Installing issue-driven skill..." ;;
      uninstalling)  echo "Uninstalling issue-driven skill..." ;;
      skill_ok)      echo "✓ Skill installed to $SKILL_DST" ;;
      skill_rm)      echo "✓ Skill directory removed" ;;
      injected)      echo "✓ ISSUE_DRIVEN config injected into CLAUDE.md" ;;
      updated)       echo "✓ ISSUE_DRIVEN config updated in CLAUDE.md" ;;
      removed)       echo "✓ ISSUE_DRIVEN config removed from CLAUDE.md" ;;
      no_marker)     echo "⚠ No ISSUE_DRIVEN markers found in CLAUDE.md" ;;
      done)          echo "✓ Done!" ;;
      usage)         echo "Usage: $0 [install|uninstall]" ;;
    esac
  fi
}

# --- Config block to inject ---
gen_block() {
  cat << 'BLOCK'
<!-- ISSUE_DRIVEN_START -->
## Issue-Driven Development

在有 remote 的 Git 项目中，所有开发任务（feature/bug/refactor）默认走 Issue-driven 流程。
使用 `/issue` skill 管理完整生命周期：Issue 创建 → 开发 → Code Review → PR → 关闭。

- **有 remote 的 Git 项目**：默认走 issue-driven，主动提示用户。
- **无 remote 的 Git 项目**：建议创建 remote（`gh repo create`），但不强制阻断，由用户决定。
- **非 Git 项目**：不受此约束。
<!-- ISSUE_DRIVEN_END -->
BLOCK
}

# --- CLAUDE.md injection (Python regex, same as CCB) ---
inject_claude_md() {
  local block
  block="$(gen_block)"

  mkdir -p "$(dirname "$CLAUDE_MD")"

  if [[ ! -f "$CLAUDE_MD" ]]; then
    echo "$block" > "$CLAUDE_MD"
    msg injected
  elif grep -qF "$START_MARKER" "$CLAUDE_MD"; then
    python3 -c "
import re, sys
p = sys.argv[1]
new = sys.argv[2]
with open(p, 'r') as f: c = f.read()
c = re.sub(r'<!-- ISSUE_DRIVEN_START -->.*?<!-- ISSUE_DRIVEN_END -->', new, c, flags=re.DOTALL)
with open(p, 'w') as f: f.write(c)
" "$CLAUDE_MD" "$block"
    msg updated
  else
    printf '\n%s\n' "$block" >> "$CLAUDE_MD"
    msg injected
  fi
}

# --- Remove ISSUE_DRIVEN block from CLAUDE.md ---
remove_claude_md() {
  if [[ ! -f "$CLAUDE_MD" ]] || ! grep -qF "$START_MARKER" "$CLAUDE_MD"; then
    msg no_marker; return
  fi
  python3 -c "
import re, sys
p = sys.argv[1]
with open(p, 'r') as f: c = f.read()
c = re.sub(r'\n*<!-- ISSUE_DRIVEN_START -->.*?<!-- ISSUE_DRIVEN_END -->\n*', '\n', c, flags=re.DOTALL)
with open(p, 'w') as f: f.write(c)
" "$CLAUDE_MD"
  msg removed
}

# --- Install: copy skill + inject CLAUDE.md ---
do_install() {
  msg installing
  mkdir -p "$SKILL_DST"
  cp "$REPO_ROOT/SKILL.md" "$SKILL_DST/SKILL.md"
  msg skill_ok
  inject_claude_md
  msg done
}

# --- Uninstall: remove skill + clean CLAUDE.md ---
do_uninstall() {
  msg uninstalling
  if [[ -d "$SKILL_DST" ]]; then
    rm -rf "$SKILL_DST"
    msg skill_rm
  fi
  remove_claude_md
  msg done
}

# --- Main ---
case "${1:-install}" in
  install)   do_install ;;
  uninstall) do_uninstall ;;
  *)         msg usage; exit 1 ;;
esac
