#!/usr/bin/env node
/**
 * Browser Plus - Intelligent browser automation with smart routing
 * 
 * Routes between OpenClaw native browser tool and Vercel agent-browser
 * based on element type for optimal interaction.
 */

const detectors = require('./scripts/detectors');
const nativeBrowser = require('./scripts/adapters/native-browser');
const agentBrowser = require('./scripts/adapters/agent-browser');
const tweet = require('./scripts/composite/tweet');

// Global configuration
const config = {
  preferNative: true,
  fallbackToAgent: true,
  agentBrowserTimeout: 60000,
  defaultDelay: 10
};

/**
 * Detect element type and determine routing
 * @param {Object} options
 * @param {string} options.ref - Element reference
 * @param {Object} [options.snapshot] - Optional pre-fetched snapshot
 * @returns {Promise<Object>} Detection result with adapter recommendation
 */
async function detectAndRoute(options) {
  const { ref, snapshot: providedSnapshot } = options;
  
  if (!ref) {
    throw new Error('ref is required');
  }

  // Get snapshot if not provided
  let snapshot = providedSnapshot;
  if (!snapshot) {
    try {
      const result = await nativeBrowser.snapshot();
      snapshot = result.result;
    } catch (error) {
      return {
        ref,
        elementType: 'UNKNOWN',
        adapter: 'native-browser',
        error: error.message
      };
    }
  }

  // Find element in snapshot
  const element = detectors.findElementByRef(snapshot, ref);
  
  if (!element) {
    return {
      ref,
      elementType: 'UNKNOWN',
      adapter: config.preferNative ? 'native-browser' : 'agent-browser',
      warning: 'Element not found in snapshot, using default adapter'
    };
  }

  const elementType = detectors.getElementType(element);
  const adapter = detectors.getPreferredAdapter(element);

  return {
    ref,
    elementType,
    adapter,
    element,
    isRichText: elementType === 'RICH_TEXT'
  };
}

/**
 * Smart type action - auto-routes based on element type
 * @param {Object} params - Type parameters
 * @param {string} params.ref - Element reference (e.g., '@e12')
 * @param {string} params.text - Text to type
 * @param {boolean} [params.forceAgent] - Force using agent-browser
 * @param {boolean} [params.forceNative] - Force using native browser
 * @param {boolean} [params.submit] - Submit after typing
 * @returns {Promise<Object>} Action result
 */
async function type(params) {
  const { ref, text, forceAgent, forceNative, submit } = params;

  if (!ref) {
    throw new Error('ref is required');
  }
  if (!text) {
    throw new Error('text is required');
  }

  // Determine which adapter to use
  let useAgent = false;

  if (forceAgent) {
    useAgent = true;
  } else if (forceNative) {
    useAgent = false;
  } else {
    // Auto-detect based on element type
    const detection = await detectAndRoute({ ref });
    useAgent = detection.adapter === 'agent-browser';
  }

  console.log(`[browser-plus] Using ${useAgent ? 'agent-browser' : 'native browser'} for typing`);

  const adapter = useAgent ? agentBrowser : nativeBrowser;
  const result = await adapter.type({ ref, text, submit });
  
  return {
    ...result,
    routedTo: useAgent ? 'agent-browser' : 'native-browser'
  };
}

/**
 * Click an element
 * @param {Object} params - Click parameters
 * @param {string} params.ref - Element reference
 * @returns {Promise<Object>} Action result
 */
async function click(params) {
  const { ref } = params;
  
  if (!ref) {
    throw new Error('ref is required');
  }

  // Clicks typically work fine with native browser
  return nativeBrowser.click({ ref });
}

/**
 * Navigate to a URL
 * @param {Object} params - Navigation parameters
 * @param {string} params.url - URL to navigate to
 * @returns {Promise<Object>} Action result
 */
async function navigate(params) {
  const { url } = params;
  
  if (!url) {
    throw new Error('url is required');
  }

  return nativeBrowser.navigate({ url });
}

/**
 * Get page snapshot
 * @param {Object} [params] - Snapshot parameters
 * @returns {Promise<Object>} Page snapshot
 */
async function snapshot(params = {}) {
  return nativeBrowser.snapshot(params);
}

/**
 * Post a tweet using composite action
 * @param {Object} params - Tweet parameters
 * @param {string} params.text - Tweet text
 * @param {Array<string>} [params.media] - Media file paths
 * @returns {Promise<Object>} Tweet result
 */
async function postTweet(params) {
  return tweet.post(params);
}

// Export API
module.exports = {
  // Main actions
  type,
  click,
  navigate,
  snapshot,
  tweet: postTweet,
  
  // Utilities
  detectAndRoute,
  config,
  
  // Sub-modules for advanced usage
  detectors,
  adapters: {
    native: nativeBrowser,
    agent: agentBrowser
  },
  composite: {
    tweet
  }
};
