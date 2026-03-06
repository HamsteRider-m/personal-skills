# Personal Skills Manifest

**Last Updated**: 2026-03-06  
**Total Skills**: 6

## Core Skills

### deep-learning
- **Path**: `skills/core/deep-learning/`
- **Status**: `active`
- **Role**: NotebookLM-centered orchestrator
- **Dependencies**: content-bridge, notebooklm-py
- **Notes**: 正在重构为依赖外部摄取 skills

### browser-plus
- **Path**: `skills/core/browser-plus/`
- **Status**: `stable`
- **Role**: 智能浏览器自动化
- **Dependencies**: agent-browser, OpenClaw native browser
- **Notes**: 自动路由到最优浏览器实现

## Content Skills

### bilibili-subtitle
- **Path**: `skills/content/bilibili-subtitle/`
- **Status**: `stable`
- **Role**: B站视频字幕提取与转录
- **Dependencies**: Dashscope API
- **Notes**: 可被 deep-learning 和其他 skills 复用

### jina-reader
- **Path**: `skills/content/jina-reader/`
- **Status**: `stable`
- **Role**: 网页内容提取
- **Dependencies**: Jina AI API
- **Notes**: 未来可能被 web-reader 整合

## Productivity Skills

### dev-workflow
- **Path**: `skills/productivity/dev-workflow/`
- **Status**: `stable`
- **Role**: 开发流程管理
- **Dependencies**: git, gh CLI
- **Notes**: Issue-driven development

## Integration Skills

### notebooklm-suite
- **Path**: `skills/integrations/notebooklm-suite/`
- **Status**: `under-review`
- **Role**: NotebookLM 集成套件
- **Dependencies**: notebooklm-py
- **Notes**: 边界待厘清，可能被 deep-learning 吸收

---

## Planned Skills (待创建)

### content-bridge
- **Target Path**: `skills/content/content-bridge/`
- **Status**: `planned`
- **Role**: 通用内容摄取路由层
- **Source**: 改名自 anything-to-notebooklm
- **Phase**: Phase 1

### weixin-extractor
- **Target Path**: `skills/content/weixin-extractor/`
- **Status**: `planned`
- **Role**: 微信文章提取
- **Source**: 从 anything-to-notebooklm 拆分
- **Phase**: Phase 2

### youtube-transcript
- **Target Path**: `skills/content/youtube-transcript/`
- **Status**: `planned`
- **Role**: YouTube 视频转录
- **Source**: 从 anything-to-notebooklm 拆分
- **Phase**: Phase 2

### web-reader
- **Target Path**: `skills/content/web-reader/`
- **Status**: `planned`
- **Role**: 通用网页内容提取
- **Source**: 整合 jina-reader
- **Phase**: Phase 2

### document-parser
- **Target Path**: `skills/content/document-parser/`
- **Status**: `planned`
- **Role**: PDF/DOCX 文档解析
- **Source**: 从 anything-to-notebooklm 拆分
- **Phase**: Phase 2

---

## Migration Queue (待迁移)

### ultimate-search
- **Target Path**: `skills/content/ultimate-search/`
- **Status**: `migration-pending`
- **Source**: Fork from ckckck/UltimateSearchSkill
- **Notes**: 有 3 个有价值的增强 commits，需保留并监控上游
- **Phase**: Phase 4

### obsidian-assistant
- **Target Path**: `skills/productivity/obsidian-assistant/`
- **Status**: `migration-pending`
- **Source**: obsidian-best-pract (需改名)
- **Notes**: 标记 needs-refresh，后续单独重做
- **Phase**: Phase 4

### codex-agent
- **Target Path**: `skills/core/codex-agent/`
- **Status**: `verification-needed`
- **Notes**: 需确认是否已在库中
- **Phase**: Phase 4

---

## Archive

### feishu-work-archive
- **Path**: `archive/feishu-work-archive/`
- **Status**: `archive`
- **Reason**: 已废弃，不再维护

---

## Status Legend

- `stable`: 生产可用，无已知问题
- `active`: 活跃开发中
- `needs-refresh`: 功能可用但需更新
- `under-review`: 评估中，未来方向待定
- `planned`: 计划创建
- `migration-pending`: 等待从外部迁入
- `verification-needed`: 需确认状态
- `archive`: 已废弃

---

## Maintenance Notes

- 本文档应在每次 skill 状态变更时更新
- 新增 skill 必须在此登记
- 废弃 skill 移至 Archive 区
