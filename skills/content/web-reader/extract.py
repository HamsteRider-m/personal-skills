#!/usr/bin/env python3
"""Web content extractor using defuddle.me or jina.ai"""
import sys
import json
import requests
from datetime import datetime

def extract(url, options=None):
    """Extract content from URL using defuddle.me (primary) or jina.ai (fallback)"""
    options = options or {}
    provider = options.get("provider", "auto")  # auto, defuddle, jina
    
    providers = []
    if provider == "auto":
        providers = ["defuddle", "jina"]
    elif provider in ["defuddle", "jina"]:
        providers = [provider]
    else:
        providers = ["defuddle", "jina"]
    
    last_error = None
    
    for p in providers:
        try:
            if p == "defuddle":
                # Defuddle.me - recommended by Obsidian CEO
                response = requests.get(f"https://defuddle.me/{url}", timeout=30)
            else:  # jina
                response = requests.get(f"https://r.jina.ai/{url}", timeout=30)
            
            response.raise_for_status()
            content = response.text
            
            return {
                "content": content,
                "metadata": {
                    "source": url,
                    "title": url.split('//')[-1].split('/')[0],
                    "date": datetime.now().isoformat(),
                    "extractor": "web-reader",
                    "provider": p,
                    "word_count": len(content.split())
                },
                "status": "success"
            }
        except Exception as e:
            last_error = str(e)
            continue
    
    return {
        "content": "",
        "metadata": {},
        "status": "error",
        "error": f"All providers failed. Last error: {last_error}"
    }

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: web-reader <url>")
        sys.exit(1)
    
    result = extract(sys.argv[1])
    print(json.dumps(result, indent=2, ensure_ascii=False))
