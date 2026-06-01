#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
echo $SCRIPT_DIR

source "$SCRIPT_DIR/utils/print_utils.sh"

SONG_DATABASE="$SCRIPT_DIR/../songs";
SONG_CONFIG_JSON="config.json";
INDEX_HTML="$SCRIPT_DIR/../index.html"



tmpfile=$(mktemp)
patterns=""

for pattern in "$@"; do
  escaped=$(printf '%s' "$pattern" | sed 's/[.[\*^$()+?{|]/\\&/g')
  patterns+="(?=.*$escaped)"
done

if [[ -z "$1" ]]; then
  printHTML "$SONG_DATABASE" "$SONG_CONFIG_JSON" \
   | grep -P '<song>.*</song>'> "$tmpfile"
else
  [[ -n "$patterns" ]] || fatal "No valid search patterns provided"

  printHTML "$SONG_DATABASE" "$SONG_CONFIG_JSON" \
    | grep -P '<song>.*</song>' \
    | grep -P "$patterns" > "$tmpfile"
fi




sed '/<song.*>.*<\/song>/d' "$INDEX_HTML" \
| sed "/<div.*id=\"magic-mixer\".*>/r $tmpfile" \
> test.html

mv test.html "$INDEX_HTML"

rm -f "$tmpfile"

