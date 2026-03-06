#!/usr/bin/env node
/**
 * 批量导出飞书工作文档到 Obsidian
 * 用法: node batch-export.js <doc-list.md>
 */

const fs = require('fs');
const path = require('path');

const OBSIDIAN_BASE = '/Users/maygo/Library/CloudStorage/OneDrive-个人/obsidian-vault/Projects/工作归档';
const DOC_LIST_PATH = process.argv[2] || '/Users/maygo/.openclaw/media/inbound/梅杭俊_云文档列表---eb5002fd-4e2c-47d6-880a-e941538a424f';

// 解析文档列表
function parseDocList(content) {
  const lines = content.split('\n');
  const docs = [];
  
  for (const line of lines) {
    const match = line.match(/\|\s*(\d+)\s*\|\s*(.+?)\s*\|\s*(https:\/\/[^\s]+)/);
    if (match) {
      const [, id, name, url] = match;
      const tokenMatch = url.match(/\/([a-zA-Z0-9]+)$/);
      if (tokenMatch) {
        docs.push({
          id: parseInt(id),
          name: name.trim(),
          url: url.trim(),
          token: tokenMatch[1]
        });
      }
    }
  }
  
  return docs;
}

// 主题分类规则
function categorizeDoc(name) {
  if (name.includes('降本') || name.includes('预算') || name.includes('EBITDA') || name.includes('现金流')) {
    return '财务预算管理';
  }
  if (name.includes('智能纪要') || name.includes('文字记录') || name.includes('会议速递')) {
    return '会议纪要';
  }
  if (name.includes('周工作报告') || name.includes('工作汇报')) {
    return '工作汇报';
  }
  if (name.includes('Excel') || name.includes('PowerQuery') || name.includes('多维表格') || name.includes('技术文档')) {
    return '技术工具';
  }
  if (name.includes('门店') || name.includes('闭店') || name.includes('经营分析')) {
    return '运营管理';
  }
  return '其他文档';
}

// 生成安全文件名
function sanitizeFilename(name) {
  return name
    .replace(/[\/\\:*?"<>|]/g, '_')
    .replace(/\s+/g, '_')
    .substring(0, 100);
}

// 主函数
async function main() {
  console.log('读取文档列表...');
  const content = fs.readFileSync(DOC_LIST_PATH, 'utf8');
  const docs = parseDocList(content);
  
  console.log(`找到 ${docs.length} 个文档\n`);
  
  // 按主题分组
  const grouped = {};
  for (const doc of docs) {
    const category = categorizeDoc(doc.name);
    if (!grouped[category]) grouped[category] = [];
    grouped[category].push(doc);
  }
  
  // 输出分类统计
  console.log('文档分类统计:');
  for (const [category, items] of Object.entries(grouped)) {
    console.log(`  ${category}: ${items.length} 个`);
  }
  
  // 生成导出清单
  const manifest = {
    total: docs.length,
    categories: grouped,
    exportTime: new Date().toISOString(),
    obsidianPath: OBSIDIAN_BASE
  };
  
  fs.writeFileSync(
    path.join(__dirname, 'export-manifest.json'),
    JSON.stringify(manifest, null, 2)
  );
  
  console.log('\n✓ 导出清单已生成: export-manifest.json');
  console.log('\n下一步: 使用 OpenClaw feishu_doc 工具批量读取文档');
}

main().catch(console.error);
