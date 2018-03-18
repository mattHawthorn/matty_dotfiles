n_nonflags() {
    local n=0
    while [[ ( ! -z "$1" ) && "$1" = "${1#-}" ]]; do 
        (( n++ )); shift;
    done
    echo $n
}

TITLE_SCRIPT='
BEGIN { split("a the to at in on with and but or", w)
        for (i in w) nocap[w[i]] }

function cap(word) {
    return toupper(substr(word,1,1)) tolower(substr(word,2))
}

{
  for (i=1; i<=NF; ++i) {
      printf "%s%s", (i==1||i==NF||!(tolower($i) in nocap)?cap($i):tolower($i)),
                     (i==NF?"\n":" ")
  }
}'

titleize() {
    echo $@ | tr -dc '[:alnum:][:blank:]-_' | awk "$TITLE_SCRIPT" | tr ' ' '_'
}

papertitle() {
    local author year len=$(n_nonflags "$@")
    local title="$(titleize ${@:1:$len})"
    shift $len
    while [ $# -gt 0 ]; do
        case "$1" in
            -y) year=$2; shift 2
                if ! validate_regex $year '19[0-9]{2}|20[01][0-9]'; then
                    echo "Bad year: $year"; return 1
                fi
                ;;
            -a) shift; len=$(n_nonflags "$@")
                author="$(titleize ${@:1:$len} | sed -E 's/[Ee]t\.?[-_][Aa]l\.?/et_al/')"
                shift $len
                ;;
            -*) echo "Unknown option: $1; legal options are -a, -y"; return 1
                ;;
        esac
    done
    if [ -z "$year" ]; then
        echo "Warning: no year!" >&2
    else
        year="($year)"
    fi
    if [ -z "$author" ]; then
        echo "Warning: no author!" >&2
    else
        author="$author-"
    fi
    echo "$author$title$year"
}

validate_regex() {
    echo "$1" | grep -qE "$2" && return 0 || return 1
}