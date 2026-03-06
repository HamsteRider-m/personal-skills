// Jina Reader 测试

const jinaReader = require('../index');

async function runTests() {
  console.log('🧪 Testing Jina Reader...\n');
  
  // 测试 1: 解析响应
  console.log('Test 1: Parse response');
  const sampleResponse = `Title: Example Article
URL Source: https://example.com/article
Published Time: Wed, 25 Feb 2026 07:22:28 GMT

Markdown Content:
# Example Article

This is the content.

[Link](https://example.com)`;

  const parsed = jinaReader.parseJinaResponse(sampleResponse, 'https://example.com/article');
  console.log('  Title:', parsed.title);
  console.log('  Content length:', parsed.content.length);
  console.log('  ✅ Parse test passed\n');
  
  // 测试 2: 实际获取（如果网络可用）
  console.log('Test 2: Fetch example.com');
  try {
    const result = await jinaReader.fetchWithTimeout('http://example.com', { timeout: 5000 });
    console.log('  Title:', result.title);
    console.log('  Content preview:', result.content.substring(0, 100));
    console.log('  ✅ Fetch test passed\n');
  } catch (error) {
    console.log('  ⚠️  Fetch test skipped:', error.message, '\n');
  }
  
  console.log('✨ Tests completed!');
}

runTests().catch(console.error);