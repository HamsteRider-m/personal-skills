---
name: jina-reader
description: Extract clean text content from any webpage using r.jina.ai service. Use when needing to fetch article content, social media posts, or any web page text without dealing with paywalls, login walls, or complex HTML parsing. Automatically converts web pages to clean Markdown format.
---

# Jina Reader

使用 r.jina.ai 服务提取任意网页的干净文本内容。

## 核心能力

- 🚀 **绕过限制** - 自动处理登录墙、付费墙
- 📝 **干净输出** - 返回结构化 Markdown，无广告/导航
- 🔍 **广泛支持** - Twitter/X、新闻网站、博客等
- ⚡ **无需配置** - 零 API key，即开即用

## 使用方法

### 基础用法

```javascript
const { fetchContent } = require('./skills/jina-reader');

// 获取任意网页内容
const result = await fetchContent('https://example.com/article');
console.log(result.title);
console.log(result.content);
```

### 支持的网站

| 类型 | 示例 |
|------|------|
| 社交媒体 | Twitter/X, Reddit |
| 新闻网站 | NYT, WSJ (绕过付费墙) |
| 博客 | Medium, Substack |
| 文档 | GitHub, ReadTheDocs |
| 任意网页 | 任何公开 URL |

### 高级用法

```javascript
const jinaReader = require('./skills/jina-reader');

// 批量获取
const urls = [
  'https://twitter.com/user/status/123',
  'https://example.com/news/456'
];
const results = await jinaReader.batchFetch(urls);

// 带超时控制
const result = await jinaReader.fetchWithTimeout(url, { timeout: 10000 });
```

## 工作原理

通过 `https://r.jina.ai/http://<目标URL>` 接口：
1. Jina AI 抓取目标网页
2. 提取正文内容
3. 转换为 Markdown 格式
4. 返回结构化数据

## 注意事项

- 免费服务，可能有速率限制
- 不适合需要 JavaScript 渲染的动态内容
- 私有/需要登录的内容可能无法访问