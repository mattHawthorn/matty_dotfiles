#!/usr/bin/env bash

docker-shell(){
    local CONTAINER="$1" shell=bash; shift
    [ ! -z "$1" ] && shell="$@"
    docker exec -it "$CONTAINER" $shell
}

container-mounts() {
   docker container inspect "$1" | jq  ".[0].Mounts"
}

container-exists() {
    case $(docker container ls -a -f name="$1" | wc -l) in
        1) echo false && return 1 ;;
        *) echo true && return 0 ;;
    esac
}

container-is-running() {
    case $(docker container inspect "$1" | jq -r '.[0].State.Status') in
        running) echo true && return 0 ;;
        *) echo false && return 1 ;;
    esac
}

container-is-bound() {
    local SOURCE="$1" DEST="$2" CONTAINER="$3"
    if [[ $(container-mounts "$CONTAINER" |
        jq  "map(select(.Type == \"bind\")) |
             map(select(.Destination == \"$DEST\")) |
             map(select(.Source == \"$SOURCE\")) | length") -ne 0 ]]; then
        echo true && return 0
    fi
    echo false && return 1
}
