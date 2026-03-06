# Deep-Learning Skill Evaluation - Quick Start

## 评测脚本位置
```
~/.openclaw/workspace/skills/deep-learning/eval/
├── scripts/
│   ├── score_trial.sh      # Phase 1-3 自动评分
│   ├── llm_grade.sh         # Phase 4 LLM 质量评分
│   └── run_trials.sh        # 批量运行 5 次试验
└── results/                 # 评测结果输出
```

## 快速开始

### 运行单个测试用例（5次试验）

**Test Case 1: 单网页文章**
```bash
bash ~/.openclaw/workspace/skills/deep-learning/eval/scripts/run_trials.sh \
  --test-case "test-1-web-article" \
  --topic "Kubernetes 架构深度解析" \
  --material "https://kubernetes.io/docs/concepts/architecture/"
```

**Test Case 2: YouTube 视频**
```bash
bash ~/.openclaw/workspace/skills/deep-learning/eval/scripts/run_trials.sh \
  --test-case "test-2-youtube" \
  --topic "Docker 容器技术入门" \
  --material "https://www.youtube.com/watch?v=Gjnup-PuquQ"
```

**Test Case 3: 多源混合**
```bash
bash ~/.openclaw/workspace/skills/deep-learning/eval/scripts/run_trials.sh \
  --test-case "test-3-mixed" \
  --topic "微服务架构最佳实践" \
  --material "https://microservices.io/patterns/microservices.html" \
  --material "https://www.youtube.com/watch?v=CZ3wIuvmHeM"
```


**Test Case 4: 搜索关键词（Research 模式）**
```bash
bash ~/.openclaw/workspace/skills/deep-learning/eval/scripts/run_trials.sh \
  --test-case "test-4-research" \
  --topic "Rust 编程语言内存安全机制"
  # 注意：无 --material 参数，触发搜索+研究模式
```

**Test Case 5: B站视频**
```bash
bash ~/.openclaw/workspace/skills/deep-learning/eval/scripts/run_trials.sh \
  --test-case "test-5-bilibili" \
  --topic "Python 异步编程详解" \
  --material "https://www.bilibili.com/video/BV1aK411M7HX"
```

## 查看结果

```bash
# 查看汇总报告
cat ~/.openclaw/workspace/skills/deep-learning/eval/results/test-1-web-article/aggregate.json

# 查看单次试验详情
cat ~/.openclaw/workspace/skills/deep-learning/eval/results/test-1-web-article/trial-1.json
```

## 评分标准

- **Pass**: ≥ 70/100
- **Pass@5**: ≥ 0.8 (5次中至少4次通过)

详细评分标准见：`~/.openclaw/workspace/docs/deep-learning-eval-framework.md`
