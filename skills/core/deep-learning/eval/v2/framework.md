# Deep-Learning Skill Robustness Test Framework v2.0

## 核心问题分析

### 原框架的不足
1. **评分过于简单** - 只有总分，无法定位具体失败点
2. **缺乏降级策略测试** - 没有验证部分失败时的行为
3. **时间估算不准确** - 实际耗时与预期偏差大
4. **无用户体验指标** - 只关注技术正确性，忽略交互质量
5. **缺少增量交付测试** - 全部完成才给结果，不符合人性化需求

### 新增测试维度
1. **Robustness（鲁棒性）** - 部分失败时的恢复能力
2. **Progressive Delivery（渐进交付）** - 产物逐步可用性
3. **User Experience（用户体验）** - 交互质量和反馈及时性
4. **Resource Efficiency（资源效率）** - 时间和成本优化

---

## 新评分体系（100分 → 扩展版）

### Phase 1: 意图识别 (10分)
| 子项 | 分值 | 说明 |
|------|------|------|
| 显式触发识别 | 3 | 正确识别"帮我学习"等指令 |
| 隐式触发识别 | 4 | 正确识别"总结一下"等意图 |
| 上下文感知 | 3 | 主动询问场景检测准确性 |

### Phase 2: 材料收集 (15分)
| 子项 | 分值 | 说明 |
|------|------|------|
| 源类型检测 | 3 | 正确识别URL类型 |
| 内容提取成功率 | 5 | jina-reader/其他工具成功率 |
| 处理超时处理 | 4 | 超时后的降级策略 |
| 错误恢复 | 3 | 失败后重试或跳过机制 |

### Phase 3: Notebook 创建与管理 (10分)
| 子项 | 分值 | 说明 |
|------|------|------|
| Notebook 创建 | 3 | 成功创建并返回ID |
| 源上传成功率 | 4 | 至少1个源成功 |
| 索引完成等待 | 3 | 正确处理异步索引 |

### Phase 4: 产物生成 (25分) ⭐ 关键改进
| 子项 | 分值 | 说明 |
|------|------|------|
| 报告生成 | 6 | 最快产物，必须成功 |
| 播客生成 | 5 | 音频产物 |
| PPT生成 | 5 | 幻灯片产物 |
| 思维导图 | 3 | 快速产物 |
| 测试题 | 3 | 互动产物 |
| 视频/信息图/闪卡 | 3 | 可选产物 |

**评分规则：**
- 报告必须成功（否则整体失败）
- 至少3个核心产物成功（报告+任意2个）
- 可选产物失败不扣分，成功加分

### Phase 5: 渐进交付 (20分) ⭐ 新增
| 子项 | 分值 | 说明 |
|------|------|------|
| 首产物响应时间 | 8 | 首个产物<5分钟 |
| 中间状态通知 | 7 | 每完成一个产物即通知 |
| Key Takeaways 提取 | 5 | 提供即时价值摘要 |

### Phase 6: 质量评估 (15分)
| 子项 | 分值 | 说明 |
|------|------|------|
| 内容准确性 | 5 | LLM rubric评分 |
| 结构完整性 | 5 | 格式规范、章节完整 |
| 实用价值 | 5 | 用户可直接使用 |

### Phase 7: 最终交付 (5分)
| 子项 | 分值 | 说明 |
|------|------|------|
| Obsidian保存 | 2 | 正确保存到指定路径 |
| Feishu通知 | 2 | 完整摘要发送成功 |
| 链接可访问 | 1 | NotebookLM链接有效 |

---

## Robustness 测试用例（新增）

### R1: 单源失败恢复
**输入：** 3个URL，其中1个无效
**期望：** 
- 2个成功源继续流程
- 向用户报告哪个源失败
- 整体流程不中断

### R2: 产物部分失败
**输入：** 正常材料
**期望：**
- 报告必须成功
- 其他产物允许个别失败
- 失败产物在通知中标注

### R3: 网络中断恢复
**输入：** 长流程执行中网络波动
**期望：**
- 自动重试（最多3次）
- 指数退避延迟
- 最终失败时提供手动继续选项

### R4: NotebookLM 限流
**输入：** 高频调用场景
**期望：**
- 检测到429错误
- 自动等待并重试
- 向用户说明延迟原因

### R5: 超大内容处理
**输入：** >100页PDF或>2小时视频
**期望：**
- 分段处理
- 进度通知
- 内存不溢出

---

## Progressive Delivery 机制（人性化改进）

### 核心理念
不要等所有产物完成再给结果，有什么先给什么，让用户立即获得价值。

### 交付时间表
```
T+0min    → 确认收到请求，开始处理
T+2min    → 📄 报告完成 → 立即发送 + Key Takeaways
T+5min    → 🗺️ 思维导图完成 → 追加发送
T+10min   → ❓ 测试题完成 → 追加发送（可先做）
T+15min   → 🎙️ 播客完成 → 追加发送
T+25min   → 📊 PPT完成 → 追加发送
T+30min   → 🎬 视频完成 → 追加发送（如启用）
T+35min   → ✅ 全部完成总结
```

