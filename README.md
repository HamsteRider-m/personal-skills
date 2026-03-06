# Personal Skills Monorepo

个人技能集合仓库，统一管理所有自定义 OpenClaw skills。

## 架构理念

- **解耦**：内容摄取与下游应用分离
- **复用**：任何 skill 可依赖独立摄取能力
- **清晰**：每个 skill 职责明确，边界清晰
- **可维护**：独立升级，影响范围可控

## 目录结构

```
skills/
├── core/           # 核心能力编排与平台级 skill
├── content/        # 内容采集、抽取、搜索类
├── productivity/   # 知识管理、开发流程、效率类
├── integrations/   # 外部平台/套件集成
└── archive/        # 已废弃但暂不删除的旧 skill
```

## 安装

```bash
# 安装所有 skills 到 OpenClaw
npx skills add HamsteRider-m/personal-skills --all -g -a openclaw -y

# 更新已安装的 skills
npx skills update HamsteRider-m/personal-skills
```

## 管理策略

### Skill 状态标签
- `stable`: 生产可用
- `active`: 活跃开发中
- `needs-refresh`: 需要更新
- `under-review`: 评估中
- `archive`: 已废弃

### Branch 命名规范
- Skill-specific: `feature/<skill-name>-<feature>`
- Category-wide: `refactor/<category>-<scope>`
- Monorepo infra: `infra/<scope>`

### Worktree 使用
- 每个 worktree 对应一条独立开发线
- 明确目标和完成条件
- 完成后及时清理

## 核心 Skills

### Core
- **deep-learning**: NotebookLM-centered orchestrator
- **browser-plus**: 智能浏览器自动化

### Content
- **content-bridge**: 通用内容摄取路由层
- **bilibili-subtitle**: B站字幕提取
- **jina-reader**: 网页内容提取

### Productivity
- **dev-workflow**: 开发流程管理

### Integrations
- **notebooklm-suite**: NotebookLM 集成套件

## 贡献

本仓库为个人使用，但欢迎参考和借鉴。

## License

MIT
