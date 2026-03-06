#!/usr/bin/env node
/**
 * 通过浏览器批量导出飞书文档
 */

const fs = require('fs');
const path = require('path');

const MANIFEST_PATH = path.join(__dirname, 'export-manifest.json');
const OUTPUT_DIR = '/Users/maygo/Library/CloudStorage/OneDrive-个人/obsidian-vault/Projects/工作归档';
const PROGRESS_FILE = path.join(__dirname, 'export-progress.json');

// 读取清单
const manifest = JSON.parse(fs.readFileSync(MANIFEST_PATH, 'utf8'));
const allDocs = [];

for (const [category, docs] of Object.entries(manifest.categories)) {
  for (const doc of docs) {
    allDocs.push({ ...doc, category });
  }
}

console.log(`总共 ${allDocs.length} 个文档`);
console.log(`输出目录: ${OUTPUT_DIR}`);
console.log('\n需要通过 OpenClaw browser 工具逐个访问并提取内容');
console.log('建议分批执行，每批 20-30 个文档\n');

// 生成批次
const BATCH_SIZE = 20;
const batches = [];
for (let i = 0; i < allDocs.length; i += BATCH_SIZE) {
  batches.push(allDocs.slice(i, i + BATCH_SIZE));
}

console.log(`已分为 ${batches.length} 批，每批 ${BATCH_SIZE} 个文档`);
console.log('\n第一批文档:');
batches[0].slice(0, 5).forEach((doc, i) => {
  console.log(`  ${i+1}. ${doc.name} (${doc.category})`);
});

// 保存批次信息
fs.writeFileSync(
  path.join(__dirname, 'batches.json'),
  JSON.stringify({ batches, batchSize: BATCH_SIZE }, null, 2)
);

console.log('\n✓ 批次信息已保存到 batches.json');
