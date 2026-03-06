---
name: weixin-extractor
description: 微信公众号文章内容提取。输入微信文章 URL，返回标准化 Markdown 内容。
---

# 微信文章提取器

从微信公众号文章 URL 提取清洗后的内容。

## 接口

遵循 content-bridge 标准接口（见 `../content-bridge/INTERFACE.md`）

## 使用

```bash
weixin-extractor "https://mp.weixin.qq.com/s/xxx"
```

## 实现

使用 MCP weixin-reader 或 web scraping
