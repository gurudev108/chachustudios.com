#!/bin/bash
# Batch-transcribe every audio/video file in a folder with OpenAI Whisper.
# Skips files that already have output. Safe to stop and re-run (resumes).
#
# Examples:
#   ./cs-whisper-batch.sh
#   ./cs-whisper-batch.sh --folder /Users/shiningankit/Downloads/Whisper
#   ./cs-whisper-batch.sh --model small --language en --format srt
#   ./cs-whisper-batch.sh --dry-run
#
# Run overnight (keeps going if you close the terminal):
#   nohup ./cs-whisper-batch.sh --folder /Users/shiningankit/Downloads/Whisper \
#     >> /Users/shiningankit/Downloads/Whisper/whisper-batch.nohup.log 2>&1 &
#   echo $! > /Users/shiningankit/Downloads/Whisper/whisper-batch.pid
#
# Tips for Apple M2 (CPU):
#   --language en     skips 30s language detection (faster)
#   --model small     much faster; use medium for final quality
#   --threads 4       tune to taste (default: auto)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FOLDER="${WHISPER_FOLDER:-/Users/shiningankit/Downloads/Whisper}"
MODEL="medium"
LANGUAGE="en"
OUTPUT_FORMAT="srt"
DRY_RUN=false
RECURSIVE=false
THREADS=""
INITIAL_PROMPT=""

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
  echo ""
  echo "Options:"
  echo "  --folder PATH       Input directory (default: $FOLDER)"
  echo "  --model NAME        whisper model: tiny, base, small, medium, large (default: medium)"
  echo "  --language CODE     e.g. en — skips auto-detect (recommended for English yoga audio)"
  echo "  --format FORMAT     srt, vtt, txt, json, tsv, or all (default: srt)"
  echo "  --threads N         CPU threads for whisper"
  echo "  --prompt TEXT       initial_prompt for vocabulary (mantra names, Sanskrit, etc.)"
  echo "  --recursive         include subfolders"
  echo "  --dry-run           list files only, do not transcribe"
  echo "  -h, --help          show this help"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --folder) FOLDER="${2:-}"; shift 2 ;;
    --model) MODEL="${2:-}"; shift 2 ;;
    --language) LANGUAGE="${2:-}"; shift 2 ;;
    --format) OUTPUT_FORMAT="${2:-}"; shift 2 ;;
    --threads) THREADS="${2:-}"; shift 2 ;;
    --prompt) INITIAL_PROMPT="${2:-}"; shift 2 ;;
    --recursive) RECURSIVE=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

if [ ! -d "$FOLDER" ]; then
  echo "Error: folder not found: $FOLDER"
  exit 1
fi

if ! command -v whisper >/dev/null 2>&1; then
  echo "Error: whisper not found. Install with: brew install openai-whisper"
  exit 1
fi

FOLDER="$(cd "$FOLDER" && pwd)"
LOG_FILE="$FOLDER/whisper-batch.log"
STATE_FILE="$FOLDER/whisper-batch.done.list"
LOCK_FILE="$FOLDER/whisper-batch.lock"

MEDIA_EXTENSIONS="mp4 mov mkv webm m4v avi wav mp3 m4a flac aac ogg wma"

log() {
  local line="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
  echo "$line"
  echo "$line" >> "$LOG_FILE"
}

acquire_lock() {
  if [ -f "$LOCK_FILE" ]; then
    local pid
    pid="$(cat "$LOCK_FILE" 2>/dev/null || true)"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      echo "Error: another batch run is active (pid $pid). Lock: $LOCK_FILE"
      exit 1
    fi
    log "Removing stale lock (pid $pid not running)"
    rm -f "$LOCK_FILE"
  fi
  echo "$$" > "$LOCK_FILE"
}

release_lock() {
  rm -f "$LOCK_FILE"
}

trap release_lock EXIT

is_media_file() {
  local base ext
  base="$(basename "$1")"
  ext="${base##*.}"
  ext="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"
  case " $MEDIA_EXTENSIONS " in
    *" $ext "*) return 0 ;;
    *) return 1 ;;
  esac
}

output_exists() {
  local stem="$1"
  case "$OUTPUT_FORMAT" in
    all)
      [ -f "${stem}.srt" ] && [ -f "${stem}.txt" ] && [ -f "${stem}.vtt" ]
      ;;
    *)
      [ -f "${stem}.${OUTPUT_FORMAT}" ]
      ;;
  esac
}

mark_done() {
  echo "$1" >> "$STATE_FILE"
}

already_done() {
  local f="$1"
  grep -Fxq "$f" "$STATE_FILE" 2>/dev/null
}

collect_files() {
  local find_args=()
  if [ "$RECURSIVE" = true ]; then
    find_args=(-mindepth 1)
  else
    find_args=(-maxdepth 1)
  fi
  find "$FOLDER" "${find_args[@]}" -type f ! -name '.*' | sort
}

acquire_lock
touch "$LOG_FILE" "$STATE_FILE"

log "=== Whisper batch start ==="
log "Folder: $FOLDER"
log "Model: $MODEL | Language: ${LANGUAGE:-auto} | Format: $OUTPUT_FORMAT"
log "Recursive: $RECURSIVE | Dry run: $DRY_RUN"

total=0
skipped=0
processed=0
failed=0

while IFS= read -r file; do
  is_media_file "$file" || continue
  total=$((total + 1))

  dir="$(dirname "$file")"
  stem="${file%.*}"

  if output_exists "$stem" || already_done "$file"; then
    log "SKIP (already done): $(basename "$file")"
    skipped=$((skipped + 1))
    continue
  fi

  if [ "$DRY_RUN" = true ]; then
    log "WOULD RUN: $(basename "$file")"
    processed=$((processed + 1))
    continue
  fi

  log "START: $(basename "$file")"
  whisper_args=(
    "$file"
    --model "$MODEL"
    --output_dir "$dir"
    --output_format "$OUTPUT_FORMAT"
    --verbose False
  )

  if [ -n "$LANGUAGE" ]; then
    whisper_args+=(--language "$LANGUAGE")
  fi
  if [ -n "$THREADS" ]; then
    whisper_args+=(--threads "$THREADS")
  fi
  if [ -n "$INITIAL_PROMPT" ]; then
    whisper_args+=(--initial_prompt "$INITIAL_PROMPT")
  fi

  start_ts="$(date +%s)"
  if whisper "${whisper_args[@]}" 2>&1 | tee -a "$LOG_FILE"; then
    end_ts="$(date +%s)"
    elapsed=$((end_ts - start_ts))
    log "DONE: $(basename "$file") (${elapsed}s)"
    mark_done "$file"
    processed=$((processed + 1))
  else
    log "FAILED: $(basename "$file") — will retry on next run"
    failed=$((failed + 1))
  fi
done < <(collect_files)

log "=== Whisper batch finished ==="
log "Media files found: $total | transcribed: $processed | skipped: $skipped | failed: $failed"
log "Log: $LOG_FILE"
log "Done list: $STATE_FILE"

if [ "$failed" -gt 0 ]; then
  exit 1
fi
