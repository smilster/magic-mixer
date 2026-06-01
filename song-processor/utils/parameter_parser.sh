#source print_utils.sh
#source check.sh
#source config_handler.sh

# PARAMETER PARSER


mapfile -t ALL_SONG_CONFIG_KEYS < <(jq -r 'keys[]' "$DEFAULT_SONG_JSON")

ALL_SONG_CONFIG_KEYS+=("songId")
ALL_SONG_CONFIG_KEYS+=("target_bpm")
ALL_SONG_CONFIG_KEYS+=("file_format")


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
    warning "VALID FLAGS: $valid_flags"
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
  eval "$key=\"\$2\";"
  shift 2
done


# check for songId
[[ -z "$songId" ]] && fatal "please provide --songId SONG_ID, where SONG_ID matches the song folder"
[[ -d "$SONG_DATABASE/$songId" ]] || fatal "song folder $SONG_DATABASE/$songId NOT found"

success "Found song $songId"

#check if config exists

if [[ -f "$SONG_DATABASE/$songId/$SONG_CONFIG_JSON" ]]; then
  info "Found $songId/$SONG_CONFIG_JSON"
  song_config_exists=1
fi
# use config bpm if song config exists
if [[ "$song_config_exists" == "1" ]]; then
  config_bpm=$(jq -rM .bpm "$SONG_DATABASE/$songId/$SONG_CONFIG_JSON")
  [[ "$config_bpm" != "null" ]] && {
  warning "Found \"bpm\": $config_bpm in config. The --bpm $bpm flag will be ignored"
  bpm="$config_bpm"
  }
fi


[[ -z "$bpm" ]] && fatal "No BPM found. Provide --bpm or define bpm in $SONG_DATABASE/$songId/$DEFAULT_SONG_JSON"
is_number "$bpm" || fatal "bpm=$bpm is not valid. bpm must be a number."

# add original bpm to TARGET_BPMS
TARGET_BPMS=("$bpm" "${TARGET_BPMS[@]}")


#check file format
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