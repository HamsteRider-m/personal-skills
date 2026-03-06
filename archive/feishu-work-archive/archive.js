#!/usr/bin/env node
/**
 * 飞书工作文档归档工具
 * 用途：导出工作飞书文档到 Obsidian，AI 分析主题并整理
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

// 配置
const CONFIG = {
  appId: 'cli_a75960290439500d',
  appSecret: 'tBd5CYrc3jFTa4yQ9aD3whBMyMvDfl2w',
  obsidianPath: '/Users/maygo/Library/CloudStorage/OneDrive-个人/obsidian-vault/Projects/工作归档',
  domain: 'feishu.cn'
};

// 确保输出目录存在
function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

// 获取 tenant_access_token
async function getTenantToken() {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({
      app_id: CONFIG.appId,
      app_secret: CONFIG.appSecret
    });

    const options = {
      hostname: `open.${CONFIG.domain}`,
      path: '/open-apis/auth/v3/tenant_access_token/internal',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        const result = JSON.parse(body);
        if (result.code === 0) {
          resolve(result.tenant_access_token);
        } else {
          reject(new Error(`获取 token 失败: ${JSON.stringify(result)}`));
        }
      });
    });

    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

// 通用 API 调用
async function callFeishuAPI(token, method, path, data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: `open.${CONFIG.domain}`,
      path: path,
      method: method,
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    };

    if (data) {
      const jsonData = JSON.stringify(data);
      options.headers['Content-Length'] = jsonData.length;
    }

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          const result = JSON.parse(body);
          resolve(result);
        } catch (e) {
          reject(new Error(`解析响应失败: ${body}`));
        }
      });
    });

    req.on('error', reject);
    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

module.exports = {
  CONFIG,
  ensureDir,
  getTenantToken,
  callFeishuAPI
};
