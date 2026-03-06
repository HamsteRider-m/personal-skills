---
name: web-reader
description: 通用网页内容提取。输入任意 URL，返回清洗后的 Markdown 内容。
---

# 通用网页提取器

从任意网页提取主要内容，过滤广告和无关元素。

## 接口

遵循 content-bridge 标准接口

## 使用

```bash
web-reader "https://example.com/article"
```

## 实现

整合 jina-reader 或使用 markitdown
