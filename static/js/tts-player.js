/**
 * Text-to-Speech Player for Hugo Posts
 * Uses browser's native Web Speech API
 */

class TTSPlayer {
  constructor() {
    this.synth = window.speechSynthesis;
    this.utterance = null;
    this.isPlaying = false;
    this.currentSpeed = 1.0;
    this.speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    this.speedIndex = 2; // Default to 1.0x
    this.textElements = [];
    this.currentElementIndex = 0;
    this.startTime = null;
    this.totalDuration = 0;
    
    this.init();
  }

  init() {
    // Check if SpeechSynthesis is supported
    if (!('speechSynthesis' in window)) {
      console.warn('Text-to-speech not supported in this browser');
      return;
    }

    // Find post content - try multiple selectors for PaperMod
    this.postContent = document.querySelector('.post-content') || 
                       document.querySelector('article .entry-content') ||
                       document.querySelector('article .content') ||
                       document.querySelector('main article');

    if (!this.postContent) {
      console.warn('Post content not found');
      return;
    }

    // Inject TTS player into post header
    this.injectTTSPlayer();

    // Get DOM elements
    this.playBtn = document.getElementById('tts-play-btn');
    this.controls = document.getElementById('tts-controls');
    this.speedBtn = document.getElementById('tts-speed-btn');
    this.progressBar = document.getElementById('tts-progress-bar');

    if (!this.playBtn) return;

    // Extract text elements from post content
    this.extractTextElements();

    // Set up event listeners
    this.playBtn.addEventListener('click', () => this.togglePlay());
    this.speedBtn.addEventListener('click', () => this.changeSpeed());
    
    // Keyboard shortcut (space bar)
    document.addEventListener('keydown', (e) => {
      if (e.code === 'Space' && e.target.tagName !== 'INPUT' && e.target.tagName !== 'TEXTAREA') {
        e.preventDefault();
        this.togglePlay();
      }
    });

    // Handle page visibility (pause when tab is hidden)
    document.addEventListener('visibilitychange', () => {
      if (document.hidden && this.isPlaying) {
        this.pause();
      }
    });
  }

  injectTTSPlayer() {
    // Find post header - try multiple selectors for PaperMod
    const postHeader = document.querySelector('.post-header') ||
                       document.querySelector('article header') ||
                       document.querySelector('.entry-header') ||
                       document.querySelector('article .post-meta')?.parentElement;

    if (!postHeader) {
      console.warn('Post header not found, injecting after title');
      // Fallback: inject after first h1
      const title = document.querySelector('article h1, .post-title');
      if (title && title.parentElement) {
        const container = document.createElement('div');
        container.className = 'tts-player-container';
        container.id = 'tts-player-container';
        container.innerHTML = this.getTTSPlayerHTML();
        title.parentElement.insertBefore(container, title.nextSibling);
        return;
      }
      return;
    }

    // Insert TTS player after post meta
    const container = document.createElement('div');
    container.className = 'tts-player-container';
    container.id = 'tts-player-container';
    container.innerHTML = this.getTTSPlayerHTML();
    
    // Insert after post-meta or at end of header
    const postMeta = postHeader.querySelector('.post-meta');
    if (postMeta && postMeta.nextSibling) {
      postHeader.insertBefore(container, postMeta.nextSibling);
    } else {
      postHeader.appendChild(container);
    }
  }

  getTTSPlayerHTML() {
    return `
      <button class="tts-play-btn" id="tts-play-btn" aria-label="Play audio" title="Listen to this post">
        <svg class="tts-icon-play" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polygon points="5 3 19 12 5 21 5 3"></polygon>
        </svg>
        <svg class="tts-icon-pause" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="display: none;">
          <rect x="6" y="4" width="4" height="16"></rect>
          <rect x="14" y="4" width="4" height="16"></rect>
        </svg>
      </button>
      <div class="tts-controls" id="tts-controls" style="display: none;">
        <button class="tts-speed-btn" id="tts-speed-btn" title="Reading speed">1x</button>
        <div class="tts-progress-container">
          <div class="tts-progress-bar" id="tts-progress-bar"></div>
        </div>
      </div>
    `;
  }

  extractTextElements() {
    if (!this.postContent) return;

    // Get all text-containing elements (p, h1-h6, li, etc.)
    // Exclude elements that are likely in header/footer
    const selectors = 'p, h1, h2, h3, h4, h5, h6, li, blockquote, td, th';
    const elements = this.postContent.querySelectorAll(selectors);
    
    this.textElements = Array.from(elements).filter(el => {
      const text = el.textContent.trim();
      // Exclude if in navigation, header, footer, or TTS container
      const isExcluded = el.closest('nav, header, footer, .tts-player-container, .post-header, .post-footer');
      return text.length > 0 && !isExcluded && el.offsetParent !== null; // offsetParent checks visibility
    });

    // Add data attributes for highlighting
    this.textElements.forEach((el, index) => {
      el.setAttribute('data-tts-index', index);
      el.classList.add('tts-text-element');
    });
  }

