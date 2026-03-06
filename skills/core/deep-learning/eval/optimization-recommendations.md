# Deep-Learning Skill 优化建议

基于 Test Case 6 (X 文章) 的测试结果和分析。

## 1. 智能源类型检测与预处理

### 当前问题
- NotebookLM 仅支持：url、text、file、youtube
- X/Twitter、微信公众号等需要预处理

### 优化方案
```bash
# 扩展检测规则
detect_source_type() {
  case "$url" in
    *x.com*|*twitter.com*)
      echo "x-article" ;;
    *mp.weixin.qq.com*)
      echo "wechat-article" ;;
    *zhihu.com*|*jianshu.com*)
      echo "blog-article" ;;
    *youtube.com*|*youtu.be*)
      echo "youtube" ;;
    *bilibili.com*)
      echo "bilibili" ;;
    *.pdf|*.docx)
      echo "document" ;;
    *)
      echo "url" ;;
  esac
}
```

### 预处理策略
- **X/Twitter/微信/知乎** → jina-reader 转 Markdown
- **YouTube** → 字幕提取（yt-dlp）
- **B站** → bilibili-subtitle
- **PDF/DOCX** → 直接上传
- **普通 URL** → 直接上传


## 2. 延伸阅读自动扩展

### 当前问题
- 文章末尾的参考链接未被利用
- 知识图谱不完整

### 优化方案
```bash
# 检测参考链接
extract_references() {
  grep -oP 'https?://[^\s]+' "$markdown_file" | tail -5
}

# 询问用户
echo "检测到 5 个延伸阅读链接，是否加入学习材料？[y/N]"
```

### 实现策略
- 自动提取文末链接
- 可选：自动添加（--auto-expand）
- 构建完整知识体系


## 3. 技术文章特殊处理

### 识别技术文章
- 关键词密度检测（API、架构、算法、框架等）
- 代码块数量
- 技术术语频率

### 增强处理
- 自动提取架构图描述 → 生成 Mermaid 图
- 提取代码示例并分类
- 识别技术栈并生成学习路径

### 产物优化
- PPT：按技术模块分段
- 报告：增加"实践指南"章节
- 测试题：增加代码理解题


## 4. 产物生成稳定性

### 当前问题
- 思维导图生成失败
- 播客下载失败
- 无等待和重试机制

### 优化方案
```bash
# 轮询等待产物完成
wait_for_artifact() {
  local artifact_id=$1
  local max_wait=600  # 10分钟
  
  for i in {1..60}; do
    status=$(notebooklm artifact status -a "$artifact_id" --json | jq -r '.status')
    [[ "$status" == "completed" ]] && return 0
    sleep 10
  done
  return 1
}

# 重试下载
download_with_retry() {
  for i in {1..3}; do
    notebooklm download "$@" && return 0
    sleep 5
  done
  return 1
}
```


## 5. Deep Research 集成

### 触发条件
- 无 --material 参数，仅有 --topic
- 检测到研究类关键词（"深入研究"、"全面了解"）
- 用户明确要求 deep research

### 实现方式
```bash
if [[ ${#MATERIALS[@]} -eq 0 ]]; then
  echo "🔬 Triggering Deep Research mode..."
  notebooklm research "$TOPIC" -n "$NOTEBOOK_ID" --depth deep
fi
```

### 预期效果
- Gemini 自动搜索 15+ 源
- 综合多个视角
- 生成深度研究报告


## 6. 评分系统改进

### LLM 评分脚本修复
```bash
# 使用 OpenClaw 的 image tool 调用 LLM
RESPONSE=$(echo "$GRADING_PROMPT" | openclaw chat --stdin --json)

# 或直接调用 API
curl -X POST https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -d "{\"model\":\"claude-sonnet-4-6\",\"messages\":[...]}"
```

### 评分标准调整
- Phase 1: 源类型识别 +5，上传成功 +10，处理完成 +5
- Phase 3: 按产物重要性分配（报告 10、播客 10、PPT 10、思维导图 5、测试题 5）
- Phase 4: 可评估部分按比例计分


## 7. 实施优先级

### P0（立即修复）
1. ✅ 源类型检测与预处理（已完成）
2. 产物等待和下载逻辑
3. LLM 评分脚本修复

### P1（重要优化）
4. Deep Research 集成
5. 重试机制
6. 延伸阅读扩展

### P2（增强功能）
7. 技术文章特殊处理
8. 架构图生成
9. 学习路径规划

---

## 测试结果总结

**Test Case 6 (X 文章)：75/100 ✅ Pass**

**优点：**
- 报告质量优秀（20/20）
- 技术深度准确
- 结构清晰完整

**改进空间：**
- 产物完整性（3/5）
- 下载稳定性
- 自动化程度

**下一步：**
执行完整测试矩阵（8 个场景），验证各类资源处理能力。

