# Text-to-Speech Architecture & Design

## Current Implementation

### How It Works

The TTS feature uses the **Web Speech API (SpeechSynthesis)**, which is built into modern browsers. Here's the architecture:

```
Browser (Client-Side)
├── Web Speech API (SpeechSynthesis)
│   ├── Native TTS Engine (OS-level)
│   │   ├── macOS: AVSpeechSynthesizer
│   │   ├── Windows: SAPI
│   │   ├── Linux: Festival/Espeak
│   │   └── Android/iOS: Platform TTS
│   └── Voice Selection (System voices)
│
└── Our JavaScript (tts-player.js)
    ├── Text Extraction (from post content)
    ├── SpeechSynthesisUtterance (API wrapper)
    ├── Playback Control (play/pause/speed)
    └── UI Updates (button, progress, highlighting)
```

### Key Components

#### 1. **Text Extraction** (`extractTextElements()`)
- Scans the post content DOM
- Finds all text elements (p, h1-h6, li, etc.)
- Filters out navigation/header/footer elements
- Creates an array of text chunks

#### 2. **Speech Synthesis** (`play()`)
```javascript
const utterance = new SpeechSynthesisUtterance(text);
utterance.rate = 1.0;      // Speed (0.1 to 10)
utterance.pitch = 1.0;     // Pitch (0 to 2)
utterance.volume = 1.0;    // Volume (0 to 1)
utterance.lang = 'en-US';  // Language code
speechSynthesis.speak(utterance);
```

#### 3. **Text Highlighting**
- Tracks which text element is being read
- Adds CSS class `tts-reading` to current element
- Scrolls to keep highlighted text visible

#### 4. **Progress Tracking**
- Estimates duration based on word count
- Updates progress bar in real-time
- Highlights text based on reading position

## Current Limitations

### 1. **Language Support**
- Currently hardcoded to `'en-US'`
- Uses system's default English voice
- Limited control over voice selection

### 2. **Voice Quality**
- Depends on OS/browser TTS engine
- No custom voice support
- Quality varies by platform

### 3. **Text Processing**
- Simple text extraction
- No language detection
- No special handling for mixed languages

## Improvements for Hindi Support

### Option 1: Multi-Language Detection (Recommended)

```javascript
// Detect language from post metadata or content
const detectLanguage = (content) => {
  // Check post front matter for language
  const langMeta = document.querySelector('meta[property="article:language"]');
  if (langMeta) return langMeta.content;
  
  // Simple detection: count Devanagari characters
  const devanagariCount = (content.match(/[\u0900-\u097F]/g) || []).length;
  const totalChars = content.length;
  
  if (devanagariCount / totalChars > 0.3) {
    return 'hi-IN'; // Hindi
  }
  return 'en-US'; // Default to English
};

// Use in utterance
utterance.lang = detectLanguage(text);
```

### Option 2: Explicit Language Selection

Add language selector to UI:
```javascript
// Add to TTS controls
<select id="tts-language">
  <option value="en-US">English</option>
  <option value="hi-IN">हिंदी (Hindi)</option>
  <option value="mr-IN">मराठी (Marathi)</option>
  <option value="gu-IN">ગુજરાતી (Gujarati)</option>
</select>
```

### Option 3: Per-Post Language

Add to post front matter:
```yaml
+++
title: "My Post"
language: "hi-IN"
+++
```

Then in JavaScript:
```javascript
const postLang = document.querySelector('meta[property="article:language"]')?.content || 'en-US';
utterance.lang = postLang;
```

## Using Your Own Voice

### Option 1: Pre-recorded Audio Files (Best Quality)

**How it works:**
- Generate audio files for each post using your voice
- Store in `static/audio/` directory
- Use HTML5 Audio API instead of SpeechSynthesis

**Implementation:**
```javascript
class CustomVoicePlayer {
  constructor() {
    this.audio = new Audio();
    this.currentPost = null;
  }
  
  play(postSlug) {
    // Load your recorded audio file
    this.audio.src = `/audio/${postSlug}.mp3`;
    this.audio.play();
  }
}
```

**Workflow:**
1. Record yourself reading each post
2. Convert to MP3/OGG
3. Store in `static/audio/`
4. JavaScript loads and plays the file

**Pros:**
- ✅ Natural, human voice
- ✅ Perfect pronunciation
- ✅ Emotional expression
- ✅ Works offline

**Cons:**
- ❌ Must record each post
- ❌ File storage required
- ❌ No dynamic text changes

### Option 2: TTS Service with Custom Voice (Cloud)

**Services:**
- **Google Cloud Text-to-Speech** - Custom voice training
- **Amazon Polly** - Neural TTS with custom voices
- **Azure Cognitive Services** - Custom neural voices
- **ElevenLabs** - High-quality voice cloning

**How it works:**
1. Train a custom voice model with your recordings
2. Generate audio files server-side or via API
3. Store/cache audio files
4. Serve via CDN or static hosting

**Implementation:**
```javascript
// Generate audio on-demand
async function generateAudio(text, voiceId) {
  const response = await fetch('/api/generate-tts', {
    method: 'POST',
    body: JSON.stringify({ text, voiceId })
  });
  const audioUrl = await response.json();
  return audioUrl;
}
```

**Pros:**
- ✅ Your voice, scalable
- ✅ High quality
- ✅ Multiple languages

**Cons:**
- ❌ Requires backend/API
- ❌ Costs money
- ❌ More complex setup

### Option 3: Browser Extension/Plugin

Create a browser extension that:
- Intercepts TTS requests
- Uses your custom voice model
- Works across all sites

**Pros:**
- ✅ Works everywhere
- ✅ User-controlled

**Cons:**
- ❌ Users must install extension
- ❌ Complex development

## Recommended Approach for Your Site

### Phase 1: Multi-Language Support (Easy)
1. Add language detection
2. Support Hindi and English
3. Add language selector to UI
4. Use system Hindi voices

### Phase 2: Custom Voice (If Needed)
1. **For important posts**: Pre-record audio files
2. **For all posts**: Use TTS service (ElevenLabs/Google)
3. **Hybrid**: Pre-record key posts, TTS for others

## Implementation Priority

1. **Immediate**: Add Hindi language support
   - Detect language from content
   - Set `utterance.lang = 'hi-IN'`
   - Add language selector

2. **Short-term**: Improve text extraction
   - Better handling of mixed languages
   - Preserve formatting/emphasis
   - Handle special characters

3. **Long-term**: Custom voice (if desired)
   - Evaluate TTS services
   - Set up audio generation pipeline
   - Implement audio file serving

## Code Structure

```
tts-player.js
├── TTSPlayer class
│   ├── init() - Setup
│   ├── extractTextElements() - Get text from DOM
│   ├── play() - Start TTS
│   ├── pause() - Pause TTS
│   ├── changeSpeed() - Adjust rate
│   ├── highlightCurrentText() - Visual feedback
│   └── injectTTSPlayer() - Add UI to page
│
└── Initialization
    └── Wait for DOM, then create TTSPlayer instance
```

## Next Steps

1. **Add Hindi support** - Modify `play()` to detect/set language
2. **Add voice selection** - Let users choose from available voices
3. **Improve text extraction** - Better handling of mixed content
4. **Consider custom voice** - If you want your own voice, we can set up TTS service integration

Would you like me to implement Hindi support first?



