---
name: document-parser
description: 文档解析器。支持 PDF/DOCX/EPUB 等格式，返回提取的文本内容。
---

# 文档解析器

解析各类文档格式，提取文本内容。

## 支持格式

- PDF
- DOCX
- EPUB
- PPTX
- XLSX

## 接口

遵循 content-bridge 标准接口

## 使用

```bash
document-parser "/path/to/file.pdf"
document-parser "https://example.com/doc.pdf"
```
