# file inspection/management utils

mkrdir() {
  # recursive mkdir
  local curdir=$(pwd)     
  local dirs=("$(echo $1 | cut -d "/" --output-delimiter=" " -f 1-)")
  if [ ${1:0:1} == '/' ]; then
    dirs=('/' "${dirs[@]}")
  fi
  for d in ${dirs[@]}; do
    if [ ! -d $d ]; then
      mkdir $d
    fi
    cd $d
  done
  cd $curdir
}

robustcopy() {
    local from="$1" to="$2"
    local flag=""
    if [ -d "$from" ]; then
        flag="${flag} -r"
        if [ -d $to ]; then
            flag="${flag} -T"
        fi
    fi
    cp $flag "$from" "$to"
}

BACKUP_SUFFIX=".backup"

backup() {
    # make a backup copy of the first arg in the dir specified by the second.
    # if no second arg is passed, make the backup in the dir where the first arg is located.
    if [ $# -lt 1 ]; then echo "no file specified; aborting" >&2; return 1; fi
    
    local f=$1; shift
    if [ $# -lt 1 ]; then dest="$(dirname "$f")"; else dirname="$1"; shift; fi
    
    if [ ! -d "$dest" ]; then echo "specified directory ${dest} does not exist" >&2; return; fi
    
    # expand glob if any
    local files=($f)
    
    for f in "${files[@]}"; do
        if [ ! "${f%%$BACKUP_SUFFIX}" == "$f" ]; then
           echo "${f} appears to already be a backup file; skipping"
           continue
        fi
        cp -r "$f" "${dest}/$(basename "$f")$BACKUP_SUFFIX"
    done
}

largest() {
    du -hsx * | sort -rh | head -$1
}

rlargest() {
    local size name getsize="numfmt --to=si" findargs="" depth="" verbose="" type="" cmd
    local USAGE="Usage: $FUNCNAME [--bytes|-b] [--depth|-d MAXDEPTH] [--dirs|--files|-f] [--verbose|-v] NFILES [FIND-ARG [...]]"
    while true; do
        case "$1" in
            -*) case "$1" in
                    -h|--help) echo "$USAGE"; return 1 ;;
                    --raw|--bytes|-b) getsize="echo"; shift ;;
                    --depth|--maxdepth|-d) depth="-maxdepth $2"; shift 2 ;;
                    --dirs) [ -z "$type" ] && type="-type d" || type="-type d -o $type"; shift ;;
                    --files|-f) [ -z "$type" ] && type="-type f" || type="-type f -o $type"; shift ;;
                    --verbose|-v) verbose="1"; shift ;;
                    *) echo "Unknown option: $1"; echo "$USAGE"; return 1 ;;
                esac ;;
            *) break ;;
        esac
    done
        
    cmd="find . $depth $type ${*:2} -printf '%s %p\n' | sort -nr | head -$1"
    [ ! -z "$verbose" ] && echo && echo "    $cmd" && echo
    eval $cmd |
        while read line; do
            size=$(echo "$line" | cut -d ' ' -f 1)
            name="${line#$size }"
            echo "$($getsize ${size}) ${name}"
        done;
}


# code inspection utils

partsof() {
    local typeflag="$1"
    shift
    if [ "$1" == "-n" ]; then
        shift
        local only_total=1
    fi
    local pattern=".*$(regexor $*)"
    if [ -z "$only_total" ]; then
        find . -type f -iregex "$pattern" | xargs wc $typeflag
    else
        local fields=($(find . -type f -iregex "$pattern" | xargs wc $typeflag | tail -n 1))
        echo ${fields[0]}
    fi
}

linesof() {
    partsof -l $@
}

wordsof() {
    partsof -w $@
}

charsof() {
    partsof -m $@
}

bytesof() {
    partsof -c $@
}

charsperline() {
    echo "scale=4; $(charsof -n $@) / $(linesof -n $@)" | bc
}

wordsperline() {
    echo "scale=4; $(wordsof -n $@) / $(linesof -n $@)" | bc
}


join_by() { d=$1; shift; echo -n "$1"; shift; printf "%s" "${@/#/$d}"; }

regexor() { echo "\(\.$(join_by "\|\." $*)\)"; }



background() {
    # run command in background and print PID
    "$@" &
    echo $!
}

