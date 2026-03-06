# Deep-Learning Skill 完整测试矩阵

## 测试用例设计（8 个场景）

### Test Case 1: YouTube 视频
**Input:**
- Topic: "Kubernetes 入门教程"
- Material: https://www.youtube.com/watch?v=X48VuDVv0do

**Expected:**
- 字幕提取成功
- 视频内容转文本
- 生成学习指南
- 时长：20-30 分钟

**Success Criteria:**
- 所有产物：5/5
- 质量：≥ 16/20
- Total: ≥ 75/100

---

### Test Case 2: X/Twitter 技术文章
**Input:**
- Topic: "AI 技术深度分析"
- Material: https://x.com/[tech_thread]

**Expected:**
- jina-reader 转换
- 技术内容准确提取
- 结构化学习材料
- 时长：15-25 分钟

**Success Criteria:**
- 转换成功
- 质量（技术深度）：≥ 17/20
- Total: ≥ 75/100

---

### Test Case 3: Anthropic 技术文档
**Input:**
- Topic: "Claude API 使用指南"
- Material: https://docs.anthropic.com/en/api/getting-started

**Expected:**
- 直接 URL 上传
- API 文档结构化
- 代码示例提取
- 时长：15-20 分钟

**Success Criteria:**
- 文档完整性：高
- 代码示例准确
- Total: ≥ 75/100


### Test Case 4: OpenAI 技术博客
**Input:**
- Topic: "GPT-4 技术解析"
- Material: https://openai.com/research/gpt-4

**Expected:**
- 直接 URL 上传
- 研究内容提取
- 技术细节准确
- 时长：15-20 分钟

**Success Criteria:**
- 研究深度：高
- 技术准确性：≥ 17/20
- Total: ≥ 75/100

---

### Test Case 5: RSS 博客文章
**Input:**
- Topic: "技术博客精选"
- Material: https://blog.example.com/tech-article

**Expected:**
- jina-reader 提取
- 博客内容完整
- 格式保留良好
- 时长：10-15 分钟

**Success Criteria:**
- 内容完整性：高
- 格式保留：良好
- Total: ≥ 70/100


### Test Case 6: Deep Research（关键词触发）
**Input:**
- Topic: "Rust 内存安全机制"
- Material: (无，仅关键词)

**Expected:**
- 触发 NotebookLM Deep Research
- Gemini 自动搜索 15+ 源
- 综合研究报告
- 时长：30-60 分钟

**Success Criteria:**
- 研究源数量：≥ 15
- 研究深度：≥ 18/20
- Total: ≥ 80/100

---

### Test Case 7: 多源混合（技术栈学习）
**Input:**
- Topic: "Docker 容器化完整指南"
- Materials:
  - https://docs.docker.com/get-started/
  - https://www.youtube.com/watch?v=Gjnup-PuquQ
  - https://x.com/docker/status/[example]

**Expected:**
- 3 种源类型处理
- 知识融合
- 完整学习路径
- 时长：30-40 分钟

**Success Criteria:**
- 所有源上传：3/3
- 知识融合质量：≥ 17/20
- Total: ≥ 80/100


### Test Case 8: B站技术视频
**Input:**
- Topic: "Python 异步编程详解"
- Material: https://www.bilibili.com/video/BV1aK411M7HX

**Expected:**
- bilibili-subtitle 提取字幕
- 中文内容处理
- 技术概念准确
- 时长：20-30 分钟

**Success Criteria:**
- 字幕提取：成功
- 中文处理：准确
- Total: ≥ 70/100

---

## 测试执行计划

### Phase 1: 核心场景验证（优先级高）
1. Test Case 2: X 文章 ✅ (已完成，75/100)
2. Test Case 1: YouTube 视频
3. Test Case 6: Deep Research

### Phase 2: 文档类测试
4. Test Case 3: Anthropic 文档
5. Test Case 4: OpenAI 博客

### Phase 3: 复杂场景
6. Test Case 7: 多源混合
7. Test Case 8: B站视频
8. Test Case 5: RSS 博客

### 执行方式
```bash
# 单个测试
bash ~/.openclaw/workspace/skills/deep-learning/eval/scripts/run_trials.sh \
  --test-case "test-N" \
  --topic "主题" \
  --material "URL"

# 批量测试（待开发）
bash ~/.openclaw/workspace/skills/deep-learning/eval/scripts/run_all_tests.sh
```

