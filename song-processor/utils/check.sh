#source print_utils.sh

check_all_dependencies(){

  check_dependency ffmpeg
  check_dependency ffprobe
  check_dependency rubberband
  check_dependency awk
  check_dependency sed
  check_dependency jq
  check_dependency bc

  success "All checks passed."
}

check_config_dependencies(){

  check_dependency awk
  check_dependency sed
  check_dependency jq
  check_dependency ffprobe

  success "All checks passed."
}



is_number() {
  [[ "$1" =~ ^[+-]?([0-9]+([.][0-9]+)?|[.][0-9]+)$ ]]
}

check_if_array_contains() {
  local needle="$1"
  shift

  local item
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done

  return 1
}

check_dependency(){
    local probe_command="$1"
    local path=$(command -v "$probe_command")
    [[ ! $path ]]  && fatal "$probe_command NOT found."
    success "✔ $probe_command: $path"
}





check_ffmpeg_encoder(){
  local file_format="$1"
  [[ "${#file_format}" == "0" ]] && fatal "$FUNCNAME: Encoder file_format (e.g., mp3, aac) must be provided";

  local ENCODERS=$(ffmpeg -encoders 2>/dev/null | awk -v file_format="$file_format" '$0 ~ file_format {print $2}' | sort -u | paste -sd ' ' -)

      if [[ -n "$ENCODERS" ]]; then
        success "✔ $file_format encoder(s): $ENCODERS"
      else
        fatal "No $file_format encoder found"
      fi
}

check_ffmpeg_decoder(){
  local file_format="$1"
  [[ "${#file_format}" == "0" ]] && fatal "$FUNCNAME: Encoder file_format (e.g., mp3, aac) must be provided";

  local DECODERS=$(ffmpeg -decoders 2>/dev/null | awk -v file_format="$file_format" '$0 ~ file_format {print $2}' | sort -u | paste -sd ' ' -)

      if [[ -n "$DECODERS" ]]; then
        success "$file_format decoder(s): $DECODERS"
      else
        fatal "No $file_format decoder found"
      fi
}
