---
name: browser-plus
description: Intelligent browser automation with smart routing between OpenClaw native browser tool and Vercel agent-browser. Use when needing to interact with web pages, especially for filling forms, clicking elements, or typing text in rich text editors that resist standard DOM manipulation. Automatically detects element types and routes to the best execution strategy.
---

# Browser Plus

Intelligent browser automation that routes between OpenClaw native browser tool and Vercel agent-browser based on element type detection.

## Overview

Browser Plus provides a unified API for browser automation that intelligently selects the best execution strategy:

- **Rich text editors** (contenteditable, tweet textarea, etc.) → Uses agent-browser keyboard simulation for real key events
- **Plain inputs** (text fields, password fields, etc.) → Uses native browser fill for faster execution

## Quick Start

```javascript
const browserPlus = require('./skills/browser-plus');

// Auto-routes based on element type
await browserPlus.type({ ref: '@e12', text: 'Hello World' });

// One-click Twitter posting
await browserPlus.tweet({ text: 'My automated tweet!' });
```

## Core API

### `type(options)`

Types text into an element with automatic routing.

```javascript
await browserPlus.type({
  ref: '@e12',           // Element reference (required)
  text: 'Hello World',   // Text to type (required)
  forceNative: false,    // Force native browser (optional)
  forceAgent: false      // Force agent-browser (optional)
});
```

### `click(options)`

Clicks an element.

```javascript
await browserPlus.click({
  ref: '@e12',           // Element reference (required)
  forceAgent: false      // Use agent-browser (optional)
});
```

### Composite Actions

#### `tweet(options)`

One-click Twitter posting.

```javascript
await browserPlus.tweet({
  text: 'My tweet content',
  media: ['/path/to/image.jpg']  // Optional media attachments
});
```

## How It Works

1. **Element Detection**: Analyzes the target element to determine its type
2. **Strategy Selection**: 
   - Rich text editors → agent-browser (real key events)
   - Plain inputs → native browser (faster)
3. **Execution**: Routes to the appropriate adapter

## Scripts

- `scripts/detectors.js` - Element type detection utilities
- `scripts/adapters/native-browser.js` - OpenClaw browser wrapper
- `scripts/adapters/agent-browser.js` - Vercel agent-browser CLI wrapper
- `scripts/composite/tweet.js` - Twitter posting composite action
