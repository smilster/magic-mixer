# 🎵 Magic Mixer — Song Processor

## Overview

The **song-processor** module is the core audio processing engine of Magic Mixer.  
It transforms raw audio files into structured, remixable musical data.

In simple terms:

> 🎧 It turns a song into “understood music components” like stems, beats, structure, and features.

---

## 🧠 Core Pipeline

The processor works in five main stages:

### 1. Audio Loading & Normalization
- Loads audio files (WAV, MP3, etc.)
- Resamples to a consistent sample rate
- Normalizes loudness and stereo balance

### 2. Stem Separation
Splits audio into individual components using models like Demucs:
- Vocals
- Drums
- Bass
- Other instruments

**Output example:**
```
song.wav
→ vocals.wav
→ drums.wav
→ bass.wav
→ other.wav
```

### 3. Feature Extraction
Extracts musical metadata:
- BPM (tempo)
- Key (e.g., A minor)
- Energy levels
- Spectral features
- Beat positions

**Example:**
```json
{
  "bpm": 128,
  "key": "C major",
  "duration": 210
}
```

### 4. Segmentation
Detects song structure:
- Intro
- Verse
- Chorus
- Drops
- Time-based segments

**Example:**
```
0:00–0:12 Intro
0:12–0:45 Verse
0:45–1:10 Chorus
```

### 5. Remix Preparation
Prepares output for:
- Loop creation
- Sampling
- DJ mixing
- AI music generation

---

## ⚙️ Full Pipeline Flow

```
Input Audio
   ↓
Load & Normalize
   ↓
Stem Separation
   ↓
Feature Extraction
   ↓
Segmentation
   ↓
Structured Music Data Output
```

---

## 🧪 Example Use Cases

### 🎧 Remixing
Extract vocals, drums, and bass for mashups or DJ sets.

### 🎤 Vocal Extraction
Generate clean vocal datasets for AI training or karaoke systems.

### 🥁 Beat Making
Extract loops and rhythmic patterns for production.

### 🎼 Music Analysis
Detect tempo, key, and structure for recommendation systems.

### 🤖 AI Music Systems
Feed structured music data into generative AI models.

---

## 🧩 Core Idea

Instead of treating music as a single file:

```
song.wav
```

We treat it as structured data:

```json
{
  "stems": {...},
  "beats": [...],
  "segments": [...],
  "features": {...}
}
```

---

## 🚀 Why It Matters

This enables:
- Real-time remixing
- AI-assisted music production
- Automated DJ systems
- Intelligent music analysis
