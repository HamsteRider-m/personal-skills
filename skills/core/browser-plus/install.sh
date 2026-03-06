#!/bin/bash
# Installation script for browser-plus skill

set -e

echo "Installing browser-plus skill..."

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is required but not installed."
    exit 1
fi

# Check Node version (requires 16+)
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 16 ]; then
    echo "Error: Node.js 16+ is required. Found: $(node -v)"
    exit 1
fi

echo "✓ Node.js $(node -v) detected"

# Check for OpenClaw CLI
if ! command -v openclaw &> /dev/null; then
    echo "Warning: OpenClaw CLI not found in PATH. Native browser features may not work."
else
    echo "✓ OpenClaw CLI detected"
fi

# Check for agent-browser (optional but recommended)
AGENT_BROWSER_PATH=""

# Common locations to check for agent-browser
CHECK_PATHS=(
    "$HOME/.local/bin/agent-browser"
    "/usr/local/bin/agent-browser"
    "$(npm root -g)/agent-browser/cli.js"
    "$(which agent-browser 2>/dev/null)"
)

for path in "${CHECK_PATHS[@]}"; do
    if [ -f "$path" ] || [ -L "$path" ]; then
        AGENT_BROWSER_PATH="$path"
        break
    fi
done

if [ -z "$AGENT_BROWSER_PATH" ]; then
    echo "⚠ agent-browser not found. Rich text editor support will be limited."
    echo "  To install: npm install -g @vercel/agent-browser"
else
    echo "✓ agent-browser detected at: $AGENT_BROWSER_PATH"
fi

# Make scripts executable
chmod +x scripts/adapters/*.js
chmod +x scripts/composite/*.js

echo ""
echo "Installation complete!"
echo ""
echo "Usage:"
echo "  const browserPlus = require('./skills/browser-plus');"
echo "  await browserPlus.type({ ref: '@e12', text: 'Hello' });"
echo ""
