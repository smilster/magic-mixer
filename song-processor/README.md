# 🎵 Audio Song Processing (MP3/MP4 Compression & Tempo Stretching)

This script is a Bash-based audio processing pipeline designed to
**normalize, compress, and optionally tempo-stretch song folders** into
ready-to-use audio packages with updated configuration files.

It is especially useful for projects that need: - Multiple BPM versions
of the same song - Lightweight compressed audio for web playback -
Structured "song bundles" with metadata (`config.json`) - Automatic
batch processing of multi-track song folders

------------------------------------------------------------------------

## 🚀 What the Script Does

Given a song directory (called a `songId`), the script:

### 1. Validates environment

-   Ensures required tools exist:
    -   `ffmpeg`
    -   `jq`
    -   optionally `rubberband` (for tempo stretching)

------------------------------------------------------------------------

### 2. Loads a song folder

Each song is expected to live in:

../songs/`<songId>`{=html}/

Example: ../songs/my_song/ kick.wav snare.wav melody.wav config.json

------------------------------------------------------------------------

### 3. Detects audio tracks

-   Scans the folder for valid audio files using `ffprobe`
-   Ignores non-audio files and `config.json`

------------------------------------------------------------------------

### 4. Resolves BPM

BPM is determined in this order:

1.  `config.json` (highest priority)
2.  CLI argument `--bpm`
3.  Fails if neither is provided

------------------------------------------------------------------------

### 5. Compresses audio

Each audio file is: - Converted to a target format (`mp3` or
`mp4/aac`) - Downsampled to: - 64 kbps - 44.1 kHz - Mono - Stored in a
new folder:

../songs/`<songId>`{=html}-`<bpm>`{=html}-bpm-`<format>`{=html}/

------------------------------------------------------------------------

### 6. Generates / updates config.json

If no config exists: - A default config is generated

If config exists: - File names are updated to match compressed outputs -
BPM is updated

------------------------------------------------------------------------

### 7. Optional: BPM stretching (multi-version export)

If `--target_bpm` is provided and `rubberband` is installed:

The script will: 1. Calculate tempo ratio:
`tempo = target_bpm / original_bpm` 2. Create stretched audio versions
3. Re-compress them into final output folders

Example output: my_song-128-bpm-mp3/ my_song-140-bpm-mp3/
my_song-160-bpm-mp3/

------------------------------------------------------------------------

### 8. Outputs HTML snippet

At the end, it prints a ready-to-use snippet:

``` html
<div id="magic-mixer">
    <song>songId-bpm-bpm-format</song>
</div>
```

------------------------------------------------------------------------

## 📦 Output Structure

For each processed song:

../songs/ my_song-128-bpm-mp3/ kick.mp3 snare.mp3 melody.mp3 config.json

If stretching is enabled:

../songs/ my_song-128-bpm-mp3/ my_song-140-bpm-mp3/ my_song-160-bpm-mp3/

------------------------------------------------------------------------

## 🧰 Requirements

### Mandatory

-   ffmpeg
-   ffprobe
-   jq

### Optional

-   rubberband-cli

------------------------------------------------------------------------

## ⚙️ Usage

### Basic compression

./script.sh --songId my_song --bpm 128

### Multiple BPM versions

./script.sh --songId my_song --bpm 128 --target_bpm 140 150 160

------------------------------------------------------------------------

## 🎯 Summary

A batch audio pipeline that: - compresses audio - normalizes BPM -
optionally generates tempo-stretched versions - produces web-ready song
packages
