#!/usr/bin/env node
/**
 * Twitter/X Composite Action
 * 
 * One-click Twitter posting with smart element detection.
 * Handles the full flow: navigate → detect textarea → type → submit.
 */

const path = require('path');
const { execSync } = require('child_process');

// Import core modules
const detectors = require('../detectors');
const nativeBrowser = require('../adapters/native-browser');
const agentBrowser = require('../adapters/agent-browser');

const TWITTER_COMPOSE_URL = 'https://twitter.com/compose/tweet';
const MAX_TWEET_LENGTH = 280;

/**
 * Validate tweet text
 * @param {string} text - Tweet text to validate
 * @throws {Error} If validation fails
 */
function validateText(text) {
  if (!text || text.trim().length === 0) {
    throw new Error('Tweet text cannot be empty');
  }

  if (text.length > MAX_TWEET_LENGTH) {
    throw new Error(`Tweet text is ${text.length} characters, exceeds maximum length of ${MAX_TWEET_LENGTH}`);
  }
}

/**
 * Post a tweet with automatic element detection and routing
 * @param {Object} options
 * @param {string} options.text - Tweet text content
 * @param {string[]} [options.media] - Optional array of media file paths
 * @param {boolean} [options.dryRun=false] - If true, don't actually submit (for testing)
 * @param {string} [options.targetId] - Optional target tab ID
 * @returns {Promise<Object>} Result object
 */
async function post(options) {
  const { text, media = [], dryRun = false, targetId } = options;
  
  // Validate input
  validateText(text);

  const results = {
    success: false,
    steps: []
  };

  try {
    // Step 1: Navigate to Twitter compose
    console.log('[browser-plus] Navigating to Twitter compose...');
    const navResult = await nativeBrowser.navigate({
      url: TWITTER_COMPOSE_URL,
      targetId
    });
    results.steps.push({ step: 'navigate', ...navResult });
    
    if (!navResult.success) {
      throw new Error('Failed to navigate to Twitter compose');
    }

    // Wait for page to load
    await sleep(2000);

    // Step 2: Get snapshot to find textarea
    console.log('[browser-plus] Detecting tweet textarea...');
    const snapshotResult = await nativeBrowser.snapshot({ targetId, refs: 'aria' });
    
    if (!snapshotResult.success) {
      throw new Error('Failed to get page snapshot');
    }

    // Step 3: Find the tweet textarea
    const textareaRef = findTweetTextarea(snapshotResult.result);
    
    if (!textareaRef) {
      throw new Error('Could not find tweet textarea. Twitter UI may have changed.');
    }

    console.log(`[browser-plus] Found textarea at ref: ${textareaRef}`);

    // Step 4: Find element details and determine adapter
    const element = detectors.findElementByRef(snapshotResult.result, textareaRef);
    const elementType = detectors.getElementType(element);
    const useAgent = elementType === 'RICH_TEXT';
    
    console.log(`[browser-plus] Element type detected: ${elementType}, using ${useAgent ? 'agent-browser' : 'native browser'}`);

    // Step 5: Type the tweet
    console.log('[browser-plus] Typing tweet...');
    let typeResult;
    
    if (useAgent) {
      typeResult = await agentBrowser.type({
        ref: textareaRef,
        text: text,
        targetId
      });
    } else {
      typeResult = await nativeBrowser.type({
        ref: textareaRef,
        text: text,
        targetId
      });
    }
    
    results.steps.push({ step: 'type', ...typeResult });

    if (!typeResult.success) {
      throw new Error('Failed to type tweet text');
    }

    // Step 6: Upload media if provided
    if (media.length > 0) {
      console.log(`[browser-plus] Uploading ${media.length} media file(s)...`);
      for (const mediaPath of media) {
        const uploadResult = await uploadMedia(mediaPath, targetId);
        results.steps.push({ step: 'upload', path: mediaPath, ...uploadResult });
        await sleep(1000);
      }
    }

    // Step 7: Submit tweet (unless dry run)
    if (!dryRun) {
      console.log('[browser-plus] Submitting tweet...');
      const submitResult = await submitTweet(snapshotResult.result, targetId);
      results.steps.push({ step: 'submit', ...submitResult });
      
      if (submitResult.success) {
        results.success = true;
        results.tweetUrl = submitResult.tweetUrl;
        console.log('[browser-plus] Tweet posted successfully!');
      } else {
        throw new Error('Failed to submit tweet');
      }
    } else {
      console.log('[browser-plus] Dry run - tweet not submitted');
      results.success = true;
      results.dryRun = true;
    }

  } catch (error) {
    results.error = error.message;
    console.error('[browser-plus] Error posting tweet:', error.message);
  }

  return results;
}

/**
 * Reply to a tweet
 * @param {Object} options
 * @param {string} options.tweetUrl - URL of tweet to reply to
 * @param {string} options.text - Reply text
 * @param {boolean} [options.dryRun=false] - Don't actually submit
 * @returns {Promise<Object>} Result object
 */
