#!/usr/bin/env node
/**
 * 本地文档处理工具
 * 读取手动导出的文档，AI 分析主题，整理到 Obsidian
 * 
 * 用法:
 * 1. 从飞书手动导出文档到 ~/Downloads/工作文档/
 * 2. 运行: node local-process.js
 */

const fs = require('fs');
const path = require('path');

const CONFIG = {
  inputDir: path.join(process.env.HOME, 'Downloads/工作文档'),
  outputDir: '/Users/maygo/Library/CloudStorage/OneDrive-个人/obsidian-vault/Projects/工作归档',
  indexFile: 'INDEX.md'
};

// 确保目录存在
function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

// 扫描输入目录
function scanInputFiles() {
  ensureDir(CONFIG.inputDir);
  const files = fs.readdirSync(CONFIG.inputDir);
  return files.filter(f => 
    f.endsWith('.md') || 
    f.endsWith('.txt') || 
    f.endsWith('.docx')
  );
}

// 读取文件内容
function readFile(filename) {
  const filepath = path.join(CONFIG.inputDir, filename);
  return fs.readFileSync(filepath, 'utf8');
}

// 保存到 Obsidian
function saveToObsidian(category, filename, content, metadata = {}) {
  const categoryDir = path.join(CONFIG.outputDir, category);
  ensureDir(categoryDir);
  
  const frontmatter = `---
title: ${metadata.title || filename}
category: ${category}
source: 工作飞书
exported_at: ${new Date().toISOString()}
tags: [工作归档, ${category}]
---

`;
  
  const outputPath = path.join(categoryDir, filename);
  fs.writeFileSync(outputPath, frontmatter + content, 'utf8');
  return outputPath;
}

// 生成索引
function generateIndex(processed) {
  const grouped = {};
  for (const item of processed) {
    if (!grouped[item.category]) grouped[item.category] = [];
    grouped[item.category].push(item);
  }
  
  let index = `# 工作文档归档索引\n\n`;
  index += `**生成时间:** ${new Date().toLocaleString('zh-CN')}\n`;
  index += `**文档总数:** ${processed.length}\n\n`;
  
  for (const [category, items] of Object.entries(grouped)) {
    index += `## ${category} (${items.length})\n\n`;
    for (const item of items) {
      index += `- [[${item.filename}|${item.title}]]\n`;
    }
    index += `\n`;
  }
  
  fs.writeFileSync(
    path.join(CONFIG.outputDir, CONFIG.indexFile),
    index,
    'utf8'
  );
}

// 主函数
async function main() {
  console.log('扫描输入目录:', CONFIG.inputDir);
  const files = scanInputFiles();
  
  if (files.length === 0) {
    console.log('\n未找到文件。请先手动导出文档到:', CONFIG.inputDir);
    console.log('\n操作步骤:');
    console.log('1. 在飞书打开文档');
    console.log('2. 点击右上角 "..." → 导出 → Markdown');
    console.log('3. 保存到', CONFIG.inputDir);
    return;
  }
  
  console.log(`找到 ${files.length} 个文件\n`);
  
  const processed = [];
  
  for (const file of files) {
    console.log(`处理: ${file}`);
    const content = readFile(file);
    
    // 简单分类（后续可接入 AI）
    let category = '其他文档';
    if (file.includes('预算') || file.includes('降本')) category = '财务预算管理';
    else if (file.includes('纪要') || file.includes('会议')) category = '会议纪要';
    else if (file.includes('周工作报告')) category = '工作汇报';
    
    const outputPath = saveToObsidian(category, file, content, {
      title: file.replace(/\.(md|txt|docx)$/, '')
    });
    
    processed.push({
      filename: file,
      title: file.replace(/\.(md|txt|docx)$/, ''),
      category,
      path: outputPath
    });
    
    console.log(`  ✓ 已保存到: ${category}/${file}`);
  }
  
  generateIndex(processed);
  console.log(`\n✓ 完成！已处理 ${processed.length} 个文档`);
  console.log(`✓ 索引文件: ${path.join(CONFIG.outputDir, CONFIG.indexFile)}`);
}

main().catch(console.error);
