#!/usr/bin/env node
/**
 * Agent Browser Adapter - Vercel agent-browser CLI wrapper
 * 
 * Uses Vercel's agent-browser for complex interactions requiring
 * real keyboard events (rich text editors, etc.)
 */

const { execSync, spawn } = require('child_process');
const path = require('path');

// Default timeout for agent-browser operations
const DEFAULT_TIMEOUT = 60000;

/**
 * Check if agent-browser is installed
 * @returns {boolean}
 */
function isAvailable() {
  try {
    execSync('which agent-browser', { stdio: 'pipe' });
    return true;
  } catch {
    return false;
  }
}

/**
 * Type text using agent-browser keyboard simulation
 * @param {Object} options
 * @param {string} options.ref - Element reference or selector
 * @param {string} options.text - Text to type
 * @param {boolean} options.submit - Whether to press Enter after typing
 * @param {number} options.delay - Delay between keystrokes in ms (default: 10)
 * @param {string} options.targetUrl - Target page URL
 * @returns {Promise<Object>} Result
 */
async function type(options) {
  const { ref, text, submit = false, delay = 10, targetUrl } = options;
  
  if (!ref || !text) {
    throw new Error('Both ref and text are required');
  }

  if (!isAvailable()) {
    return {
      success: false,
      method: 'agent-browser',
      error: 'agent-browser not found. Install with: npm install -g agent-browser'
    };
  }

  try {
    // Build agent-browser command
    const args = [
      'type',
      '--selector', refToSelector(ref),
      '--text', text,
      '--delay', String(delay)
    ];

    if (submit) {
      args.push('--submit');
    }

    if (targetUrl) {
      args.push('--url', targetUrl);
    }

    const result = await runAgentBrowser(args);
    
    return {
      success: true,
      method: 'agent-browser',
      result
    };
  } catch (error) {
    return {
      success: false,
      method: 'agent-browser',
      error: error.message
    };
  }
}

/**
 * Click an element using agent-browser
 * @param {Object} options
 * @param {string} options.ref - Element reference or selector
 * @param {string} options.targetUrl - Target page URL
 * @returns {Promise<Object>} Result
 */
async function click(options) {
  const { ref, targetUrl } = options;
  
  if (!ref) {
    throw new Error('ref is required');
  }

  if (!isAvailable()) {
    return {
      success: false,
      method: 'agent-browser',
      error: 'agent-browser not found. Install with: npm install -g agent-browser'
    };
  }

  try {
    const args = [
      'click',
      '--selector', refToSelector(ref)
    ];

    if (targetUrl) {
      args.push('--url', targetUrl);
    }

    const result = await runAgentBrowser(args);
    
    return {
      success: true,
      method: 'agent-browser',
      result
    };
  } catch (error) {
    return {
      success: false,
      method: 'agent-browser',
      error: error.message
    };
  }
}

/**
 * Navigate to a URL using agent-browser
 * @param {Object} options
 * @param {string} options.url - URL to navigate to
 * @returns {Promise<Object>} Result
 */
async function navigate(options) {
  const { url } = options;
  
  if (!url) {
    throw new Error('url is required');
  }

  if (!isAvailable()) {
    return {
      success: false,
      method: 'agent-browser',
      error: 'agent-browser not found. Install with: npm install -g agent-browser'
    };
  }

  try {
    const args = ['navigate', '--url', url];
    const result = await runAgentBrowser(args);
    
    return {
      success: true,
      method: 'agent-browser',
      result
    };
  } catch (error) {
    return {
      success: false,
      method: 'agent-browser',
      error: error.message
    };
  }
}

/**
 * Press a key using agent-browser
 * @param {Object} options
 * @param {string} options.key - Key to press (e.g., 'Enter', 'Tab', 'Escape')
 * @param {string} options.ref - Optional element to focus first
 * @returns {Promise<Object>} Result
 */
async function pressKey(options) {
  const { key, ref } = options;
  
  if (!key) {
    throw new Error('key is required');
  }

  if (!isAvailable()) {
    return {
      success: false,
      method: 'agent-browser',
      error: 'agent-browser not found. Install with: npm install -g agent-browser'
    };
  }

  try {
    const args = ['press', '--key', key];
    
    if (ref) {
      args.push('--selector', refToSelector(ref));
    }

    const result = await runAgentBrowser(args);
    
    return {
      success: true,
      method: 'agent-browser',
      result
    };
  } catch (error) {
    return {
      success: false,
      method: 'agent-browser',
      error: error.message
    };
  }
}

/**
 * Run agent-browser CLI command
 * @private
 * @param {string[]} args - Command arguments
 * @returns {Promise<Object>} Parsed result
 */
async function runAgentBrowser(args) {
  return new Promise((resolve, reject) => {
    const child = spawn('agent-browser', args, {
      stdio: ['pipe', 'pipe', 'pipe']
    });

    let stdout = '';
    let stderr = '';

    child.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    child.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    child.on('close', (code) => {
      if (code !== 0) {
        reject(new Error(`agent-browser exited with code ${code}: ${stderr}`));
      } else {
        try {
          resolve(JSON.parse(stdout));
        } catch {
          resolve({ output: stdout.trim() });
        }
      }
    });

    // Timeout handling
    setTimeout(() => {
      child.kill();
      reject(new Error('agent-browser operation timed out'));
    }, DEFAULT_TIMEOUT);
  });
}

/**
 * Convert OpenClaw-style ref to CSS selector
 * @private
 * @param {string} ref - Reference like '@e12' or '[data-testid="tweetTextarea"]'
 * @returns {string} CSS selector
 */
function refToSelector(ref) {
  // If already looks like a selector, use as-is
  if (ref.startsWith('[') || ref.startsWith('.') || ref.startsWith('#')) {
    return ref;
  }
  
  // Handle OpenClaw aria-ref format (@e12)
  if (ref.startsWith('@')) {
    // This would need to be resolved via snapshot
    // For now, assume it's a data attribute
    return `[aria-ref="${ref.slice(1)}"]`;
  }
  
  return ref;
}

module.exports = {
  isAvailable,
  type,
  click,
  navigate,
  pressKey,
  keypress: pressKey  // Alias for compatibility
};
