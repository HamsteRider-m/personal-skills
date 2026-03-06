#!/usr/bin/env node
import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const CONFIG = {
  batchesFile: path.join(__dirname, 'batches.json'),
  progressFile: path.join(__dirname, 'progress.json'),
  outputDir: '/Users/maygo/Library/CloudStorage/OneDrive-个人/obsidian-vault/Projects/工作归档',
  userDataDir: path.join(__dirname, 'browser-data'),
  reportInterval: 5 * 60 * 1000
};

const { batches } = JSON.parse(fs.readFileSync(CONFIG.batchesFile, 'utf8'));
const allDocs = batches.flat();

let progress = { completed: 0, failed: [], lastReport: Date.now(), results: [] };
if (fs.existsSync(CONFIG.progressFile)) {
  progress = JSON.parse(fs.readFileSync(CONFIG.progressFile, 'utf8'));
}

function saveProgress() {
  fs.writeFileSync(CONFIG.progressFile, JSON.stringify(progress, null, 2));
}

function ensureDir(dir) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

function sanitize(name) {
  return name.replace(/[\/\\:*?"<>|]/g, '_').substring(0, 100);
}

async function extractDocContent(page) {
  await page.waitForTimeout(3000);
  const content = await page.evaluate(() => {
    const main = document.querySelector('[role="main"]') || document.body;
    return main.innerText || '';
  });
  return content;
}

async function processDoc(page, doc) {
  try {
    await page.goto(doc.url, { waitUntil: 'domcontentloaded', timeout: 60000 });
    const content = await extractDocContent(page);
    
    if (content.includes('扫码登录') || content.includes('账号登录')) {
      throw new Error('需要登录');
    }
    
    const categoryDir = path.join(CONFIG.outputDir, doc.category);
    ensureDir(categoryDir);
    
    const filename = `${sanitize(doc.name)}.md`;
    const frontmatter = `---
title: ${doc.name}
category: ${doc.category}
source: 工作飞书
url: ${doc.url}
exported_at: ${new Date().toISOString()}
---

`;
    
    fs.writeFileSync(path.join(categoryDir, filename), frontmatter + content, 'utf8');
    
    progress.completed++;
    progress.results.push({ id: doc.id, name: doc.name, status: 'success' });
    
    console.log(`✓ [${progress.completed}/${allDocs.length}] ${doc.name}`);
    
  } catch (err) {
    progress.failed.push({ id: doc.id, name: doc.name, error: err.message });
    console.error(`✗ ${doc.name}: ${err.message}`);
  } finally {
    saveProgress();
  }
}

async function main() {
  console.log('启动浏览器，等待 10 秒让你登录...');
  console.log(`总文档数: ${allDocs.length}\n`);
  
  const browser = await chromium.launchPersistentContext(CONFIG.userDataDir, {
    headless: false,
    args: ['--disable-blink-features=AutomationControlled']
  });
  
  const page = await browser.newPage();
  await page.goto('https://ottno-cd.feishu.cn/drive/home/');
  
  console.log('等待 10 秒...');
  await page.waitForTimeout(10000);
  
  console.log('\n开始导出...\n');
  
  const startFrom = progress.completed;
  
  for (let i = startFrom; i < allDocs.length; i++) {
    await processDoc(page, allDocs[i]);
    
    if (Date.now() - progress.lastReport > CONFIG.reportInterval) {
      console.log(`\n进度: ${progress.completed}/${allDocs.length} (${Math.round(progress.completed/allDocs.length*100)}%)`);
      console.log(`失败: ${progress.failed.length}\n`);
      progress.lastReport = Date.now();
    }
  }
  
  await browser.close();
  
  console.log(`\n✓ 完成！成功: ${progress.completed - progress.failed.length} 失败: ${progress.failed.length}`);
}

main().catch(console.error);
