#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
echo "$SCRIPT_DIR"

source "$SCRIPT_DIR/utils/print_utils.sh"
source "$SCRIPT_DIR/utils/check.sh" # depends on print_utils
check_all_dependencies

source "$SCRIPT_DIR/utils/audio_processor.sh" # depends on print_utils
source "$SCRIPT_DIR/utils/config_handler.sh" # depends on print_utils and audio_processor

SONG_DATABASE="$SCRIPT_DIR/../songs";


# parse parameters
source "$SCRIPT_DIR/utils/parameter_parser.sh"  #depends on print_utils, check and config_handler


song_dir_original="$SONG_DATABASE/$songId"


for target_bpm in "${TARGET_BPMS[@]}"; do
  new_songId="$songId-${target_bpm}-bpm-$file_format"

  target_tempo="$(calculate_tempo "$bpm" "$target_bpm")"
  song_dir_stretched="$SONG_DATABASE/$songId-${target_bpm}-bpm"
  song_dir_stretched_compressed="$SONG_DATABASE/$new_songId"


  # STRETCH
  stretch_song "$song_dir_original" "$song_dir_stretched" "$target_tempo"

  if [[ "$song_config_exists" == "1" ]]; then
    cp  "$song_dir_original/$SONG_CONFIG_JSON" "$song_dir_stretched/$SONG_CONFIG_JSON"
  else
    gen_default_song_config_json "$song_dir_stretched"
  fi
  change_config_key "$song_dir_stretched" "bpm" "$target_bpm"

  # COMPRESS
  compress_song "$song_dir_stretched" "$song_dir_stretched_compressed" "$file_format"

  if [[ "$song_config_exists" == "1" ]]; then
    cp  "$song_dir_original/$SONG_CONFIG_JSON" "$song_dir_stretched_compressed/$SONG_CONFIG_JSON"
    change_file_format "$song_dir_stretched_compressed" "$file_format"
  else
    gen_default_song_config_json "$song_dir_stretched_compressed"
  fi
  change_config_key "$song_dir_stretched_compressed" "bpm" "$target_bpm"



done
echo
success "A L L   D O N E"
echo
printHTML "$SONG_DATABASE" "$SONG_CONFIG_JSON"




