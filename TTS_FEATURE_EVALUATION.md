# Text-to-Speech Feature Evaluation

## Overview
Add a Medium.com-style "Listen" button to blog posts that reads the content aloud using browser's native text-to-speech.

## Implementation Approach

### Option 1: Browser Native TTS (Recommended)
**Technology:** Web Speech API (SpeechSynthesis)
- ✅ No backend required
- ✅ No audio file generation needed
- ✅ Works offline
- ✅ Free and unlimited
- ✅ Real-time highlighting of text
- ⚠️ Browser compatibility (good in modern browsers)
- ⚠️ Voice quality varies by browser/OS

### Option 2: Pre-generated Audio Files
**Technology:** TTS service → MP3 files → HTML5 audio player
- ✅ Consistent voice quality
- ✅ Works in all browsers
- ❌ Requires backend/service
- ❌ Storage costs
- ❌ Must regenerate for each post edit
- ❌ No text highlighting

## Recommended: Option 1 (Browser Native TTS)

## Implementation Requirements

### 1. Hugo Layout Override
- Create `layouts/_default/single.html` to override PaperMod's post template
- Add TTS button in post header
- Preserve existing PaperMod styling

### 2. JavaScript Module
- Extract text from post content (strip markdown artifacts)
- Implement SpeechSynthesis API
- Handle play/pause/resume
- Highlight current text being read
- Speed control (0.5x to 2x)
- Voice selection (if multiple available)

### 3. CSS Styling
- Play button design (similar to Medium)
- Progress indicator
- Highlighted text styling
- Control panel (speed, voice, etc.)

### 4. Features to Implement
- [x] Play/Pause button
- [x] Text highlighting during playback
- [x] Speed control (0.5x, 0.75x, 1x, 1.25x, 1.5x, 2x)
- [x] Resume from last position
- [x] Skip to next/previous paragraph
- [x] Visual progress indicator
- [x] Keyboard shortcuts (space = play/pause)
- [x] Accessibility (ARIA labels)

## File Structure
```
layouts/
  _default/
    single.html          # Override post template
static/
  js/
    tts-player.js        # TTS functionality
  css/
    tts-player.css       # TTS styling
```

## Browser Compatibility
- Chrome/Edge: ✅ Full support
- Firefox: ✅ Full support
- Safari: ✅ Full support (iOS 7+)
- Opera: ✅ Full support

## Estimated Implementation Time

### Without AI Assistance (Manual Coding)
- Layout override: 30 minutes
- JavaScript module: 2-3 hours
- CSS styling: 1 hour
- Testing & polish: 1 hour
**Total: ~4-5 hours**

### With AI Assistance (Cursor IDE)
- Layout override: 5-10 minutes
- JavaScript module: 20-30 minutes
- CSS styling: 10-15 minutes
- Testing & polish: 15-20 minutes
**Total: ~50-75 minutes (less than 1.5 hours)**

*Note: AI can generate the code quickly, but you'll still want to test and adjust styling to match your site's design.*

## User Experience Flow
1. User clicks play button on post
2. Button changes to pause icon
3. Text highlights as it's being read
4. User can adjust speed, pause, or stop
5. Progress bar shows reading position
6. On page refresh, remembers last position (optional)

## Technical Considerations
- Need to extract clean text from Hugo's rendered HTML
- Handle special characters and formatting
- Pause TTS when user scrolls away (optional)
- Respect user's system volume
- Handle multiple posts on same page (only one active)

## Deployment Compatibility

### ✅ Works with Netlify + GitHub + Hugo
- **100% Client-Side**: Uses browser's native Web Speech API
- **No Backend Required**: All code runs in the browser
- **No API Keys**: No external services needed
- **Static Files**: JavaScript and CSS files in `static/` are included in Hugo build
- **Layout Override**: Hugo processes `layouts/_default/single.html` during build
- **No Netlify Config Needed**: Works out of the box with standard Hugo build

### How It Works
1. Hugo builds the site (including layout overrides)
2. Static files (`static/js/tts-player.js`, `static/css/tts-player.css`) are copied to `public/`
3. Netlify serves the static site
4. Browser loads the page and JavaScript
5. User clicks play → Browser's TTS engine reads the text
6. **No server-side processing needed!**

### Compatible With
- ✅ Netlify
- ✅ Vercel
- ✅ GitHub Pages
- ✅ Any static hosting
- ✅ Local Hugo server (`hugo server`)

## Next Steps
1. Create layout override for single post template
2. Implement JavaScript TTS module
3. Add CSS styling
4. Test across browsers
5. Add to all existing posts automatically
6. Push to GitHub → Netlify auto-deploys → Feature is live!

