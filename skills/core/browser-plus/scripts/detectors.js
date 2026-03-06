#!/usr/bin/env node
/**
 * Element Detectors - Identify element types for smart routing
 * 
 * These functions analyze DOM elements to determine if they are:
 * - Rich text editors (need agent-browser with real key events)
 * - Plain inputs (can use native browser fill for speed)
 */

/**
 * Check if an element is a rich text editor
 * Rich text editors require real keyboard events to function properly
 * 
 * @param {Object} element - Element data from snapshot
 * @param {string} element.tagName - HTML tag name
 * @param {Object} element.attributes - Element attributes
 * @returns {boolean} True if element is a rich text editor
 */
function isRichTextEditor(element) {
  if (!element || !element.attributes) {
    return false;
  }

  const attrs = element.attributes;
  const tagName = (element.tagName || '').toLowerCase();

  // Contenteditable elements are rich text editors
  if (attrs.contenteditable === 'true' || attrs.contenteditable === '') {
    return true;
  }

  // Twitter composer textarea
  if (attrs['data-testid'] && attrs['data-testid'].startsWith('tweetTextarea')) {
    return true;
  }

  // Draft.js editor
  if (attrs.class && attrs.class.includes('DraftEditor-root')) {
    return true;
  }

  // Quill editor
  if (attrs.class && attrs.class.includes('ql-editor')) {
    return true;
  }

  // TinyMCE
  if (attrs.class && attrs.class.includes('mce-content-body')) {
    return true;
  }

  // CKEditor
  if (attrs.class && attrs.class.includes('ck-content')) {
    return true;
  }

  // ProseMirror
  if (attrs.class && attrs.class.includes('ProseMirror')) {
    return true;
  }

  // Tiptap
  if (attrs.class && attrs.class.includes('tiptap')) {
    return true;
  }

  // Generic rich text class patterns
  const richTextClasses = [
    'rich-text',
    'richtext',
    'wysiwyg',
    'editor-content'
  ];
  
  if (attrs.class) {
    const classLower = attrs.class.toLowerCase();
    for (const pattern of richTextClasses) {
      if (classLower.includes(pattern)) {
        return true;
      }
    }
  }

  // Role-based detection
  if (attrs.role === 'textbox' && attrs['aria-multiline'] === 'true') {
    // Multi-line textbox might be rich text
    if (tagName === 'div') {
      return true;
    }
  }

  return false;
}

/**
 * Check if element is specifically a Twitter/X composer
 * @param {Object} element - Element data
 * @returns {boolean} True if Twitter composer
 */
function isTwitterComposer(element) {
  if (!element || !element.attributes) {
    return false;
  }
  
  const testId = element.attributes['data-testid'] || '';
  return testId.startsWith('tweetTextarea');
}

/**
 * Check if element is a plain input field
 * @param {Object} element - Element data
 * @returns {boolean} True if plain input
 */
function isPlainInput(element) {
  if (!element) return false;
  
  const tagName = (element.tagName || '').toLowerCase();
  const attrs = element.attributes || {};

  // Standard input types that work well with native fill
  if (tagName === 'input') {
    const inputType = (attrs.type || 'text').toLowerCase();
    const supportedTypes = ['text', 'email', 'password', 'search', 'tel', 'url', 'number'];
    return supportedTypes.includes(inputType);
  }

  return false;
}

/**
 * Check if element is a textarea
 * @param {Object} element - Element data
 * @returns {boolean} True if textarea
 */
function isTextarea(element) {
  if (!element) return false;
  return (element.tagName || '').toLowerCase() === 'textarea';
}

/**
 * Get the element type category
 * @param {Object} element - Element data
 * @returns {string} One of: RICH_TEXT, PLAIN_INPUT, TEXTAREA, UNKNOWN
 */
function getElementType(element) {
  if (isRichTextEditor(element)) {
    return 'RICH_TEXT';
  }
  if (isPlainInput(element)) {
    return 'PLAIN_INPUT';
  }
  if (isTextarea(element)) {
    return 'TEXTAREA';
  }
  return 'UNKNOWN';
}

/**
 * Determine which adapter to use based on element type
 * @param {Object} element - Element data
 * @returns {string} 'agent-browser' or 'native-browser'
 */
function getPreferredAdapter(element) {
  const type = getElementType(element);
  
  // Rich text editors need agent-browser for real key events
  if (type === 'RICH_TEXT') {
    return 'agent-browser';
  }
  
  // Everything else can use native browser for speed
  return 'native-browser';
}

/**
 * Analyze snapshot data to find element by reference
 * @param {Object} snapshot - Browser snapshot result
 * @param {string} ref - Element reference (e.g., '@e12')
 * @returns {Object|null} Element data or null
 */
function findElementByRef(snapshot, ref) {
  if (!snapshot || !snapshot.elements) {
    return null;
  }

  // Remove @ prefix if present
  const targetRef = ref.startsWith('@') ? ref.slice(1) : ref;

  for (const element of snapshot.elements) {
    if (element.ref === targetRef) {
      return element;
    }
  }

  return null;
}

module.exports = {
  isRichTextEditor,
  isTwitterComposer,
  isPlainInput,
  isTextarea,
  getElementType,
  getPreferredAdapter,
  findElementByRef
};
