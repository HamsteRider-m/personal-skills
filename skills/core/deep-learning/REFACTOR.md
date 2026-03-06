# Deep-Learning 工作流重构完成

## 重构目标
创建统一的深度学习入口，用户无需登录 NotebookLM 网页，一个界面完成所有学习。

## 已完成的改进

### 1. 统一入口设计
- 更新 SOUL.md：定义自动触发规则
- 触发条件：链接+学习意图 / 概念+深度学习关键词 / 明确要求生成材料

### 2. Deep Research 支持
- 实现关键词触发 Deep Research
- 使用 `notebooklm source add-research` + `research wait`
- 自动搜集 15+ 源并导入

### 3. 自动发送到飞书
- 报告、PPT、播客、测试题自动发送
- 用户无需手动下载

### 4. 状态轮询优化
- 最多等待 5 分钟
- 每 10 秒检查产物完成度
- 显示进度（X/Y artifacts ready）

### 5. Skills 清理
- 删除 `anything-to-notebooklm`（功能已整合）
- 保留核心 skills：deep-learning, notebooklm, bilibili-subtitle, jina-reader

## 工作流程

**用户发送：** "帮我深度学习 Rust 内存安全"

**自动执行：**
1. 触发 Deep Research（Gemini 搜索 15+ 源）
2. 并行生成：报告、播客、PPT、测试题
3. 自动发送到飞书

**用户收到：** 完整学习包，无需任何手动操作

