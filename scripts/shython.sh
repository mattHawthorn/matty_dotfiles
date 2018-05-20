#!/usr/bin/env bash

#############
# CONSTANTS #
#############

FIELD_SEP=$'\t'
FIFO_PREFIX=$(mktemp)


###########
# HELPERS #
###########

alias paste_="paste -d '$FIELD_SEP'"

alias join_="join -t '$FIELD_SEP'"

alias cut_="cut -d '$FIELD_SEP'"

alias print="printf '%s\n'"

alias global='declare -g'

alias tuple=list

alias False=false

alias True=true

pass() {
    return
}

_parse_identifiers() {
    while [ $# -gt 0 ] && [ "${1%:}" == "$1" ]; do echo "$1"; shift; done
    [ "$1" == ":" ] || [ $# -eq 0 ] && return
    echo "${1%:}"
}


#################
# INTROSPECTION #
#################

_public_fns() {
    compgen -A function | filter 'not str.startswith __'
}

_typeflags() {
    local flags=$(declare -p $1)
    local flags=${flags##declare -}
    echo ${flags%% *}
}

isinstance() {
    local flags=$(_typeflags $1)
    local first=${flags:0:1}
    case $2 in
        str)
            case $first in
                -|u|l) return 0 ;;
                *) return 1 ;;
            esac ;;
        list|array)
            case $first in
                a) return 0 ;;
                *) return 1 ;;
            esac ;;
        dict)
            case $first in
                A) return 0 ;;
                *) return 1 ;;
            esac ;;
        int)
            case $first in
                i) return 0 ;;
                *) return 1 ;;
            esac ;;
        *)
            raise ValueError "must pass identifier, typename to isinstance()" ;;
    esac
}

type_() {
    # TODO: functions
    local flags=$(_typeflags $1) || local funcname=
    local first=${flags:0:1}
    case $first in
        a) echo list ;;
        A) echo dict ;;
        -|u|l) echo str ;;
        i) echo int ;;
        *) 
    esac
}


#############
# OPERATORS #
#############

# readable math
.:() { 
    echo $(( $@ ));
}

itemgetter() {
    get $2 "$1"
}

bool(){
    "$@" >/dev/null && echo true || echo false
}

not() {
    "$@" >/dev/null && echo false || echo true
}


########
# INTS #
########

int() {
    declare -ig $1=$2
}

int.infix() {
    echo $(( $2 $1 $3 ))
}

int.prefix() {
    echo $(( $1 $2 ))
}

alias int.add="int.infix '+'"

alias int.sub="int.infix '-'"

alias int.mul="int.infix '*'"

alias int.div="int.infix '/'"

alias int.mod="int.infix '%'"

alias int.and="int.infix '&'"

alias int.or="int.infix '|'"

alias int.xor="int.infix '^'"

alias int.mul="int.infix '*'"

alias int.not="int.prefix '~'"


#########
# LISTS #
#########

list() {
    local __=$1; shift
    unset $__
    global -a $__
    eval "$__=(\"\$@\")"
}

list.contains() {
    values $1 | {
        while read line; do
            [ "$line" == "$2" ] && return
        done
    }
    return 1
}

len() {
    eval "echo \${#$1[@]}"
}

alias list.iter=values

reversed() {
    local i vs IFS=$'\n'
    vs=($(values $1))
    for (( i = $(len $1) - 1; i >= 0; i-- )); do echo "${vs[$i]}" ; done
}


#########
# DICTS #
#########

dict() {
    # bash 4+ only!
    local __=$1; shift
    unset $__
    global -A $__
    while [ ! -z "$1" ]; do eval "$__["$1"]='"$2"'"; shift 2; done
}

get() {
    eval "echo \"\${$1["$2"]}\""
}

keys() {
    global -a __
    eval "__=(\"\${!$1[@]}\")"
    for (( i=0; i<$(len __); i++ )); do echo "${__[$i]}"; done
}

