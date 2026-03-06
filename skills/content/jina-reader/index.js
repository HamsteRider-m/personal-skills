// Jina Reader - 网页内容提取工具
// 使用 r.jina.ai 服务获取干净文本

const https = require('https');
const http = require('http');
const { URL } = require('url');

/**
 * 从任意 URL 提取内容
 * @param {string} targetUrl - 目标网页 URL
 * @returns {Promise<{title: string, content: string, url: string}>}
 */
async function fetchContent(targetUrl) {
  // 构建 r.jina.ai 请求 URL
  const jinaUrl = `https://r.jina.ai/http://${targetUrl.replace(/^https?:\/\//, '')}`;
  
  return new Promise((resolve, reject) => {
    const url = new URL(jinaUrl);
    const client = url.protocol === 'https:' ? https : http;
    
    const req = client.get(jinaUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; JinaReaderBot/1.0)',
        'Accept': 'text/plain, text/markdown, */*'
      },
      timeout: 30000
    }, (res) => {
      let data = '';
      
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const result = parseJinaResponse(data, targetUrl);
          resolve(result);
        } catch (error) {
          reject(new Error(`Parse error: ${error.message}`));
        }
      });
    });
    
    req.on('error', reject);
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });
  });
}

/**
 * 解析 Jina AI 返回的内容
 */
function parseJinaResponse(rawText, originalUrl) {
  const lines = rawText.split('\n');
  
  let title = '';
  let url = originalUrl;
  let publishedTime = '';
  let contentStartIndex = 0;
  
  // 解析头部元数据
  for (let i = 0; i < Math.min(lines.length, 20); i++) {
    const line = lines[i].trim();
    
    if (line.startsWith('Title:')) {
      title = line.replace('Title:', '').trim();
    } else if (line.startsWith('URL Source:')) {
      url = line.replace('URL Source:', '').trim();
    } else if (line.startsWith('Published Time:')) {
      publishedTime = line.replace('Published Time:', '').trim();
    } else if (line === 'Markdown Content:') {
      contentStartIndex = i + 1;
      break;
    }
  }
  
  // 提取正文内容
  const content = lines.slice(contentStartIndex).join('\n').trim();
  
  return {
    title: title || 'Untitled',
    url: url,
    publishedTime: publishedTime,
    content: content,
    raw: rawText
  };
}

/**
 * 批量获取多个 URL
 * @param {string[]} urls - URL 数组
 * @param {Object} options - 配置选项
 * @returns {Promise<Array>}
 */
async function batchFetch(urls, options = {}) {
  const { concurrency = 3, delay = 1000 } = options;
  const results = [];
  
  for (let i = 0; i < urls.length; i += concurrency) {
    const batch = urls.slice(i, i + concurrency);
    const batchResults = await Promise.allSettled(
      batch.map(url => fetchContent(url))
    );
    
    results.push(...batchResults.map((result, index) => ({
      url: batch[index],
      success: result.status === 'fulfilled',
      data: result.status === 'fulfilled' ? result.value : null,
      error: result.status === 'rejected' ? result.reason.message : null
    })));
    
    // 批次间延迟，避免触发速率限制
    if (i + concurrency < urls.length) {
      await sleep(delay);
    }
  }
  
  return results;
}

/**
 * 带超时的获取
 */
async function fetchWithTimeout(targetUrl, options = {}) {
  const { timeout = 10000 } = options;
  
  return Promise.race([
    fetchContent(targetUrl),
    new Promise((_, reject) => 
      setTimeout(() => reject(new Error('Timeout')), timeout)
    )
  ]);
}

/**
 * 睡眠辅助函数
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

module.exports = {
  fetchContent,
  batchFetch,
  fetchWithTimeout,
  parseJinaResponse
};