async function reply(options) {
  const { tweetUrl, text, dryRun = false } = options;
  
  if (!tweetUrl) {
    throw new Error('tweetUrl is required');
  }
  
  validateText(text);

  // Navigate to tweet and find reply button
  const navResult = await nativeBrowser.navigate({ url: tweetUrl });
  
  if (!navResult.success) {
    return { success: false, error: 'Failed to navigate to tweet' };
  }

  await sleep(2000);

  // Get snapshot and find reply button
  const snapshotResult = await nativeBrowser.snapshot({ refs: 'aria' });
  
  if (!snapshotResult.success) {
    return { success: false, error: 'Failed to get page snapshot' };
  }

  // Find reply button
  const replyButton = snapshotResult.result.elements?.find(el =>
    el.attributes?.['data-testid'] === 'reply' ||
    el.role === 'button' && el.name?.toLowerCase().includes('reply')
  );

  if (!replyButton) {
    return { success: false, error: 'Could not find reply button' };
  }

  // Click reply button
  await nativeBrowser.click({ ref: replyButton.ref });
  await sleep(1000);

  // Now post as normal (reply textarea should be focused/active)
  return post({ text, dryRun });
}

/**
 * Post a tweet with media attachments
 * @param {Object} options
 * @param {string} options.text - Tweet text
 * @param {string[]} options.media - Media file paths (required)
 * @param {boolean} [options.dryRun=false] - Don't actually submit
 * @returns {Promise<Object>} Result object
 */
async function postWithMedia(options) {
  const { text, media, dryRun = false } = options;
  
  if (!media || media.length === 0) {
    throw new Error('media array is required for postWithMedia');
  }

  return post({ text, media, dryRun });
}

/**
 * Find tweet textarea in snapshot
 * @private
 */
function findTweetTextarea(snapshot) {
  // Try multiple selectors for Twitter's ever-changing UI
  const possibleSelectors = [
    { attr: 'data-testid', value: 'tweetTextarea_0' },
    { attr: 'data-testid', value: 'tweetTextarea_0RichInput' },
    { attr: 'contenteditable', value: 'true' },
    { attr: 'aria-label', value: 'Post text' },
    { attr: 'aria-label', value: 'Tweet text' }
  ];

  // First try specific selectors
  for (const selector of possibleSelectors) {
    const element = snapshot.elements?.find(el => 
      el.attributes?.[selector.attr] === selector.value
    );
    if (element) return `@${element.ref}`;
  }

  // Fallback: look for any contenteditable textbox
  const editable = snapshot.elements?.find(el => 
    el.role === 'textbox' && 
    el.attributes?.contenteditable === 'true'
  );
  
  return editable ? `@${editable.ref}` : null;
}

/**
 * Upload media to tweet
 * @private
 */
async function uploadMedia(mediaPath, targetId) {
  try {
    // Find media input
    const snapshotResult = await nativeBrowser.snapshot({ targetId, refs: 'aria' });
    
    if (!snapshotResult.success) {
      return { success: false, error: 'Failed to get snapshot for media upload' };
    }

    // Look for file input
    const fileInput = snapshotResult.result.elements?.find(el => 
      el.tagName?.toLowerCase() === 'input' && 
      el.attributes?.type === 'file'
    );

    if (!fileInput) {
      // Try clicking the media button first
      const mediaButton = snapshotResult.result.elements?.find(el =>
        el.attributes?.['data-testid']?.includes('fileInput') ||
        el.attributes?.['aria-label']?.toLowerCase().includes('media') ||
        el.attributes?.['aria-label']?.toLowerCase().includes('photo')
      );

      if (mediaButton) {
        await nativeBrowser.click({ ref: `@${mediaButton.ref}`, targetId });
        await sleep(500);
      }
    }

    // Use browser upload action via CLI
    const result = execSync(
      `openclaw browser act --request '${JSON.stringify({
        kind: 'upload',
        paths: [mediaPath]
      })}'`,
      { encoding: 'utf8', timeout: 30000 }
    );

    return { success: true, result: JSON.parse(result) };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

/**
 * Submit the tweet
 * @private
 */
async function submitTweet(snapshot, targetId) {
  try {
    // Find submit button
    const submitButton = snapshot.elements?.find(el =>
      el.attributes?.['data-testid'] === 'tweetButton' ||
      el.attributes?.['data-testid'] === 'tweetButtonInline' ||
      (el.role === 'button' && (
        el.name?.toLowerCase().includes('post') ||
        el.name?.toLowerCase().includes('tweet')
      ))
    );

    if (!submitButton) {
      return { success: false, error: 'Could not find submit button' };
    }

    const clickResult = await nativeBrowser.click({
      ref: `@${submitButton.ref}`,
      targetId
    });

    if (clickResult.success) {
      // Wait for tweet to post and extract URL
      await sleep(2000);
      return {
        success: true,
        tweetUrl: 'https://twitter.com' // Would extract actual URL in production
      };
    }

    return clickResult;
  } catch (error) {
    return { success: false, error: error.message };
  }
}

/**
 * Sleep helper
 * @private
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Export API
module.exports = {
  post,
  reply,
  postWithMedia,
  validateText
};
