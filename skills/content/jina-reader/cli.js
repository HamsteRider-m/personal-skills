#!/usr/bin/env node
// Jina Reader CLI

const jinaReader = require('./index');

async function main() {
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    console.log('Usage: jina-reader <url>');
    console.log('       jina-reader batch <url1> <url2> ...');
    process.exit(1);
  }
  
  if (args[0] === 'batch') {
    // 批量模式
    const urls = args.slice(1);
    console.log(`Fetching ${urls.length} URLs...\n`);
    
    const results = await jinaReader.batchFetch(urls);
    
    for (const result of results) {
      console.log('─'.repeat(60));
      console.log('URL:', result.url);
      console.log('Status:', result.success ? '✅ Success' : '❌ Failed');
      
      if (result.success) {
        console.log('Title:', result.data.title);
        console.log('\nContent preview:');
        console.log(result.data.content.substring(0, 500));
      } else {
        console.log('Error:', result.error);
      }
      console.log();
    }
  } else {
    // 单 URL 模式
    const url = args[0];
    console.log(`Fetching: ${url}\n`);
    
    try {
      const result = await jinaReader.fetchContent(url);
      
      console.log('Title:', result.title);
      console.log('Source:', result.url);
      if (result.publishedTime) {
        console.log('Published:', result.publishedTime);
      }
      console.log('\n' + '='.repeat(60));
      console.log(result.content);
    } catch (error) {
      console.error('Error:', error.message);
      process.exit(1);
    }
  }
}

main().catch(console.error);