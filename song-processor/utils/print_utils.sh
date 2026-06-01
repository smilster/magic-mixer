# Colors
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
RESET='\033[0m'

fatal() {
  echo -e "${RED}[F A T A L] $1${RESET}"
  echo -e "${RED}[E R R O R] ${RESET}"
  echo
  exit 1
}

warning() {
  echo -e "${YELLOW}[ WARNING ]${RESET} $1"
}

info() {
  echo -e "${BLUE}[ I N F O ]${RESET} $1"
}

success() {
  echo -e "${GREEN}[ SUCCESS ]${RESET} $1"
}

printHTML () {
  local song_database="$1"
  local song_config_json="$2"
  local SONG_IDS=()
  mapfile -t SONG_IDS < <(find "$song_database" -name "$song_config_json" -printf '%P\n' | awk -F "/" '{print $1}' | sort)


  info "You may use the following in your index.html "
  echo
  echo '<div id="magic-mixer">'

  for newSongId in "${SONG_IDS[@]}"; do
  echo "    <song>$newSongId</song>"
  done
  echo "</div>"

}