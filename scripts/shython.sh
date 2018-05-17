##########
# ARRAYS #
##########

list() {
    local __=$1; shift
    eval "$__=("$@")"
}

len() {
    eval "echo \${#$1[@]}"
}

keys() {
    eval "echo \${!$1[@]} | tr ' ' $'\n'"
}

get() {
    eval "echo \${$1[$2]}"
}

values() {
    keys $1 | {
        while read i; do get $1 $i; done
    }
}


###########
# STRINGS #
###########

str.rstrip() {
    local __="$2"
    echo "${__%%$1}"
}

str.lstrip() {
    local __="$2"
    echo "${__##$1}"
}

str.strip() {
    str.lstrip "$(str.rstrip "$2" "$1")"
}

str.add() {
    local __
    for __ in "$@"; do printf '%s' "$__"; done; echo
}


#############
# ITERATORS #
#############

zip() {
    local _1=$(mktemp -u) _2=$(mktemp -u) k1 k2 line
    mkfifo $_1; mkfifo $_2
    keys $1 > $_1; keys $2 > $_2
    join $_1 $_2 | {
        while read line; do k1=${line%% *} k2=${line##* }
            eval "printf '%s\n' \${$1[$k1]}"
            get $1 "$k2"
        done
    }
}

###############
# COMBINATORS #
###############

map() {
    local cmd="$1" iter __
    echo "$cmd"
    [ ! -z $2 ] && iter="values $2" || iter="cat -"
    $iter | {
        while read __; do $cmd "$__"; done
    }
}

_map() {
    COMPREPLY
}

flipped() {
    $1 "$3" "$2"
}
