#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
echo "$SCRIPT_DIR"

source "$SCRIPT_DIR/utils/print_utils.sh"
source "$SCRIPT_DIR/utils/check.sh" # depends on print_utils
check_config_dependencies

source "$SCRIPT_DIR/utils/audio_processor.sh" # depends on print_utils
source "$SCRIPT_DIR/utils/config_handler.sh" # depends on print_utils and audio_processor

SONG_DATABASE="$SCRIPT_DIR/../songs";

# parse parameters
ALL_SONG_CONFIG_KEYS=();

ALL_SONG_CONFIG_KEYS+=("songId")
ALL_SONG_CONFIG_KEYS+=("bpm")
ALL_SONG_CONFIG_KEYS+=("timeSignature")

source "$SCRIPT_DIR/utils/parameter_parser.sh"  #depends on print_utils, check and config_handler


song_dir_original="$SONG_DATABASE/$songId"

if [[ "$song_config_exists" == "1" ]]; then
  warning "$song_dir_original/$SONG_CONFIG_JSON already exists!"
  read -n 1 -r -p "Overwrite? (y/N): " answer
  echo

  case "$answer" in
    y|Y)
      rm "$song_dir_original/$SONG_CONFIG_JSON"
      ;;
    *)
      info "Skipped."
      exit 0
      ;;
  esac
fi

gen_default_song_config_json "$song_dir_original"
change_config_key "$song_dir_original" "bpm" "$bpm"
change_config_key "$song_dir_original" "timeSignature" "$timeSignature"

echo
success "D O N E"
success "Created $SONG_CONFIG_JSON for $songId!"
echo
printHTML "$SONG_DATABASE" "$SONG_CONFIG_JSON"




