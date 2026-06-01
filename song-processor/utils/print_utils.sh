# Colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RESET='\033[0m'

fatal() {
  echo -e "${RED}[FATAL] $1${RESET}"
  echo -e "${RED}[EXIT]${RESET}"
  echo
  exit 1
}

warning() {
  echo -e "${YELLOW}[WARNING]${RESET} $1"
}

info() {
  echo -e "${BLUE}[INFO]${RESET} $1"
}

success() {
  echo -e "${GREEN}[SUCCESS]${RESET} $1"
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