---
name: feishu-work-archive
description: 导出工作飞书文档到 Obsidian，按主题整理并生成索引
---

# 飞书工作归档 Skill

从工作飞书账号读取文档，AI 分析主题，整理到 Obsidian。

## 使用场景

- 离职前整理工作文档
- 定期备份飞书云文档
- 按主题归档项目资料

## 工作流程

1. 列出工作飞书的文档/知识库
2. 读取文档内容
3. AI 分析主题和重要性
4. 按主题分类保存到 Obsidian
5. 生成索引文件

## 配置

需要在 `openclaw.json` 配置工作飞书账号（account: "work"）

## 命令

```bash
# 列出可导出的文档
node archive.js list

# 导出所有文档
node archive.js export

# 导出指定文档
node archive.js export --doc-token ABC123

# 生成索引
node archive.js index
```
