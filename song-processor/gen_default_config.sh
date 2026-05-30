#!/usr/bin/env bash

trackConfigs=""

clearTrackConfigs() {
  trackConfigs=""
}

genTrack() {
  local filename="$1"
  local label="${filename%.*}"
  label="${label:0:8}"

  cat <<EOF
    {
      "filename": "$filename",
      "label": "$label",
      "vol": -10,
      "pan": 0.0,
      "mute": false
    }
EOF
}

appendTrack() {
  local filename="$1"

  local newTrack
  newTrack="$(genTrack "$filename")"

  if [ -n "$trackConfigs" ]; then
    trackConfigs+=","
    trackConfigs+=$'\n'
  fi

  trackConfigs+="$newTrack"
}

genSong() {
  local songId="$1"
  local bpm="$2"

  cat <<EOF
{
  "title": "$songId",
  "bpm": $bpm,
  "timeSignature": "4/4",
  "startMeasure": 1,
  "masterGain": 0.5,
  "tracks": [
$trackConfigs
  ]
}
EOF
}
