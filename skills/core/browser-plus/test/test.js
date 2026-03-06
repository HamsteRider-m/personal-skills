#!/usr/bin/env node
/**
 * Browser Plus - Test Suite
 * 
 * Run with: npm test or node test/test.js
 */

const assert = require('assert');
const path = require('path');

// Import modules to test
const detectors = require('../scripts/detectors');
const nativeBrowser = require('../scripts/adapters/native-browser');
const agentBrowser = require('../scripts/adapters/agent-browser');
const tweet = require('../scripts/composite/tweet');
const browserPlus = require('../index');

// Test utilities
let testsRun = 0;
let testsPassed = 0;
let testsFailed = 0;

function test(name, fn) {
  testsRun++;
  try {
    fn();
    console.log(`✓ ${name}`);
    testsPassed++;
  } catch (error) {
    console.error(`✗ ${name}`);
    console.error(`  Error: ${error.message}`);
    testsFailed++;
  }
}

async function asyncTest(name, fn) {
  testsRun++;
  try {
    await fn();
    console.log(`✓ ${name}`);
    testsPassed++;
  } catch (error) {
    console.error(`✗ ${name}`);
    console.error(`  Error: ${error.message}`);
    testsFailed++;
  }
}

console.log('\n🧪 Browser Plus Test Suite\n');
console.log('===========================\n');

// ==================== DETECTOR TESTS ====================
console.log('\n📋 Detector Tests:\n');

test('isRichTextEditor detects contenteditable', () => {
  const element = {
    tagName: 'div',
    attributes: { contenteditable: 'true' }
  };
  assert.strictEqual(detectors.isRichTextEditor(element), true);
});

test('isRichTextEditor detects tweet textarea', () => {
  const element = {
    tagName: 'div',
    attributes: { 'data-testid': 'tweetTextarea_0' }
  };
  assert.strictEqual(detectors.isRichTextEditor(element), true);
});

test('isRichTextEditor detects Draft.js editor', () => {
  const element = {
    tagName: 'div',
    attributes: { class: 'DraftEditor-root' }
  };
  assert.strictEqual(detectors.isRichTextEditor(element), true);
});

test('isRichTextEditor returns false for plain input', () => {
  const element = {
    tagName: 'input',
    attributes: { type: 'text' }
  };
  assert.strictEqual(detectors.isRichTextEditor(element), false);
});

test('getElementType returns RICH_TEXT for editors', () => {
  const element = {
    tagName: 'div',
    attributes: { contenteditable: 'true' }
  };
  assert.strictEqual(detectors.getElementType(element), 'RICH_TEXT');
});

test('getElementType returns PLAIN_INPUT for inputs', () => {
  const element = {
    tagName: 'input',
    attributes: { type: 'email' }
  };
  assert.strictEqual(detectors.getElementType(element), 'PLAIN_INPUT');
});

test('getElementType returns TEXTAREA for textareas', () => {
  const element = {
    tagName: 'textarea',
    attributes: {}
  };
  assert.strictEqual(detectors.getElementType(element), 'TEXTAREA');
});

test('isTwitterComposer detects Twitter composer', () => {
  const element = {
    tagName: 'div',
    attributes: { 'data-testid': 'tweetTextarea_0' }
  };
  assert.strictEqual(detectors.isTwitterComposer(element), true);
});

// ==================== ADAPTER INTERFACE TESTS ====================
console.log('\n🔌 Adapter Interface Tests:\n');

test('nativeBrowser exports required methods', () => {
  assert(typeof nativeBrowser.type === 'function', 'type should be a function');
  assert(typeof nativeBrowser.click === 'function', 'click should be a function');
  assert(typeof nativeBrowser.navigate === 'function', 'navigate should be a function');
  assert(typeof nativeBrowser.snapshot === 'function', 'snapshot should be a function');
});

test('agentBrowser exports required methods', () => {
  assert(typeof agentBrowser.type === 'function', 'type should be a function');
  assert(typeof agentBrowser.keypress === 'function', 'keypress should be a function');
  assert(typeof agentBrowser.click === 'function', 'click should be a function');
  assert(typeof agentBrowser.navigate === 'function', 'navigate should be a function');
  assert(typeof agentBrowser.isAvailable === 'function', 'isAvailable should be a function');
});

// ==================== BROWSER PLUS API TESTS ====================
console.log('\n🚀 Browser Plus API Tests:\n');

test('browserPlus exports required methods', () => {
  assert(typeof browserPlus.type === 'function', 'type should be a function');
  assert(typeof browserPlus.click === 'function', 'click should be a function');
  assert(typeof browserPlus.navigate === 'function', 'navigate should be a function');
  assert(typeof browserPlus.snapshot === 'function', 'snapshot should be a function');
  assert(typeof browserPlus.tweet === 'function', 'tweet should be a function');
  assert(typeof browserPlus.detectAndRoute === 'function', 'detectAndRoute should be a function');
});

test('browserPlus.config has default values', () => {
  assert(browserPlus.config.preferNative === true, 'preferNative should default to true');
  assert(browserPlus.config.fallbackToAgent === true, 'fallbackToAgent should default to true');
  assert(browserPlus.config.agentBrowserTimeout === 60000, 'agentBrowserTimeout should default to 60000');
});

// ==================== TWEET COMPOSITE TESTS ====================
console.log('\n🐦 Tweet Composite Tests:\n');

test('tweet module exports required methods', () => {
  assert(typeof tweet.post === 'function', 'post should be a function');
  assert(typeof tweet.postWithMedia === 'function', 'postWithMedia should be a function');
  assert(typeof tweet.reply === 'function', 'reply should be a function');
});

test('tweet.validateText validates text length', () => {
  // Should not throw for valid text
  tweet.validateText('Hello world');
  
  // Should throw for empty text
  assert.throws(() => tweet.validateText(''), /Tweet text cannot be empty/);
  
  // Should throw for text too long
  const longText = 'a'.repeat(300);
  assert.throws(() => tweet.validateText(longText), /exceeds maximum length/);
});

// ==================== ERROR HANDLING TESTS ====================
console.log('\n⚠️  Error Handling Tests:\n');

asyncTest('type throws on missing ref', async () => {
  try {
    await browserPlus.type({ text: 'hello' });
    assert.fail('Should have thrown');
  } catch (error) {
    assert(error.message.includes('ref is required'));
  }
});

asyncTest('type throws on missing text', async () => {
  try {
    await browserPlus.type({ ref: '@e12' });
    assert.fail('Should have thrown');
  } catch (error) {
    assert(error.message.includes('text is required'));
  }
});

asyncTest('tweet.post throws on missing text', async () => {
  try {
    await tweet.post({});
    assert.fail('Should have thrown');
  } catch (error) {
    assert(error.message.includes('Tweet text is required'));
  }
});

// ==================== SUMMARY ====================
console.log('\n===========================\n');
console.log(`📊 Test Results:`);
console.log(`   Total:  ${testsRun}`);
console.log(`   Passed: ${testsPassed} ✅`);
console.log(`   Failed: ${testsFailed} ❌`);
console.log('');

if (testsFailed > 0) {
  console.log('❌ Some tests failed\n');
  process.exit(1);
} else {
  console.log('✅ All tests passed!\n');
  process.exit(0);
}
