#!/usr/bin/env bash



source gen_default_config.sh
source utils.sh



SONG_DATABASE="../songs"

SONG_IDS=();

rubberbandAvailable=false


# ------------------------------------------------------------
# Check required tools
# ------------------------------------------------------------
check_ffmpeg
check_jq

if check_rubberband; then
  rubberbandAvailable=true
else
  echo "[WARN] RUBBERBAND not found, tempo stretching disabled"
  echo "[WARN] Only compression at original BPM will be performed"
fi



songId=""
bpm=""
fileFormat="mp3"
TARGET_BPMS=()

echo "[INFO] Parsing arguments..."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --songId) songId="$2"; shift 2;;
    -songId) songId="$2"; shift 2;;
    --bpm) bpm="$2"; shift 2;;
    -bpm) bpm="$2"; shift 2;;
    --format) fileFormat="$2"; shift 2;;
    -format) fileFormat="$2"; shift 2;;
    --target_bpm)
      shift
      while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
        TARGET_BPMS+=("$1")
        shift
      done
      ;;
    -target_bpm)
      shift
      while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
        TARGET_BPMS+=("$1")
        shift
      done
      ;;
    *)
      fatal "Unknown argument: $1"
      ;;
  esac
done

echo "[INFO] Arguments parsed"

# ------------------------------------------------------------
# Validate songId
# ------------------------------------------------------------
[[ -z "$songId" ]] && fatal "Missing --songId"
[[ -d "$SONG_DATABASE/$songId" ]] || fatal "Song not found: $songId"

echo "[INFO] Processing song: $songId"

# ------------------------------------------------------------
# Scan audio files FIRST (critical)
# ------------------------------------------------------------
FILE_PATHS=()
FILE_NAMES=()
FILE_BASES=()

echo "[INFO] Scanning audio files..."

for f in "$SONG_DATABASE/$songId"/*; do
  [[ -f "$f" ]] || continue
  name="${f##*/}"
  [[ "$name" == "config.json" ]] && continue

  if ffprobe -v error -show_streams "$f" >/dev/null 2>&1; then
    FILE_PATHS+=("$f")
    FILE_NAMES+=("$name")
    FILE_BASES+=("${name%.*}")
  fi
done

