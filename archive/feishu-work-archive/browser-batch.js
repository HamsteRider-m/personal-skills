#!/usr/bin/env node
/**
 * 使用 OpenClaw browser 工具批量导出
 * 在同一个标签页中逐个访问
 */

const fs = require('fs');
const path = require('path');

const CONFIG = {
  batchesFile: path.join(__dirname, 'batches.json'),
  progressFile: path.join(__dirname, 'progress-browser.json'),
  outputDir: '/Users/maygo/Library/CloudStorage/OneDrive-个人/obsidian-vault/Projects/工作归档'
};

const { batches } = JSON.parse(fs.readFileSync(CONFIG.batchesFile, 'utf8'));
const allDocs = batches.flat();

let progress = { completed: 0, failed: [], results: [] };
if (fs.existsSync(CONFIG.progressFile)) {
  progress = JSON.parse(fs.readFileSync(CONFIG.progressFile, 'utf8'));
}

// 输出下一个要处理的文档
const nextDoc = allDocs[progress.completed];
if (!nextDoc) {
  console.log('全部完成！');
  process.exit(0);
}

console.log(JSON.stringify({
  action: 'next',
  doc: nextDoc,
  progress: `${progress.completed}/${allDocs.length}`
}));
