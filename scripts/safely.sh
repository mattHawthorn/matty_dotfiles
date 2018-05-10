#!/usr/bin/env bash
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
    [ $dec -gt 0 ] && t="${t::-$dec}.${t:${#t}-$dec:$dec}"
    echo "    $label $1: runtime $t$units"
    [ $mode == f ] && eval "unset $RUNTIME_VAR_PREFIX$1"
}

progress() {
    _time_report p "$@"
}

finish() {
    _time_report f "$@"
}

