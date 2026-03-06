#!/usr/bin/env node
/**
 * 自动批量导出飞书文档
 * Headless 模式，后台运行，每 5 分钟报告进度
 */

const fs = require('fs');
const path = require('path');

const CONFIG = {
  batchesFile: path.join(__dirname, 'batches.json'),
  progressFile: path.join(__dirname, 'progress.json'),
  outputDir: '/Users/maygo/Library/CloudStorage/OneDrive-个人/obsidian-vault/Projects/工作归档',
  targetId: 'CC074F4EEB55CC58F90083D3AF5A7676',
  reportInterval: 5 * 60 * 1000 // 5 分钟
};

// 读取批次
const { batches } = JSON.parse(fs.readFileSync(CONFIG.batchesFile, 'utf8'));

// 读取或初始化进度
let progress = { completed: 0, failed: [], lastReport: Date.now() };
if (fs.existsSync(CONFIG.progressFile)) {
  progress = JSON.parse(fs.readFileSync(CONFIG.progressFile, 'utf8'));
}

// 保存进度
function saveProgress() {
  fs.writeFileSync(CONFIG.progressFile, JSON.stringify(progress, null, 2));
}

// 确保目录存在
function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

// 生成安全文件名
function sanitizeFilename(name) {
  return name.replace(/[\/\\:*?"<>|]/g, '_').substring(0, 100);
}

console.log('开始批量导出...');
console.log(`总文档数: ${batches.flat().length}`);
console.log(`已完成: ${progress.completed}`);
console.log(`剩余: ${batches.flat().length - progress.completed}\n`);

module.exports = { CONFIG, batches, progress, saveProgress, ensureDir, sanitizeFilename };
