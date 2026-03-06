// Web Reader - 网页内容提取工具
// 支持双引擎：Defuddle (primary) + Jina AI (fallback)

const https = require('https');
const http = require('http');
const { URL } = require('url');

/**
 * 从任意 URL 提取内容
 * 优先使用 Defuddle，失败时回退到 Jina AI
 * @param {string} targetUrl - 目标网页 URL
 * @param {Object} options - 配置选项
 * @returns {Promise<{title: string, content: string, url: string, source: string}>}
 */
async function fetchContent(targetUrl, options = {}) {
  const { prefer = 'defuddle', timeout = 30000 } = options;
  
  // 清理 URL
  const cleanUrl = targetUrl.trim();
  
  // 根据偏好选择策略
  const engines = prefer === 'defuddle' 
    ? [fetchFromDefuddle, fetchFromJina]
    : [fetchFromJina, fetchFromDefuddle];
  
  let lastError = null;
  
  for (const engine of engines) {
    try {
      const result = await engine(cleanUrl, timeout);
      return { ...result, source: engine.name.replace('fetchFrom', '').toLowerCase() };
    } catch (error) {
      lastError = error;
      console.log(`Engine ${engine.name} failed: ${error.message}, trying fallback...`);
      continue;
    }
  }
  
  throw new Error(`All engines failed. Last error: ${lastError?.message}`);
}

/**
 * 使用 Defuddle 获取内容
 * API: curl defuddle.md/<URL> (without protocol)
 * Returns: Markdown with YAML frontmatter
 */
async function fetchFromDefuddle(targetUrl, timeout = 30000) {
  // Defuddle 期望的格式是 domain.com/path，不带协议头
  const urlWithoutProtocol = targetUrl.replace(/^https?:\/\//, '');
  const defuddleUrl = `https://defuddle.md/${urlWithoutProtocol}`;
  
  const response = await httpGet(defuddleUrl, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (compatible; WebReaderBot/1.0)',
      'Accept': 'text/markdown, text/plain, */*'
    },
    timeout
  });
  
  return parseDefuddleResponse(response, targetUrl);
}

/**
 * 使用 Jina AI 获取内容
 * API: https://r.jina.ai/http://<targetURL>
 */
async function fetchFromJina(targetUrl, timeout = 30000) {
  const jinaUrl = `https://r.jina.ai/http://${targetUrl.replace(/^https?:\/\//, '')}`;
  
  const response = await httpGet(jinaUrl, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (compatible; WebReaderBot/1.0)',
      'Accept': 'text/plain, text/markdown, */*'
    },
    timeout
  });
  
  return parseJinaResponse(response, targetUrl);
}

/**
 * HTTP GET 请求封装
 */
function httpGet(url, options = {}) {
  return new Promise((resolve, reject) => {
    const parsedUrl = new URL(url);
    const client = parsedUrl.protocol === 'https:' ? https : http;
    
    const req = client.get(url, {
      headers: options.headers || {},
      timeout: options.timeout || 30000
    }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        // 跟随重定向
        resolve(httpGet(res.headers.location, options));
        return;
      }
      
      if (res.statusCode !== 200) {
        reject(new Error(`HTTP ${res.statusCode}: ${res.statusMessage}`));
        return;
      }
      
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data));
    });
    
    req.on('error', reject);
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });
  });
}

/**
 * 解析 Defuddle 响应（YAML frontmatter + Markdown）
 */
function parseDefuddleResponse(rawText, originalUrl) {
  const lines = rawText.split('\n');
  
  let inFrontmatter = false;
  let frontmatterEnd = 0;
  let title = '';
  let url = originalUrl;
  
  // 解析 YAML frontmatter
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    
    if (line === '---') {
      if (!inFrontmatter) {
        inFrontmatter = true;
        continue;
      } else {
        frontmatterEnd = i;
        break;
      }
    }
    
    if (inFrontmatter) {
      const colonIndex = line.indexOf(':');
      if (colonIndex > 0) {
        const key = line.substring(0, colonIndex).trim();
        const value = line.substring(colonIndex + 1).trim().replace(/^["']|["']$/g, '');
        
        if (key === 'title') title = value;
        if (key === 'url') url = value;
      }
    }
  }
  
  // 提取正文（frontmatter 之后）
  const content = lines.slice(frontmatterEnd + 1).join('\n').trim();
  
  return {
    title: title || 'Untitled',
    url: url || originalUrl,
    content: content,
    raw: rawText
  };
}

/**
 * 解析 Jina AI 响应
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
  const { concurrency = 3, delay = 1000, prefer = 'defuddle' } = options;
  const results = [];
  
  for (let i = 0; i < urls.length; i += concurrency) {
    const batch = urls.slice(i, i + concurrency);
    const batchResults = await Promise.allSettled(
      batch.map(url => fetchContent(url, { prefer }))
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
  const { timeout = 10000, prefer = 'defuddle' } = options;
  
  return Promise.race([
    fetchContent(targetUrl, { prefer, timeout }),
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

// 保持向后兼容的别名
const fetchFromJinaAI = fetchContent;

module.exports = {
  fetchContent,
  fetchFromJinaAI,
  batchFetch,
  fetchWithTimeout,
  // 内部方法也导出，方便测试
  fetchFromDefuddle,
  fetchFromJina,
  parseDefuddleResponse,
  parseJinaResponse
};
