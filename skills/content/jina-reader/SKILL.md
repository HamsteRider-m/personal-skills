---
name: web-reader
description: Extract clean text content from any webpage using Defuddle (primary) or Jina AI (fallback). Use when needing to fetch article content, social media posts, or any web page text without dealing with paywalls, login walls, or complex HTML parsing. Automatically converts web pages to clean Markdown format.
---

# Web Reader

使用 Defuddle 或 Jina AI 服务提取任意网页的干净文本内容。

## 核心能力

- 🚀 **双引擎支持** - Defuddle (Obsidian CEO 出品) + Jina AI 自动回退
- 📝 **干净输出** - 返回结构化 Markdown，无广告/导航
- 🔍 **广泛支持** - Twitter/X、新闻网站、博客等
- ⚡ **无需配置** - 零 API key，即开即用
- 🛡️ **可靠容错** - 主引擎失败自动切换备用引擎

## 使用方法

### 基础用法

```javascript
const { fetchContent } = require('./skills/web-reader');

// 获取任意网页内容（默认优先使用 Defuddle）
const result = await fetchContent('https://example.com/article');
console.log(result.title);
console.log(result.content);
console.log(result.source); // 'defuddle' 或 'jina'
```

### 指定引擎偏好

```javascript
const webReader = require('./skills/web-reader');

// 优先使用 Jina AI
const result = await webReader.fetchContent(url, { prefer: 'jina' });

// 强制使用特定引擎
const defuddleResult = await webReader.fetchFromDefuddle(url);
const jinaResult = await webReader.fetchFromJina(url);
```

### 批量获取

```javascript
const urls = [
  'https://twitter.com/user/status/123',
  'https://example.com/news/456'
];
const results = await webReader.batchFetch(urls);
```

## 支持的网站

| 类型 | 示例 |
|------|------|
| 社交媒体 | Twitter/X, Reddit |
| 新闻网站 | NYT, WSJ (绕过付费墙) |
| 博客 | Medium, Substack |
| 文档 | GitHub, ReadTheDocs |
| 任意网页 | 任何公开 URL |

## 工作原理

### Defuddle (Primary)
- 由 Obsidian CEO @kepano 开发
- 开源库：https://github.com/kepano/defuddle
- 在线服务：`https://defuddle.md/<目标URL>`
- 返回带 YAML frontmatter 的 Markdown

### Jina AI (Fallback)
- 通过 `https://r.jina.ai/http://<目标URL>` 接口
- Jina AI 抓取并提取正文
- 转换为 Markdown 格式

## 注意事项

- 免费服务，可能有速率限制
- 不适合需要 JavaScript 渲染的动态内容
- 私有/需要登录的内容可能无法访问
- 微信公众号文章通常无法访问（两种引擎都一样）
