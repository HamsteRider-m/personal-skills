# /obos review

Vault 状态回顾，不绑定时间周期，随时可以运行。输出 vault 健康度和下一步行动建议。

## Usage

```
/obos review              # 回顾默认 vault
/obos review --to work    # 回顾指定 vault
```

## Step 1: 确定目标 Vault

使用 SKILL.md 中的 Vault Path Discovery 逻辑。

## Step 2: 收集数据

读取 vault 中的关键信息：

1. **Index.md** — 如果存在，读取统计数据和最近笔记
2. **Inbox/ 目录** — 统计未整理文件数量
3. **各标准目录** — 统计文件数量
4. **frontmatter 扫描** — 统计各 status 的笔记数量（inbox/draft/refined）
5. **最近 7 天** — 新增和修改的文件列表

## Step 3: 输出回顾报告

```
📊 Vault 回顾: {vault_alias}
═══════════════════════════

总笔记: {count}
  Inbox: {n} | Notes: {n} | Clippings: {n} | References: {n}

成熟度:
  ██████░░░░ inbox: {n}
  ████░░░░░░ draft: {n}
  ██░░░░░░░░ refined: {n}

最近 7 天动态:
  新增: {n} 篇
  修改: {n} 篇
  {列出最近 5 个文件名和目录}
```

## Step 4: 待处理事项

根据 vault 状态，列出需要关注的事项：

```
待处理:
  📥 Inbox 未整理: {n} 篇 → /obos tidy
  🏝️ 孤岛笔记: {n} 篇 → /obos sync
  📝 Draft 笔记: {n} 篇 → /obos refine
```

只显示数量 > 0 的项目。如果全部为 0，输出：
```
✅ Vault 状态良好，没有待处理事项。
```

## Step 5: 下一步建议

根据优先级给出一个最有价值的行动建议：

1. Inbox 有未整理文件 → "建议先运行 `/obos tidy` 整理 {n} 篇 Inbox 笔记"
2. 孤岛笔记多 → "建议运行 `/obos sync` 为孤岛笔记建立链接"
3. Draft 笔记多 → "可以挑一篇运行 `/obos refine` 深度加工"
4. 都没有 → "Vault 井然有序。随时用 `/obos save` 收集新想法"

只给一条建议，不要列出所有可能的操作。
