#!/usr/bin/env node
/**
 * Native Browser Adapter - OpenClaw browser tool wrapper
 * 
 * Uses OpenClaw's native browser tool for fast, reliable automation
 * on standard input elements.
 */

const { execSync } = require('child_process');
const path = require('path');

/**
 * Type text into a plain input element using native browser fill
 * @param {Object} options
 * @param {string} options.ref - Element reference (e.g., '@e12')
 * @param {string} options.text - Text to type
 * @param {boolean} options.submit - Whether to submit after typing
 * @param {string} options.targetId - Optional target tab ID
 * @returns {Promise<Object>} Result from browser tool
 */
async function type(options) {
  const { ref, text, submit = false, targetId } = options;
  
  if (!ref || !text) {
    throw new Error('Both ref and text are required');
  }

  // Build the request payload for OpenClaw browser tool
  const request = {
    kind: 'fill',
    ref: ref,
    values: [text]
  };

  if (submit) {
    request.submit = true;
  }

  if (targetId) {
    request.targetId = targetId;
  }

  try {
    // Call OpenClaw browser tool via CLI
    const result = await callBrowserTool({
      action: 'act',
      request: JSON.stringify(request)
    });
    
    return {
      success: true,
      method: 'native-browser',
      result
    };
  } catch (error) {
    return {
      success: false,
      method: 'native-browser',
      error: error.message
    };
  }
}

/**
 * Click an element using native browser
 * @param {Object} options
 * @param {string} options.ref - Element reference
 * @param {string} options.targetId - Optional target tab ID
 * @returns {Promise<Object>} Result
 */
async function click(options) {
  const { ref, targetId } = options;
  
  if (!ref) {
    throw new Error('ref is required');
  }

  const request = {
    kind: 'click',
    ref: ref
  };

  if (targetId) {
    request.targetId = targetId;
  }

  try {
    const result = await callBrowserTool({
      action: 'act',
      request: JSON.stringify(request)
    });
    
    return {
      success: true,
      method: 'native-browser',
      result
    };
  } catch (error) {
    return {
      success: false,
      method: 'native-browser',
      error: error.message
    };
  }
}

/**
 * Navigate to a URL using native browser
 * @param {Object} options
 * @param {string} options.url - URL to navigate to
 * @param {string} options.targetId - Optional target tab ID
 * @returns {Promise<Object>} Result
 */
async function navigate(options) {
  const { url, targetId } = options;
  
  if (!url) {
    throw new Error('url is required');
  }

  try {
    const args = ['browser', 'navigate', '--targetUrl', url];
    if (targetId) {
      args.push('--targetId', targetId);
    }
    
    const result = execSync(`openclaw ${args.join(' ')}`, {
      encoding: 'utf8',
      timeout: 30000
    });
    
    return {
      success: true,
      method: 'native-browser',
      result: JSON.parse(result)
    };
  } catch (error) {
    return {
      success: false,
      method: 'native-browser',
      error: error.message
    };
  }
}

/**
 * Get page snapshot using native browser
 * @param {Object} options
 * @param {string} options.targetId - Optional target tab ID
 * @param {string} options.refs - Reference type ('role' or 'aria')
 * @returns {Promise<Object>} Snapshot result
 */
async function snapshot(options = {}) {
  const { targetId, refs = 'role' } = options;

  try {
    const args = ['browser', 'snapshot', '--refs', refs];
    if (targetId) {
      args.push('--targetId', targetId);
    }
    
    const result = execSync(`openclaw ${args.join(' ')}`, {
      encoding: 'utf8',
      timeout: 30000
    });
    
    return {
      success: true,
      method: 'native-browser',
      result: JSON.parse(result)
    };
  } catch (error) {
    return {
      success: false,
      method: 'native-browser',
      error: error.message
    };
  }
}

/**
 * Internal helper to call browser tool
 * @private
 */
async function callBrowserTool(params) {
  const args = ['browser', params.action];
  
  if (params.request) {
    args.push('--request', params.request);
  }
  
  const output = execSync(`openclaw ${args.join(' ')}`, {
    encoding: 'utf8',
    timeout: 30000
  });
  
  return JSON.parse(output);
}

module.exports = {
  type,
  click,
  navigate,
  snapshot
};