numAudios=${#FILE_PATHS[@]}

# ------------------------------------------------------------
# CRITICAL: no tracks found
# ------------------------------------------------------------
if [[ "$numAudios" -eq 0 ]]; then
  fatal "No audio tracks found in song: $songId"
fi

echo "[INFO] Found $numAudios audio tracks"

# ------------------------------------------------------------
# Resolve BPM (config overrides CLI)
# ------------------------------------------------------------
config_bpm=""

if [[ -f "$SONG_DATABASE/$songId/config.json" ]]; then
  echo "[INFO] config.json found"

  if command -v jq >/dev/null 2>&1; then
    config_bpm=$(jq -r '.bpm // empty' "$SONG_DATABASE/$songId/config.json")
  else
    config_bpm=$(grep -oP '"bpm"\s*:\s*\K[0-9.]+' "$SONG_DATABASE/$songId/config.json" 2>/dev/null || true)
  fi

  echo "[INFO] config BPM = ${config_bpm:-none}"
fi

# ------------------------------------------------------------
# CRITICAL BPM RESOLUTION
# ------------------------------------------------------------
if [[ -n "$config_bpm" ]]; then
  bpm="$config_bpm"
  echo "[INFO] Using BPM from config.json: $bpm"

elif [[ -n "$bpm" ]]; then
  echo "[INFO] Using BPM from CLI: $bpm"

else
  fatal "No BPM found. Provide --bpm or define bpm in config.json"
fi

# ------------------------------------------------------------
# SET FFMPEG OPTIONS ACCORDING TO FILE TYPE
# ------------------------------------------------------------
bitRate=64;
sampleRate=44100;
channels=1;

ffmpegOptions=()
if [[ "$fileFormat" == "mp3" ]]; then
  check_ffmpeg_MP3
  ffmpegOptions=( -hide_banner -loglevel info -stats -y -ac "$channels" -b:a "${bitRate}k" -ar "$sampleRate")
elif [[ "$fileFormat" == @(aac|mp4|m4a) ]]; then
  check_ffmpeg_AAC
  fileFormat="mp4"
  ffmpegOptions=( -hide_banner -loglevel info -stats -y -ac "$channels" -b:a "${bitRate}k" -ar "$sampleRate"  -c:a aac )
else
  fatal "File format $fileFormat unknown or not supported. Use --format mp3 or mp4"
fi

# ------------------------------------------------------------
# Prepare output directory for compressed files at original BPM
# ------------------------------------------------------------
newSongId="$songId-$bpm-bpm-$fileFormat";
SONG_IDS+=("$newSongId");

dirCompressed="$SONG_DATABASE/$newSongId"
mkdir -p "$dirCompressed"

useDefaultConfig=true
songConfigRaw=""

if [[ -f "$SONG_DATABASE/$songId/config.json" ]]; then
  useDefaultConfig=false
  songConfigRaw=$(<"$SONG_DATABASE/$songId/config.json")
else
  clearTrackConfigs
fi

# ------------------------------------------------------------
# Compression phase
# ------------------------------------------------------------
echo "[INFO] Starting compression..."

for ((j=0; j<numAudios; j++)); do
  in="${FILE_PATHS[$j]}"

  out="$dirCompressed/${FILE_BASES[$j]}.$fileFormat"

  echo "[INFO] Compressing ${FILE_NAMES[$j]}"

  compress_audio "$in" "$out"

  if [[ "$useDefaultConfig" == true ]]; then
    appendTrack "${FILE_BASES[$j]}.$fileFormat"
  else
    songConfigRaw="${songConfigRaw//"${FILE_NAMES[$j]}"/"${FILE_BASES[$j]}.$fileFormat"}"
  fi
done

# ------------------------------------------------------------
# Generate / update config
# ------------------------------------------------------------
if [[ "$useDefaultConfig" == true ]]; then
  echo "[INFO] Generating default song config"
  songConfigRaw="$(genSong "$songId" "$bpm")"
fi

songConfigRaw="$(update_bpm "$songConfigRaw" "$bpm")"

echo "$songConfigRaw" > "$dirCompressed/config.json"
echo "[INFO] Wrote config.json (bpm=$bpm)"

# ------------------------------------------------------------
# Optional tempo stretching
# ------------------------------------------------------------
[[ "${#TARGET_BPMS[@]}" -eq 0 ]] && {
  echo "[INFO] No target BPMs provided."

  echo
  echo "D O N E"
  echo
  printHTML "${SONG_IDS[@]}"


  exit 0
}



# ------------------------------------------------------------
# CRITICAL: stretching requires rubberband
# ------------------------------------------------------------
if [[ "$rubberbandAvailable" == false ]]; then
  fatal "Rubberband not available but --target_bpm was provided"
fi

echo "[INFO] Starting tempo stretching..."

for target in "${TARGET_BPMS[@]}"; do
  tempo=$(echo "scale=20; $target / $bpm" | bc -l)

  echo "[INFO] Target BPM: $target (tempo=$tempo)"


  newSongId="$songId-$target-bpm-$fileFormat"
  SONG_IDS+=("$newSongId")

  dirA="$SONG_DATABASE/$songId-$target-bpm"

  dirB="$SONG_DATABASE/$newSongId"

  mkdir -p "$dirA" "$dirB"

  for ((j=0; j<numAudios; j++)); do
    in="${FILE_PATHS[$j]}"
    base="${FILE_BASES[$j]}"

    stretched="$dirA/${FILE_NAMES[$j]}"
    final="$dirB/${base}.${fileFormat}"

    echo "[INFO] Stretching ${FILE_NAMES[$j]}"
    stretch_audio "$in" "$stretched" "$tempo"
    echo "[INFO] Compressing ${FILE_NAMES[$j]} to $base.$fileFormat"
    compress_audio "$stretched" "$final"
  done

  update_bpm "$songConfigRaw" "$target" > "$dirB/config.json"
  echo "[INFO] Wrote stretched config for $target BPM"
done

echo
echo "D O N E"
echo
  printHTML "${SONG_IDS[@]}"