### Key Takeaways 自动生成
每个产物完成时，提取核心价值：

**报告完成时：**
```
📄 学习报告已生成！

Key Takeaways:
• 核心概念：XXX 是 YYY 的 ZZZ
• 关键洞察：ABC 导致了 DEF
• 实践要点：建议从 GHI 入手

[查看完整报告]
```

**播客完成时：**
```
🎙️ 深度播客已生成！

本期亮点：
• 05:23 - 解释了 XXX 的核心原理
• 12:45 - 对比了 YYY 和 ZZZ 的差异
• 18:30 - 给出了实际应用建议

适合通勤收听 🎧
```

---

## 测试执行框架

### 目录结构
```
eval/
├── v2/                           # 新版评测框架
│   ├── framework.md             # 本文件
│   ├── test-cases/              # 测试用例
│   │   ├── robustness/          # 鲁棒性测试
│   │   │   ├── r1-partial-failure.sh
│   │   │   ├── r2-network-recovery.sh
│   │   │   └── r3-rate-limit.sh
│   │   ├── progressive/         # 渐进交付测试
│   │   │   ├── p1-delivery-timing.sh
│   │   │   └── p2-key-takeaways.sh
│   │   └── scenarios/           # 场景测试
│   │       ├── s1-youtube.sh
│   │       ├── s2-x-article.sh
│   │       └── s3-deep-research.sh
│   ├── scripts/
│   │   ├── run_test.sh          # 单个测试运行
│   │   ├── run_suite.sh         # 批量测试套件
│   │   ├── measure_progressive.sh # 渐进交付测量
│   │   └── grade_quality.sh     # 质量评分
│   └── reports/                 # 测试报告输出
└── v1/                          # 保留旧版兼容
```

### 测试运行命令
```bash
# 运行单个鲁棒性测试
./eval/v2/scripts/run_test.sh --test robustness/r1-partial-failure

# 运行渐进交付测试
./eval/v2/scripts/run_test.sh --test progressive/p1-delivery-timing

# 运行完整测试套件
./eval/v2/scripts/run_suite.sh --suite full --trials 5

# 仅运行快速冒烟测试
./eval/v2/scripts/run_suite.sh --suite smoke
```

### 报告格式
```json
{
  "test_id": "robustness-r1",
  "timestamp": "2026-03-06T09:00:00Z",
  "overall_score": 78,
  "passed": true,
  "phases": {
    "intent_detection": { "score": 9, "max": 10, "details": [...] },
    "material_collection": { "score": 13, "max": 15, "details": [...] },
    "notebook_management": { "score": 10, "max": 10, "details": [...] },
    "artifact_generation": { "score": 22, "max": 25, "details": [...] },
    "progressive_delivery": { "score": 16, "max": 20, "details": [...] },
    "quality_assessment": { "score": 13, "max": 15, "details": [...] },
    "final_delivery": { "score": 5, "max": 5, "details": [...] }
  },
  "progressive_timeline": [
    { "time": "00:02:15", "artifact": "report", "delivered": true },
    { "time": "00:04:30", "artifact": "mindmap", "delivered": true },
    { "time": "00:08:45", "artifact": "quiz", "delivered": true }
  ],
  "robustness_checks": {
    "partial_failure_handled": true,
    "recovery_attempted": true,
    "user_notified": true
  }
}
```

---

## 通过标准

### 基础通过（Release Ready）
- 单次测试 ≥ 70分
- Pass@5 ≥ 0.8（5次中4次通过）
- 报告产物 100% 成功率
- 渐进交付首产物 < 5分钟

### 优秀标准（Production Grade）
- 单次测试 ≥ 85分
- Pass@10 ≥ 0.9
- 所有核心产物 ≥ 90% 成功率
- 渐进交付首产物 < 3分钟
- 鲁棒性测试全部通过

### 卓越标准（Best in Class）
- 单次测试 ≥ 95分
- Pass@20 ≥ 0.95
- 100% 产物成功率
- 渐进交付首产物 < 2分钟
- 零人工干预完成率 > 95%

---

## 实施路线图

### Phase 1: 基础设施（本周）
- [ ] 创建 eval/v2/ 目录结构
- [ ] 实现渐进交付脚本
- [ ] 添加 Key Takeaways 提取功能

### Phase 2: 鲁棒性测试（下周）
- [ ] 实现 R1-R5 测试用例
- [ ] 添加故障注入机制
- [ ] 完善错误恢复逻辑

### Phase 3: 质量提升（第三周）
- [ ] 优化产物生成速度
- [ ] 改进 Key Takeaways 质量
- [ ] 完善用户体验细节

### Phase 4: 全面评测（第四周）
- [ ] 运行完整测试套件
- [ ] 生成性能基准报告
- [ ] 制定持续集成方案
