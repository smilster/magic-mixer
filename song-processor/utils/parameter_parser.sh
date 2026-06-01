#source print_utils.sh
#source check.sh
#source config_handler.sh

# PARAMETER PARSER

SONG_DATABASE=$(realpath "$SONG_DATABASE")


if [[ -z "$ALL_SONG_CONFIG_KEYS" ]]; then

ALL_SONG_CONFIG_KEYS=();

mapfile -t ALL_SONG_CONFIG_KEYS < <(jq -r 'keys[]' "$DEFAULT_SONG_JSON")

ALL_SONG_CONFIG_KEYS+=("songId")
ALL_SONG_CONFIG_KEYS+=("target_bpm")
ALL_SONG_CONFIG_KEYS+=("file_format")

fi

SONG_CONFIG_KEYS=()
valid_flags=""

song_config_exists=0;

for key in "${ALL_SONG_CONFIG_KEYS[@]}"; do
  if [[ "$key" != "tracks" ]]; then
    SONG_CONFIG_KEYS+=("$key")
    valid_flags+="--$key "
  fi
done


while [[ $# -gt 0 ]]; do
  key="${1#--}"
  if ! check_if_array_contains "$key" "${SONG_CONFIG_KEYS[@]}"; then
    info "VALID FLAGS: $valid_flags"
    fatal "flag --$key not valid"
  fi
  if [[ "$key" == "target_bpm" ]]; then
    TARGET_BPMS=()
    shift
    while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
      if is_number "$1"; then
        TARGET_BPMS+=("$1")
      else
        warning "Target bpm $1 is not a number and will be ignored."
      fi
      shift
    done

    continue

  fi
  [[ -z "$2" ]] && fatal "Missing value for --$key"
  eval "$key=\"\$2\";"
  shift 2
done


# check for songId
if [[ -z "$songId" || ! -d "$SONG_DATABASE/$songId"  ]]; then
  mapfile -t AVAILABLE_SONG_IDS < <(find ./songs/ -maxdepth 1 -mindepth 1 -type d  -printf '%f\n')
  info "Found following available songIds / song directories in $SONG_DATABASE"
  for available_song_id in "${AVAILABLE_SONG_IDS[@]}"; do
    info "$available_song_id"
  done
  [[ -z "$songId" ]] &&  fatal "Please provide --songId SONG_ID, where SONG_ID matches the song folder"
  [[ -d "$SONG_DATABASE/$songId" ]] || fatal "Song directory (songId) $songId NOT found"
fi



success "Found song $songId directory in $SONG_DATABASE"





#check if config exists

if [[ -f "$SONG_DATABASE/$songId/$SONG_CONFIG_JSON" ]]; then
  info "Found $songId/$SONG_CONFIG_JSON"
  song_config_exists=1
else
  info "Config $songId/$SONG_CONFIG_JSON does NOT exist and will be created with default values."
  info "Providing --bpm and --timeSignature will be required."
fi

if [[ "$song_config_exists" == "1" ]]; then

  # ---- BPM ----
  config_bpm=$(jq -rM '.bpm' "$SONG_DATABASE/$songId/$SONG_CONFIG_JSON")

  if [[ -n "$bpm" ]]; then
    # CLI wins
    [[ "$config_bpm" != "null" && -n "$config_bpm" ]] && \
      warning "Config bpm ($config_bpm) ignored because --bpm $bpm was provided"
  else
    # fallback to config
    if [[ "$config_bpm" != "null" && -n "$config_bpm" ]]; then
      info "Using config bpm: $config_bpm"
      bpm="$config_bpm"
    fi
  fi

  # ---- timeSignature ----
  config_timeSignature=$(jq -rM '.timeSignature' "$SONG_DATABASE/$songId/$SONG_CONFIG_JSON")

  if [[ -n "$timeSignature" ]]; then
    # CLI wins
    [[ "$config_timeSignature" != "null" && -n "$config_timeSignature" ]] && \
      warning "Config timeSignature ($config_timeSignature) ignored because --timeSignature $timeSignature was provided"
  else
    # fallback to config
    if [[ "$config_timeSignature" != "null" && -n "$config_timeSignature" ]]; then
      info "Using config timeSignature: $config_timeSignature"
      timeSignature="$config_timeSignature"
    fi
  fi
fi

[[ -z "$bpm" && "$song_config_exists" == "1" ]] && fatal "No BPM found. Provide with e.g. --bpm 120 or define bpm in $songId/$SONG_CONFIG_JSON"
[[ -z "$bpm" && "$song_config_exists" == "0" ]] && fatal "No BPM found. Provide with e.g. --bpm 120"
is_number "$bpm" || fatal "bpm=$bpm is not valid. bpm must be a number."

[[ -z "$timeSignature"  && "$song_config_exists" == "1" ]] && fatal "No timeSignature found. Provide with e.g. --timeSignature 4/4 or define timeSignature in $songId/$SONG_CONFIG_JSON"
[[ -z "$timeSignature"  && "$song_config_exists" == "0" ]] && fatal "No timeSignature found. Provide with e.g. --timeSignature 4/4"
[[ "$timeSignature" =~ ^[0-9]+/[0-9]+$ ]] || fatal "Invalid timeSignature: $timeSignature (expected INTEGER/INTEGER e.g. --timeSignature 4/4)"

##########################
  # add original bpm to TARGET_BPMS

if check_if_array_contains "target_bpm" "${SONG_CONFIG_KEYS[@]}"; then
  TARGET_BPMS=("$bpm" "${TARGET_BPMS[@]}")
fi


##########################
#check file format

if check_if_array_contains "file_format" "${SONG_CONFIG_KEYS[@]}"; then
  file_format=$(echo "$file_format" | awk '{print tolower($0)}')
  [[ -z "$file_format" ]] && {
    warning "No audio file format (--file_format) defined. Will use mp3."
     file_format="mp3"
     }


  [[ "$file_format" == @(mp4|mp3) ]] || {
    warning "$file_format not supported. Choose mp3 or mp4. Fallback to mp3. "
    file_format="mp3"
    }

  check_ffmpeg_encoder "$file_format"

fi