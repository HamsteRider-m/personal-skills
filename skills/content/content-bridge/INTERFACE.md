# Content Bridge Interface

## 标准输入

```json
{
  "url": "string (必需)",
  "options": {
    "format": "markdown | json (默认: markdown)",
    "max_length": "number (可选)",
    "include_metadata": "boolean (默认: true)"
  }
}
```

## 标准输出

```json
{
  "content": "string (Markdown 或 JSON 格式的内容)",
  "metadata": {
    "source": "string (原始 URL)",
    "title": "string (内容标题)",
    "author": "string (作者，如有)",
    "date": "string (ISO 8601 格式)",
    "extractor": "string (使用的摄取 skill 名称)",
    "word_count": "number (字数统计)"
  },
  "status": "success | error",
  "error": "string (仅当 status=error 时存在)"
}
```

## 路由规则

Content Bridge 根据 URL 模式自动路由到对应的摄取 skill：

| URL 模式 | 路由到 | 说明 |
|---------|--------|------|
| `mp.weixin.qq.com` | `weixin-extractor` | 微信公众号文章 |
| `bilibili.com`, `b23.tv` | `bilibili-subtitle` | B站视频字幕 |
| `youtube.com`, `youtu.be` | `youtube-transcript` | YouTube 视频转录 |
| `*.pdf`, `*.docx`, `*.epub` | `document-parser` | 文档解析 |
| 其他 HTTP(S) | `web-reader` | 通用网页提取 |

## 调用示例

### 命令行
```bash
content-bridge "https://mp.weixin.qq.com/s/xxx" --format markdown
```

### 编程接口
```python
from content_bridge import extract

result = extract(
    url="https://www.example.com/article",
    options={"format": "markdown", "include_metadata": True}
)

if result["status"] == "success":
    print(result["content"])
    print(f"Extracted by: {result['metadata']['extractor']}")
```

## 扩展新的摄取 Skill

要添加新的内容源支持：

1. 创建独立的摄取 skill（如 `twitter-extractor`）
2. 实现本接口规范
3. 在 content-bridge 的路由表中注册 URL 模式

## 兼容性

为保持向后兼容，content-bridge 保留 `anything-to-notebooklm` 别名：

```bash
# 两种调用方式等价
content-bridge "URL"
anything-to-notebooklm "URL"
```

别名将在 v2.0 移除，请尽快迁移到新名称。
