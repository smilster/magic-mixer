#!/usr/bin/env bash

log() { echo; echo "==> $*"; echo; }

fail() {
  echo "ERROR: $*"
  exit 1
}

fatal() {
  echo "[FATAL] $1"
  echo "[EXIT] Script aborted due to critical error"
  exit 1
}

compress_audio() {
  local in="$1"
  local out="$2"
  if [[ -f "$out" ]]; then
    echo "[WARNING] $out already exists.";
    echo "[WARNING] Use $out instead of new compression";
    echo "[WARNING] Delete folder or files if you want to re-encode.";

    return
  fi
  ffmpeg -i "$in" "${ffmpegOptions[@]}" "$out"
}

stretch_audio() {
  local in="$1"
  local out="$2"
  local tempo="$3"
  if [[ -f "$out" ]]; then
    echo "[WARNING] $out already exists.";
    echo "[WARNING] Use $out instead of new stretch";

    return
  fi
  rubberband "$in" --tempo "$tempo" --fine --formant --ignore-clipping "$out"
}

update_bpm() {
  local json="$1"
  local new_bpm="$2"


 echo $json | jq --argjson bpm "$new_bpm" '
   .bpm = $bpm
 '
}




check_ffmpeg() {

  # -----------------------------
  # ffmpeg presence
  # -----------------------------
  if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "✘ ffmpeg is NOT installed"
    echo
    exit 1
  fi
  version=$(ffmpeg -version | awk '/ffmpeg version/ {gsub(/^n/, "", $3); print $3; exit}')

  echo "✔ ffmpeg $version"
  echo "✔ $(command -v ffmpeg)"
  echo



}

check_ffmpeg_MP3() {
    # -----------------------------
    # MP3 support (detailed)
    # -----------------------------
    MP3_ENCODERS=$(ffmpeg -encoders 2>/dev/null | awk '/mp3/ {print $2}' | sort -u)
    MP3_DECODERS=$(ffmpeg -decoders 2>/dev/null | awk '/mp3/ {print $2}' | sort -u)

    if [[ -n "$MP3_ENCODERS" ]]; then
      echo "  ✔ MP3 encoder(s):"
      echo "$MP3_ENCODERS" | sed 's/^/     - /'
    else
      echo "  ✘ No MP3 encoder found"
      exit 1
    fi

    if [[ -n "$MP3_DECODERS" ]]; then
      echo "  ✔ MP3 decoder(s):"
      echo "$MP3_DECODERS" | sed 's/^/     - /'
    else
      echo "  ✘ No MP3 decoder found"
    fi

    echo
}

check_ffmpeg_AAC(){
    # -----------------------------
    # AAC support
    # -----------------------------
    if ffmpeg -encoders 2>/dev/null | grep -qi aac; then
      echo "  ✔ AAC encoder(s):"
      ffmpeg -encoders 2>/dev/null | awk '/aac/ {print "     - "$2}' | sort -u
    else
      echo "  ✘ AAC encoder NOT found"
    fi

    if ffmpeg -decoders 2>/dev/null | grep -qi aac; then
      echo "  ✔ AAC decoder(s):"
      ffmpeg -decoders 2>/dev/null | awk '/aac/ {print "     - "$2}' | sort -u
    else
      echo "  ✘ AAC decoder NOT found"
      exit 1
    fi

    echo

    # -----------------------------
    # MP4/M4A container
    # -----------------------------

    if ffmpeg -muxers 2>/dev/null | grep -qi mp4; then
      echo "  ✔ MP4/M4A container supported (mp4 muxer present)"
    else
      echo "  ✘ MP4/M4A container NOT supported"
      exit 1
    fi

    echo
}

check_rubberband() {

  if ! command -v rubberband >/dev/null 2>&1; then
    echo "✘ rubberband NOT found"
    echo
    return 1
  fi


  version="unknown version";

  # version detection (varies by distro/build)
  echo
  if rubberband --version >/dev/null 2>&1; then
    version=$(rubberband --version 2>&1);
  elif rubberband -v >/dev/null 2>&1; then
    version=$(rubberband -v 2>&1);
  fi

  echo "✔ rubberband ${version}"
  echo "✔ $(command -v rubberband)"
  echo
  return 0
}

check_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "✘ jq JSON processor NOT found"
    echo
    exit 1
  fi

  version=$(jq --version)
  echo "✔ ${version}"
  echo "✔ $(command -v jq)"

  echo

}

printHTML () {
  local SONG_IDS=("$@");

  echo "You may insert/extend the following in your index.html "
  echo
  echo '<body>'
  echo '    <div id="magic-mixer">'

  for newSongId in "${SONG_IDS[@]}"; do
    echo "        <song>$newSongId</song>"
  done
  echo "    </div>"
  echo "</body>"

}