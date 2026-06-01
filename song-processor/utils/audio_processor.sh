#source print_utils.sh;

BIT_RATE="32k"
SAMPLE_RATE=44100
CHANNELS=1

FFMPEG_OPTIONS=( -y -hide_banner -loglevel error -stats -ac "$CHANNELS" -b:a "$BIT_RATE" -ar "$SAMPLE_RATE")
RUBBERBAND_OPTIONS=( --fine --formant --ignore-clipping )

calculate_tempo(){
  local bpm="$1"
  local target_bpm="$2"
  echo "scale=20; $target_bpm / $bpm" | bc -l
}

stretch_track() {
  local input_path="$1"
  local output_path="$2"
  local tempo="$3"



  [[ -f "$input_path" ]] || fatal "$input_path NOT found"

  if [[ -f "$output_path" ]]; then
    warning "$output_path already exists."
    warning "I keep $output_path instead of new stretch"
    warning "Delete folder or files if you want to re-encode"
    return
  fi

  if awk 'BEGIN { exit !('"$tempo"' == 1) }'; then
    info "No tempo/bpm change. Just copy "
    cp "$input_path" "$output_path"
    return
  fi

  rubberband "$input_path" --tempo "$tempo" "${RUBBERBAND_OPTIONS[@]}" "$output_path"
}


stretch_song(){
    [[ "${#@}" != "3" ]] && fatal "$FUNCNAME: not enough arguments. provide input_dir ourput_dir and tempo"

    local input_dir="$1"
    local output_dir="$2"
    local tempo="$3"

    [[ -d "$input_dir" ]] || fatal "$FUNCNAME: $input_dir does not exist"
    [[ -d "$output_dir" ]] && warning "$FUNCNAME: output dir $output_dir already exists"
    mkdir -p "$output_dir"

    local FILE_NAMES=()
    mapfile -t FILE_NAMES < <(get_audio_filenames "$input_dir")

    local input_path
    local output_path

    for filename in "${FILE_NAMES[@]}"; do
      input_path="$input_dir/$filename"
      output_path="$output_dir/$filename"

    input_dir_print=$(basename $input_dir)
    output_dir_print=$(basename $output_dir)

      info "Stretch audio:   $input_dir_print/$input_filename -> $output_dir_print/$output_filename"
      stretch_track "$input_path" "$output_path" "$tempo"


    done


}

compress_song(){
  [[ "${#@}" != "3" ]] && fatal "$FUNCNAME: not enough arguments. provide input_dir ourput_dir and file_format"

  local input_dir="$1"
  local output_dir="$2"
  local file_format="$3"

  [[ -d "$input_dir" ]] || fatal "$FUNCNAME: $input_dir does not exist"
  [[ -d "$output_dir" ]] && warning "$FUNCNAME: output dir $output_dir already exists"
  mkdir -p "$output_dir"

  local INPUT_FILENAMES=()
  mapfile -t INPUT_FILENAMES < <(get_audio_filenames "$input_dir")


  local input_path
  local output_filename
  local output_path

  for input_filename in "${INPUT_FILENAMES[@]}"; do
    input_path="$input_dir/$input_filename"

    output_filename=${input_filename%.*}.${file_format}
    output_path="$output_dir/$output_filename"

    input_dir_print=$(basename $input_dir)
    output_dir_print=$(basename $output_dir)

    info "Compress audio: $input_dir_print/$input_filename -> $output_dir_print/$output_filename"
    compress_track "$input_path" "$output_path"


  done
}

compress_track(){
  local input_path="$1"
  local output_path="$2"


  [[ -f "$input_path" ]] || fatal "$input_path NOT found"

  if [[ -f "$output_path" ]]; then
    warning "$output_path already exists."
    warning "I keep $output_path instead of new compression"
    warning "Delete folder or files if you want to re-encode"
    return
  fi

  ffmpeg -i "$input_path" "${FFMPEG_OPTIONS[@]}"  "$output_path"

}




get_audio_filenames_from_dir(){
  local input_dir="$1"
  [[ ! -n "$input_dir" ]] && fatal "$FUNCNAME: input path must be provided"
  [[ ! -d "$input_dir" ]] && fatal "input_dir NOT found"

  for filepath in "$input_dir"/*; do
    if ffprobe -v quiet "$filepath"; then
          filename=$(basename "$filepath")
          printf '%s\n' "$filename"
    fi


  done
}

get_audio_filenames_from_config(){
  local input_dir="$1"
  jq -rM '.tracks[].filename' "$input_dir/$SONG_CONFIG_JSON"
}

get_audio_filenames() {
  local input_dir="$1"
  if [[ -f "$input_dir/$SONG_CONFIG_JSON" ]]; then
#    info "get filenames from $input_dir/$SONG_CONFIG_JSON"
    get_audio_filenames_from_config "$input_dir"
  else
#    info "get filenames from directory $input_dir"
    get_audio_filenames_from_dir  "$input_dir"
  fi
}


