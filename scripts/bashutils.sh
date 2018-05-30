#!/usr/bin/env bash

# command wrappers for suppression of execution and printing to stdout
UNSAFECODE=0
UNQUIETCODE=0

safely(){
    if [[ "$SAFE" == "$UNSAFECODE" ]]; then 
        "$@" 
        local STATUS=$?
        [ $STATUS -ne 0 ] && echo "    FAILED-$STATUS: $@"
        return $STATUS
    else
        echo "    RUN:  $@"
    fi
}

quietly() {
    if [[ "$QUIET" == "$UNQUIETCODE" ]]; then "$@"; else "$@" > /dev/null; fi
}

background() {
    "$@" &
    echo $!
}

# run time reporting utils
ns_() {
    date +%s%N
}

us_() {
    echo $(($(date +%s%N)/1000))
}

ms_() {
    echo $(($(date +%s%N)/1000000))
}

RUNTIME_VAR_PREFIX=t__

start() {
    eval "$RUNTIME_VAR_PREFIX$1=\$(ns_)"
    echo "$(_time_report_indent)  STARTED $1"
}

_time_report_indent() {
    local jobs=($(compgen -v $RUNTIME_VAR_PREFIX))
    local njobs=${#jobs[@]}
    printf '% '$((2 * $njobs))s ''
}

_time_report() {
    local mode=$1; shift
    local units=ms denom=1000 dec=3 label=RUNNING t
    
    [ $mode == f ] && label=FINISHED
    case "$1" in
        -M) units=min; denom=600000000; dec=2; shift ;;
        -s) units=s; denom=1000000; dec=3; shift ;;
        -m) units=ms; denom=1000; dec=3; shift ;;
        -u) units=us; denom=1; dec=3; shift ;;
        -n) units=ns; denom=1; dec=0; shift ;;
    esac
    eval "t=\$(((\$(ns_)-\$$RUNTIME_VAR_PREFIX$1)/$denom))"
    [ ${#t} -le $dec ] && t=$(printf "%0$((dec+1))"d)
    [ $dec -gt 0 ] && t="${t::-$dec}.${t:$((${#t}-$dec)):$dec}"
    echo "$(_time_report_indent)  $label $1: runtime $t$units"
    [ $mode == f ] && eval "unset $RUNTIME_VAR_PREFIX$1"
}

progress() {
    _time_report p "$@"
}

finish() {
    _time_report f "$@"
}


# bash introspection utils
fn_exists() {
    type $1 | grep -q "is a function"
}

assignfunc() {
    local oldname=$1
    local newname=$2
    # check if this is a thing we can call
    if type -p $oldname; then
        local def=$newname'() { '$oldname' $@; }'
        eval $def
    else
        echo "$oldname isn't callable"
    fi
}

lscronjobs() {
    [ $# -lt 1 ] && echo "Usage: runcronjob KEYWORD [ KEYWORD [ KEYWORD ... ] ]"
    local keywords="$@" njobs=0 jobs job
    crontab -l | cut -f 6- -d ' ' | grep -E "$keywords" | {
        while read job; do
            echo "$job"
            njobs=$((njobs + 1))
        done
        [ $njobs -lt 1 ] && echo "No jobs found which match '$keywords'" >&2 && return 1
    }
}

runcronjob() {
    local all=false line
    if [ "$1" == "-a" ]; then
        all=true; shift
    fi
    lscronjobs "$@" | {
        while read line; do
            eval $line
            ! $all && break
        done
    }
}

export BASHUTILS_IMPORTED=1