  getTextContent() {
    return this.textElements.map(el => el.textContent.trim()).join('. ');
  }

  togglePlay() {
    if (this.isPlaying) {
      this.pause();
    } else {
      this.play();
    }
  }

  play() {
    if (!this.textElements.length) {
      this.extractTextElements();
    }

    const text = this.getTextContent();
    if (!text) return;

    // Cancel any existing speech
    this.synth.cancel();

    // Create new utterance
    this.utterance = new SpeechSynthesisUtterance(text);
    this.utterance.rate = this.currentSpeed;
    this.utterance.pitch = 1;
    this.utterance.volume = 1;
    this.utterance.lang = 'en-US';

    // Calculate estimated duration (rough estimate: 150 words per minute)
    const wordCount = text.split(/\s+/).length;
    this.totalDuration = (wordCount / 150) * 60 * 1000 / this.currentSpeed; // in milliseconds

    // Set up event handlers
    this.utterance.onstart = () => {
      this.isPlaying = true;
      this.startTime = Date.now();
      this.updateUI();
      this.highlightCurrentText(0);
    };

    this.utterance.onend = () => {
      this.isPlaying = false;
      this.currentElementIndex = 0;
      this.updateUI();
      this.clearHighlights();
    };

    this.utterance.onerror = (event) => {
      console.error('Speech synthesis error:', event);
      this.isPlaying = false;
      this.updateUI();
      this.clearHighlights();
    };

    // Update progress periodically
    this.progressInterval = setInterval(() => {
      if (this.isPlaying && this.startTime) {
        const elapsed = Date.now() - this.startTime;
        const progress = Math.min((elapsed / this.totalDuration) * 100, 100);
        this.updateProgress(progress);
        
        // Update highlighted text based on progress
        const elementIndex = Math.floor((progress / 100) * this.textElements.length);
        if (elementIndex !== this.currentElementIndex) {
          this.currentElementIndex = elementIndex;
          this.highlightCurrentText(elementIndex);
        }
      }
    }, 100);

    // Speak
    this.synth.speak(this.utterance);
  }

  pause() {
    if (this.synth.speaking) {
      this.synth.pause();
      this.isPlaying = false;
      this.updateUI();
    }
  }

  resume() {
    if (this.synth.paused) {
      this.synth.resume();
      this.isPlaying = true;
      this.updateUI();
    }
  }

  changeSpeed() {
    this.speedIndex = (this.speedIndex + 1) % this.speeds.length;
    this.currentSpeed = this.speeds[this.speedIndex];
    
    if (this.utterance) {
      this.utterance.rate = this.currentSpeed;
      if (this.isPlaying) {
        this.synth.cancel();
        this.play();
      }
    }
    
    this.speedBtn.textContent = `${this.currentSpeed}x`;
  }

  highlightCurrentText(index) {
    this.clearHighlights();
    if (this.textElements[index]) {
      this.textElements[index].classList.add('tts-reading');
      // Scroll to element if needed
      this.textElements[index].scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  }

  clearHighlights() {
    this.textElements.forEach(el => el.classList.remove('tts-reading'));
  }

  updateProgress(percent) {
    if (this.progressBar) {
      this.progressBar.style.width = `${percent}%`;
    }
  }

  updateUI() {
    if (!this.playBtn) return;

    const playIcon = this.playBtn.querySelector('.tts-icon-play');
    const pauseIcon = this.playBtn.querySelector('.tts-icon-pause');

    if (this.isPlaying) {
      this.playBtn.setAttribute('aria-label', 'Pause audio');
      this.playBtn.setAttribute('title', 'Pause audio');
      if (playIcon) playIcon.style.display = 'none';
      if (pauseIcon) pauseIcon.style.display = 'block';
      if (this.controls) this.controls.style.display = 'flex';
    } else {
      this.playBtn.setAttribute('aria-label', 'Play audio');
      this.playBtn.setAttribute('title', 'Listen to this post');
      if (playIcon) playIcon.style.display = 'block';
      if (pauseIcon) pauseIcon.style.display = 'none';
    }

    this.playBtn.classList.toggle('tts-playing', this.isPlaying);
  }
}

// Initialize TTS player when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    new TTSPlayer();
  });
} else {
  new TTSPlayer();
}

