# Phase 2: 拆分独立摄取 Skills

## 目标
将 content-bridge 内部的平台特定抓取逻辑拆分为独立的摄取 skills，使 content-bridge 成为纯路由层。

## 要创建的 Skills

### 1. weixin-extractor
- **路径**: `skills/content/weixin-extractor/`
- **职责**: 微信公众号文章提取
- **输入**: 微信文章 URL (mp.weixin.qq.com)
- **输出**: 标准格式 (参考 content-bridge/INTERFACE.md)
- **实现**: 使用 MCP weixin-reader 或现有逻辑

### 2. youtube-transcript
- **路径**: `skills/content/youtube-transcript/`
- **职责**: YouTube 视频字幕/转录提取
- **输入**: YouTube URL
- **输出**: 标准格式
- **实现**: 提取现有 YouTube 处理逻辑

### 3. web-reader
- **路径**: `skills/content/web-reader/`
- **职责**: 通用网页内容提取
- **输入**: 任意 HTTP(S) URL
- **输出**: 标准格式
- **实现**: 整合 jina-reader 或使用 markitdown

### 4. document-parser
- **路径**: `skills/content/document-parser/`
- **职责**: PDF/DOCX/EPUB 等文档解析
- **输入**: 文档路径或 URL
- **输出**: 标准格式
- **实现**: 使用 markitdown

## 标准接口规范

所有摄取 skill 必须实现相同接口（详见 `content-bridge/INTERFACE.md`）：

**输入**:
```json
{
  "url": "string",
  "options": {
    "format": "markdown | json",
    "max_length": "number",
    "include_metadata": "boolean"
  }
}
```

**输出**:
```json
{
  "content": "string",
  "metadata": {
    "source": "string",
    "title": "string",
    "author": "string",
    "date": "ISO 8601",
    "extractor": "skill名称",
    "word_count": "number"
  },
  "status": "success | error",
  "error": "string"
}
```

## content-bridge 改造

将 content-bridge 改造为纯路由层：

1. 移除所有平台特定的抓取实现代码
2. 保留路由逻辑：根据 URL 判断调用哪个 skill
3. 实现统一的调用接口
4. 处理错误和回退

**路由表**:
```python
ROUTES = {
    r'mp\.weixin\.qq\.com': 'weixin-extractor',
    r'(bilibili\.com|b23\.tv)': 'bilibili-subtitle',
    r'(youtube\.com|youtu\.be)': 'youtube-transcript',
    r'\.(pdf|docx|epub)$': 'document-parser',
    r'^https?://': 'web-reader'  # 默认
}
```

## 实施步骤

1. 创建 branch: `feature/content-extractors`
2. 为每个新 skill 创建目录结构和 SKILL.md
3. 从 content-bridge 提取对应逻辑到各 skill
4. 实现标准接口
5. 更新 content-bridge 为路由层
6. 编写测试验证接口一致性
7. 更新 MANIFEST.md

## 验收标准

- [ ] 4 个新 skill 目录创建完成
- [ ] 每个 skill 有完整的 SKILL.md
- [ ] 所有 skill 实现标准接口
- [ ] content-bridge 成功改造为路由层
- [ ] 至少 2 个 URL 类型的端到端测试通过
- [ ] MANIFEST.md 已更新

## 预计时间
5-7 天

## 注意事项
- 保持向后兼容：content-bridge 仍可直接调用
- 错误处理：每个 skill 独立处理错误
- 依赖管理：各 skill 独立管理依赖（requirements.txt）
