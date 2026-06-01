#source print_utils.sh;
#source audio_processor.sh

SONG_CONFIG_JSON="config.json";
DEFAULT_SONG_JSON="default_song.json"
DEFAULT_TRACK_JSON="default_track.json";

gen_track_config() {
  local filename="$1";
  local label="${filename%.*}";
  label="${label:0:8}";

  local track_config;
  track_config="$(<$DEFAULT_TRACK_JSON)";
  track_config=$(
    echo "$track_config" \
    | sed "s/_FILENAME/$filename/g" \
    | sed "s/_LABEL/$label/g" \
    | sed "s/^/\t/g"
  )
  echo "$track_config"
}

gen_track_configs(){

    local track_configs+=$'[\n';
    for filename in "$@"; do
      track_configs+=$(gen_track_config "$filename");
      [[ "$filename" != "${FILE_NAMES[-1]}" ]] && track_configs+=",";
      track_configs+=$'\n';
    done
    track_configs+=$'  ]';

    echo "$track_configs"
}



gen_song_config(){

  local songId="$1"

  shift 1

  local FILE_NAMES=("$@")


  local track_configs
  track_configs=$(gen_track_configs "${FILE_NAMES[@]}")
  track_configs=${track_configs//$'\n'/\\$'\n'} # handle line breaks


  local song_config
  song_config="$(<${DEFAULT_SONG_JSON})";
  song_config=$(
    echo "$song_config" \
    | sed "s/_TITLE/$songId/g" \
    | sed "s/\"_TRACKS\"/$track_configs/g"
  )
  echo "$song_config"

}

gen_default_song_config_json(){
  local input_dir="$1"
  local songId
  songId=$(basename "$input_dir");
  local FILE_NAMES=()
  mapfile -t FILE_NAMES < <(get_audio_filenames "$input_dir")
  [[ "${#FILE_NAMES}" == "0" ]] && fatal "No audio files defined!"
  gen_song_config "$songId" "${FILE_NAMES[@]}" > "$input_dir/$SONG_CONFIG_JSON"
}




change_config_key(){
  local input_dir="$1"
  local key="$2"
  local value="$3"

  jq ".$key = $value" "$input_dir/$SONG_CONFIG_JSON" > "$input_dir/tmp.json"
  mv "$input_dir/tmp.json" "$input_dir/$SONG_CONFIG_JSON"

}


change_file_format(){
  local input_dir="$1"
  local file_format="$2"
  local song_config_json="$input_dir/$SONG_CONFIG_JSON"
  local FILE_NAMES=()
  mapfile -t FILE_NAMES < <(get_audio_filenames_from_config "$input_dir")
  for old_filename in "${FILE_NAMES[@]}"; do
        new_filename=${old_filename%.*}.${file_format}
        sed -i "s/$old_filename/$new_filename/g" "$song_config_json"
  done

}





