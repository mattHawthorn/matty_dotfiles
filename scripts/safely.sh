#!/usr/bin/env bash
UNSAFECODE=0
safely(){
    [[ "$SAFE" == "$UNSAFECODE" ]] && "$@" || echo "    RUN:  $@"
}
