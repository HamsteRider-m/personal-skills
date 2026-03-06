#!/usr/bin/env node
const { getTenantToken, callFeishuAPI, CONFIG, ensureDir } = require('./archive.js');
const fs = require('fs');
const path = require('path');

// 列出云空间文件
async function listDriveFiles(token, folderToken = null) {
  const params = new URLSearchParams({
    page_size: 50,
    ...(folderToken && { folder_token: folderToken })
  });
  
  const result = await callFeishuAPI(token, 'GET', `/open-apis/drive/v1/files?${params}`);
  return result;
}

// 读取文档内容
async function readDocument(token, docToken) {
  const result = await callFeishuAPI(token, 'GET', `/open-apis/docx/v1/documents/${docToken}/raw_content`);
  return result;
}

// 保存文档到本地
function saveToObsidian(filename, content, metadata = {}) {
  ensureDir(CONFIG.obsidianPath);
  
  const frontmatter = `---
title: ${metadata.title || filename}
source: feishu
doc_token: ${metadata.doc_token || ''}
exported_at: ${new Date().toISOString()}
tags: [工作归档, 飞书]
---

`;
  
  const fullContent = frontmatter + content;
  const filepath = path.join(CONFIG.obsidianPath, `${filename}.md`);
  fs.writeFileSync(filepath, fullContent, 'utf8');
  console.log(`✓ 已保存: ${filepath}`);
  return filepath;
}

// 主函数
async function main() {
  const cmd = process.argv[2] || 'list';
  
  try {
    console.log('获取访问令牌...');
    const token = await getTenantToken();
    
    if (cmd === 'list') {
      console.log('\n列出云空间文件...');
      const files = await listDriveFiles(token);
      
      if (files.code === 0 && files.data?.files) {
        console.log(`\n找到 ${files.data.files.length} 个文件:\n`);
        files.data.files.forEach((file, i) => {
          console.log(`${i+1}. [${file.type}] ${file.name}`);
          console.log(`   Token: ${file.token}`);
        });
      } else {
        console.log('返回:', JSON.stringify(files, null, 2));
      }
    } else if (cmd === 'export') {
      const docToken = process.argv[3];
      if (!docToken) {
        console.error('用法: node list-export.js export <doc_token>');
        process.exit(1);
      }
      
      console.log(`\n读取文档 ${docToken}...`);
      const doc = await readDocument(token, docToken);
      
      if (doc.code === 0 && doc.data?.content) {
        const filename = `doc_${docToken}_${Date.now()}`;
        saveToObsidian(filename, doc.data.content, {
          doc_token: docToken,
          title: filename
        });
      } else {
        console.log('返回:', JSON.stringify(doc, null, 2));
      }
    }
  } catch (err) {
    console.error('错误:', err.message);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}
