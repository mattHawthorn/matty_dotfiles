#!/usr/bin/env bash

DATEFMT="%Y-%m-%d"
DELIM='_'
RECURSE=0
SUFFIX=0
MAXDEPTH='-maxdepth 0'
TYPES=''
UNDO=0
SAFE=1
VERBOSE=0

source "$(dirname "$BASH_SOURCE")/safely.sh"

usage() {
  echo \
"Prefix filenames with their creation dates/times \
such that they sort lexically by creation time \
automatically.
Usage: datify [-f DATEFMT] [-d DELIM] [-u] [-r] [-s] [-t FILETYPES] PATH [PATH ...]
Options:
  -f DATEFMT   Posix-compliant date format to use.
               Defaults to '%Y-%m-%d'
  -t FILETYPES Only apply dates to files with types in FILETYPES, a string of
               single-character filetype aliases as understood by the `find` 
               command (d for dir, f for file, etc.)
  -r           Apply recursively to subdirectories
  -s           Append date as suffix rather than prefix
  -d DELIM     Use DELIM to split the date portion from the filename portion
  -u           Undo - undo the results of a prior datify call
  -x           Actually execute; otherwise commands are merely printed to stdout
  -v           Print commands to stdout as they are executed
  -h           Print this message and exit
"
}

warn() {
  echo "Warning: $@" >&2
}

getfmtrefs() {
  local s
  for s in $(echo "$1" | grep -o -E '%.|%:+.'); do
    echo "${s#\%}"
  done
}

DATE_FIELDS='YmdHMSTZz'
TZ_FIELDS=':z|::z'

validateDateFmt() {
  local l
  for l in $(getfmtrefs "$1"); do
    case "$l" in
      [$DATE_FIELDS])
        ;;
      "$TZ_FIELDS")
        ;;
      *)
        echo "Unrecognized format specifier: %$l; supported date format specifiers are %$DATE_FIELDS|$TZ_FIELDS" >&2
        return 1
        ;;
    esac
  done
}

dateregex() {
  HOUR='([01][0-9]|[2][0-3])'
  MIN='([0-5][0-9])'
  
  echo "$1" | sed 's/%Y/([12][0-9]{3})/' |
              sed 's/%m/([0][0-9]|[1][12])/' |
              sed 's/%d/([0-2][0-9]|[3][01])/' |
              sed 's/%H/$HOUR/' |
              sed 's/%M|%S/$MIN/' |
              sed 's/%Z/([A-Z]{2,5})/' |
              sed "s/%z/([-+]$HOUR$MIN/" |
              sed "s/%:z/([-+]$HOUR:$MIN/" |
              sed "s/%::z/([-+]$HOUR:$MIN:$MIN/" |
              sed "s/%T/$HOUR:$MIN:$MIN/"
}

while getopts ':hrsuxvf:d:t:' opt; do
  case "$opt" in
    h)
      usage
      exit 1
      ;;
    f)
      if validateDateFmt "$OPTARG"; then
        DATEFMT="$OPTARG"
      else
        echo "Invalid date format: $OPTARG" >&2
        exit 1
      fi
      ;;
    r)
      RECURSE=1
      MAXDEPTH=""
      ;;
    u)
      UNDO=1
      ;;
    s)
      SUFFIX=1
      ;;
    t)
      for (( i=0; i < $(expr length $OPTARG); i++ )); do
          [ -z "$TYPES" ] && TYPES="-type ${OPTARG:$i:1}" ||
                             TYPES="$TYPES -or -type ${OPTARG:$i:1}"
      done
      ;;
    x)
      SAFE=0
      ;;
    v)
      VERBOSE=1
      ;;
    *)
      break
      ;;
  esac
done

shift $(( $OPTIND - 1 ))

if [[ -z "$1" ]]; then
  echo "No path argument!" >&2
  usage
  exit 1
fi


DATEREGEX=$(dateregex "$DATEFMT")

for FILEPATH in "$@"; do
    if [ -d "$FILEPATH" ]; then
        cd "$FILEPATH" 2>/dev/null
        CMD="find '$PWD' -depth $MAXDEPTH $TYPES"
        cd - 2>/dev/null
    elif [ ! -e "$FILEPATH" ]; then
        warn "$FILEPATH does not exist!"        
        continue
    else
        CMD="find '$FILEPATH' -depth -maxdepth 0 $TYPES"
    fi
    
    eval $CMD | {
      while read line; do
        line="${line%/}"
        name="$(basename "$line")"
        basename="${name%%.*}"
        ext="${name#$basename}"
        dir="$(dirname "$line")"
        match="$(echo "$basename" | grep -obE "$DATEREGEX" | head -n 1)"
        
        if [ ! -z "$match" ]; then
            ix=$(echo "$match" | cut -d ':' -f 1)
            match="${match#$ix:}"
            len=$(expr length "$match")
            #echo "    match: $match len: $len"
            #echo loc: $(($ix + $len))
            #echo "    substrings: ${basename::$ix}  ${basename:$(($ix + $len))}"
        else
            match=''
        fi
        
        if [ $UNDO -ne 0 ]; then
          if [ -z "$match" ]; then
            [ $VERBOSE -ne 0 ] && warn "$line did not match date format $DATEFMT"
            continue
          fi
          new="${line%"$name"}${basename::$ix}${basename:$(($ix + $len)):}$ext"
        else
          SECONDS=$(stat -c %Y "$line")
          [ $? -ne 0 ] && warn "Could not stat $line" && continue
          date="$(date -d @$SECONDS +"$DATEFMT")"
          
          if [ ! -z "$match" ]; then
              [ $VERBOSE -ne 0 ] && warn "Prior date present for $line; removing"
              basename="${basename::$ix}${basename:$(($ix + $len))}"
          fi
          [ $SUFFIX -ne 0 ] && new="${line%"$name"}$basename$date$ext" || 
                               new="${line%"$name"}$date$name"
        fi
        
        if [ ! "$line" = "$new" ]; then
            [ "$VERBOSE" -ne 0 ] && echo mv "$line" "$new"
            safely mv "$line" "$new"
        fi
      done
    }
done