values() {
    local __ IFS=''
    keys $1 | {
        while read __; do get "$1" "$__"; done
    }
}

items() {
    local __ IFS=''
    keys $1 | {
        while read __; do printf '%s'"$FIELD_SEP" "$__"; get "$1" "$__"; done
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
    str.lstrip "$1" "$(str.rstrip "$1" "$2")"
}

str.rjust() {
    printf "%""$1""s\n" "$2"
}

str.ljust() {
    printf "%-""$1""s\n" "$2"
}

str.add() {
    local __
    for __ in "$@"; do printf '%s' "$__"; done; echo
}

str.mul() {
    local __
    for (( __=0; __ < $1; __++ )); do printf '%s' "$2"; done; echo
}

str.split() {
    local sep="$1"; shift
    echo "$1" | tr "$sep" $'\n'
}

str.replace() {
    local pat="$1" rep="$2"; shift 2
    echo "$@" | sed 's/'"$pat"/"$rep"'/g'
}

str.startswith() {
    [ "$2" != "${2##$1}" ]
}

str.endswith() {
    [ "$2" != "${2%%$1}" ]
}

str.iter() {
    local i
    for (( i=0; i< $(str.len $1); i++ )); do eval echo "\${$1:$i:1}"; done
}

str.len() {
    eval "echo \${#$1}"
}


#############
# ITERATORS #
#############

_setfifoprefix() {
    [ -z "$FIFO_PREFIX" ] && FIFO_PREFIX=$(mktemp -u) || return 1
}

_nextfifo() {
    if _setfifoprefix; then
        echo 0; return
    fi
    local fifos=($(_allfifos))
    if [ ${#fifos[@]} -gt 0 ]; then
        local lastfifo="${fifos[-1]}"
        lastfifo="${lastfifo##*.}"
    else
        lastfifo=0
    fi
    local n i nextfifo
    [ -z "$1" ] && n=1 || n=$1
    for (( i=1; i <=n; i++ )); do
        nextfifo=$FIFO_PREFIX.$(( lastfifo + i ))
        if mkfifo $nextfifo; then
            echo $nextfifo
        else
            ((n++))
        fi
    done
}

_allfifos() {
    ls $FIFO_PREFIX.* 2>/dev/null
}

_rmfifos() {
    rm -f $(_allfifos)
}

_tofifos() {
    local firstfifo=$(_nextfifo) newfifo
    local fifos=(
        $(for (( i=0; i < $#; i++ )); do 
            newfifo=$FIFO_PREFIX.$((firstfifo + i))
            # mkfifo $newfifo && echo $newfifo;
            echo $newfifo
        done
        )
    )
    # for (( i=0; i < $#; i++ )); do ( echo "${@:$((i + 1)):1}" ); done && echo ${fifos[@]}
    for (( i=0; i < $#; i++ )); do ( eval "${@:$((i + 1)):1}" > "${fifos[$i]}" & ); done && echo ${fifos[@]} || rm -f ${fifos[@]}
}

_joinfds() {
    if [ $# -eq 1 ]; then
        cat "$1"
        return
    elif [ $# -eq 2 ]; then
        join_ "$1" "$2"
    fi
    local lastfifo="$1" fifos=(); shift
    while [ ! -z "$1" ]; do
        fifo=$(_nextfifo)
        fifos="$fifos $fifo"
        ( cat "$lastfifo" | join_ - "$1" > $fifo & )
        lastfifo=$fifo
        shift
    done
    ( cat $fifo )
    rm -f $fifos
}

dict.valzip() {
    local _1=$(mktemp -u) _2=$(mktemp -u) k1 k2 line
    mkfifo $_1; mkfifo $_2
    ( keys $1 | sort > $_1 & )
    ( keys $2 | sort > $_2 & )
    (
        join -t "$FIELD_SEP" $_1 $_2 | {
            while read line; do k1="${line%%$FIELD_SEP*}" k2="${line##*$FIELD_SEP}"
                printf '%s'"$FIELD_SEP" "$(get $1 "$k1")"
                get $2 "$k2"
            done
        }
    )
}

list.valzip() {
    local _1=$(mktemp -u) _2=$(mktemp -u) k1 k2 line
    mkfifo $_1; mkfifo $_2
    ( keys $1 | sort > $_1 & )
    ( keys $2 | sort > $_2 & )
    (
        join -t "$FIELD_SEP" $_1 $_2 | {
            while read line; do k1="${line%%$FIELD_SEP*}" k2="${line##*$FIELD_SEP}"
                eval "printf '%s$FIELD_SEP' \${$1[$k1]}"
                get $2 "$k2"
            done
        }
    )
}

iter.zip() {
    local fifos=($(_nextfifo $#))
    for (( i=1; i <= $#; i++ )); do ( ${@:i:1} >${fifos[$((i-1))]} & ); done
    ( paste -d "$FIELD_SEP" ${fifos[@]} )
    for i in "${fifos[@]}"; do rm -f "$i"; done
}

all() {
    local line
    while read line; do
        if ! "$line" >/dev/null; then return 1; fi
    done
}

any() {
    local line
    while read line; do
        if "$line" >/dev/null; then return 0; fi
    done
}

repeat() {
    for (( i=0; i<$1; i++ )); do echo "$2"; done
}


##########
# LAMBDA #
##########

lambda() {
    local varnames=($(_parse_identifiers "$@"))
    shift $(len varnames)
    [ "$1" == ':' ] && shift
    local expression="$1"; shift
    for (( i=0; i<${#varnames[@]}; i++ )); do
        eval "local ${varnames[i]}=$1"; shift
        # eval echo "${varnames[i]}: \$${varnames[i]}"
    done
    # echo "$expression"
    eval "$expression"
}


###############
# COMBINATORS #
###############

map() {
    local cmd="$1" iter __; shift
    if [ "$cmd" == lambda ]; then
        local varnames=($(_parse_identifiers $@))
        shift $(len varnames)
        [ "$1" == ":" ] && shift
        cmd="lambda ${varnames[@]} : '$1'"; shift
    fi
    if [ $# -eq 0 ]; then 
        iter="cat -"
    else
        iter="values $1"
    fi
    $iter | {
        while read __; do eval "$cmd $__" 2>/dev/null; done
    }
}

filter() {
    local cmd="$1" iter __
    [ ! -z $2 ] && iter="values $2" || iter="cat -"
    $iter | {
        while read __; do $cmd "$__" >/dev/null 2>/dev/null && echo "$__" ; done
    }
}

complete -A function map

flipped() {
    $1 "$3" "$2"
}


##############
# EXCEPTIONS #
##############

declare -g ERROR_MSG=''

declare -gA ERROR_CODES=(
    [ArithmeticError]=10
    [FloatingPointError]=10
    [ZeroDivisionError]=10
    [OverflowError]=10
    
    [ValueError]=20
    [TypeError]=21
    [AttributeError]=22
    [IndexError]=23
    [KeyError]=24
    [LookupError]=25
    
    [EnvironmentError]=30
    [ModuleNotFoundError]=31
    [NameError]=32
    [NotImplementedError]=33
    [ReferenceError]=34
    [UnboundLocalError]=35
    
    [ImportError]=40
    [IndentationError]=41
    [SyntaxError]=42
    [TabError]=43
    
    [UnicodeDecodeError]=50
    [UnicodeEncodeError]=51
    [UnicodeError]=52
    [UnicodeTranslateError]=53
    
    [BlockingIOError]=60
    [BrokenPipeError]=61
    [BufferError]=62
    [EOFError]=63
    [FileExistsError]=64
    [FileNotFoundError]=65
    [IOError]=66
    [IsADirectoryError]=67
    [NotADirectoryError]=68
    
    [ChildProcessError]=70
    [InterruptedError]=71
    [OSError]=72
    [ProcessLookupError]=73
    [SystemError]=74
    [PermissionError]=75
    
    [ConnectionAbortedError]=80
    [ConnectionError]=81
    [ConnectionRefusedError]=82
    [ConnectionResetError]=83
    
    [MemoryError]=90
    [RecursionError]=91
    [TimeoutError]=92
    
    [AssertionError]=101
    [RuntimeError]=102
    
    [Exception]=1
    [ShellBuiltinError]=2
    
    [CommandNotFound]=127
    [CommandCannotExecute]=126
    [InvalidExitArgument]=128
    
    [Fatal-SIGHUP]=129
    [Fatal-KeyboardInterrupt-SIGINT]=130
    [Fatal-SIGQUIT]=131
    [Fatal-SIGILL]=132
    [Fatal-SIGTRAP]=133
    [Fatal-SIGABRT]=134
    [Fatal-SIGEMT]=135
    [Fatal-SIGFPE]=136
    [Fatal-SIGKILL]=137
    [Fatal-SIGBUS]=138
    [Fatal-SIGSEGV]=139
    [Fatal-SIGSYS]=140
    [Fatal-SIGPIPE]=141
    [Fatal-SIGALRM]=142
    [Fatal-SIGTERM]=143
    [Fatal-SIGURG]=144
    [Fatal-SIGSTOP]=145
    [Fatal-SIGTSTP]=146
    [Fatal-SIGCONT]=147
    [Fatal-SIGCHLD]=148
    [Fatal-SIGTTIN]=149
    [Fatal-SIGTTOU]=150
    [Fatal-SIGIO]=151
    [Fatal-SIGXCPU]=152
    [Fatal-SIGXFSZ]=153
    [Fatal-SIGVTALRM]=154
    [Fatal-SIGPROF]=155
    [Fatal-SIGWINCH]=156
    [Fatal-SIGINFO]=157
    [Fatal-SIGUSR]=158
    [Fatal-SIGUSR]=159
)

dict EXCEPTIONS $(iter.zip 'values ERROR_CODES' 'keys ERROR_CODES')


SHYTHON_ERRFILE=$(mktemp)
SHYTHON_ERRCODE=0


_rm_errfile() {
    [ -f $SHYTHON_ERRFILE ] && rm $SHYTHON_ERRFILE
}

try:() {
    "$@" 2>$SHYTHON_ERRFILE
    SHYTHON_ERRCODE=$?
}

except() {
    local errname
    [ $SHYTHON_ERRCODE -eq 0 ] && return
    
    errnames=($(_parse_identifiers $@))
    shift $(len errnames)
    [ "$1" == ':' ] && shift
    
    for (( i=0; i<${#errnames[@]}; i++)); do
        if [ $(get ERROR_CODES "${errnames[i]}") -eq $SHYTHON_ERRCODE ]; then
            SHYTHON_ERRCODE=0
            "$@" 2>$SHYTHON_ERRFILE
            raise_ $?
            return $?
        fi
    done
}

except:() {
    [ $SHYTHON_ERRCODE -eq 0 ] && return
    SHYTHON_ERRCODE=0
    "$@"
    return $?
}

raise() {
    local errname="$1"; shift
    local code=${ERROR_CODES[$errname]}
    if [ $# -gt 0 ]; then 
        ERROR_MSG="$@"
    else
        [ -f $SHYTHON_ERRFILE ] && ERROR_MSG="$(cat $SHYTHON_ERRFILE)"
    fi
    echo "$errname: $ERROR_MSG"
    return $code
    rm $SHYTHON_ERRFILE
}

raise_() {
    local code="$1"; shift
    local name="${EXCEPTIONS[$code]}"
    [ $# -gt 0 ] && raise "$name" "$@" || raise "$name"
}


###############
# ERROR TRAPS #
###############

# On error, print a readable name to stderr
trap 'raise $(get EXCEPTIONS $?)' >&2 ERR

trap _rmfifos EXIT
trap _rm_errfile EXIT

