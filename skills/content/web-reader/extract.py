#!/usr/bin/env python3
"""Web content extractor using jina.ai reader API"""
import sys
import json
import requests
from datetime import datetime

def extract(url, options=None):
    """Extract content from URL using jina.ai"""
    options = options or {}
    
    try:
        # Use jina.ai reader API
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
                "word_count": len(content.split())
            },
            "status": "success"
        }
    except Exception as e:
        return {
            "content": "",
            "metadata": {},
            "status": "error",
            "error": str(e)
        }

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: web-reader <url>")
        sys.exit(1)
    
    result = extract(sys.argv[1])
    print(json.dumps(result, indent=2, ensure_ascii=False))
