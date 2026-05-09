# TTS Debugging Guide

## Check Browser Console

1. Open your browser's Developer Tools (F12 or Right-click → Inspect)
2. Go to the Console tab
3. Look for messages starting with "TTS Player:"
4. Share any errors or warnings you see

## Manual Test

Open browser console and run:
```javascript
// Check if script loaded
console.log('TTS script loaded:', typeof TTSPlayer !== 'undefined');

// Check if post content exists
console.log('Post content:', document.querySelector('.post-content') || document.querySelector('article'));

// Check if CSS loaded
console.log('TTS CSS loaded:', document.querySelector('link[href*="tts-player.css"]'));
```

## Files to Check

1. **CSS file**: `static/css/tts-player.css` - Should exist
2. **JS file**: `static/js/tts-player.js` - Should exist  
3. **Config**: `hugo.toml` - Should have `customCSS` and `customJS` params
4. **Partials**: `layouts/partials/extend_head.html` and `extend_footer.html` - Should exist

## Quick Fix Test

Add this to any post page's HTML (temporarily) to test:
```html
<script>
  console.log('Testing TTS...');
  const link = document.createElement('link');
  link.rel = 'stylesheet';
  link.href = '/css/tts-player.css';
  document.head.appendChild(link);
  
  const script = document.createElement('script');
  script.src = '/js/tts-player.js';
  document.head.appendChild(script);
</script>
```



