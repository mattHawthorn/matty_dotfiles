#!/usr/bin/env bash

# Python helper-outers

_set_py_not_stdlib_script() {
local IFS=''
PY_NOT_STDLIB_SCRIPT="$(while read  line; do echo "$line"; done <<EOF
import sys, os
dirs = []
for n in sys.path:
    if n.endswith("/site-packages") or n.endswith("/dist-packages"):
        break
    dirs.append(n)

def is_stdlib(name):
    return any(os.path.exists(os.path.join(d, name)) or
               os.path.isfile(os.path.join(d, name + '.py')) or
               any(n.startswith(name + '.') for n in os.listdir(d))
               for d in dirs if os.path.isdir(d))

for f in sys.argv[1:]:
    if f in sys.builtin_module_names:
        continue
    try:
        mod = __import__(f)
    except:
        pass
        # print("Not importable: {}".format(f), file=sys.stderr)
    else:
        if not is_stdlib(f):
            print(f)
EOF
)"
}
_set_py_not_stdlib_script


pydeps() {
    local include_stdlib=false
    if [ $1 == "-s" ]; then include_stdlib=true; shift; fi
    local dir="." interpreter="python" mods
    [ $# -gt 0 ] && dir="$1"
    local modname="$(basename $dir)"
    [ $# -gt 1 ] && interpreter="$2"
    local stdlibdir="$($interpreter -c 'import os; print(os.path.dirname(os.__file__))')"

    local pyscript

    mods="$(
    find "$dir" -name '*.py' -type f -exec grep -oE '^(from|import)\s+([a-zA-Z_][a-zA-Z0-9_]*)' {} \; |
        sed -E 's/(^(from|import)\s+)//' | sort | uniq | {
            while read line; do [ $line == $modname ] || echo $line; done
        }
    )"

    if $include_stdlib; then
        for mod in $mods; do echo mod; done
    else
        $interpreter -c "$PY_NOT_STDLIB_SCRIPT" $mods
    fi
}

# Python starter-uppers

trypy() {
    # try a sequence of commands in a python interpreter,
    # without having to worry about the logout or getting all your
    # lines semicolon-separated, or worrying about the shell's escape handling.
    # works for a list of literal args, treated as lines, or read from stdin
    # if no args are passed
    if [ $# -eq 0 ]; then
        # read stdin
        while read -r line; do
           echo "$line"
        done
    else
        for line in "$@"; do
           echo "$line"
        done
    fi | python -
}

# conda-related aliases
set_conda_env_aliases() {
    if [ -z "$1" ]; then
        local tmpfile=/tmp/conda_env_aliases
        local remove=true
    else
        local tmpfile="$1"
        [ -f "$tmpfile" ] && source "$tmpfile" && return
        local remove=false
    fi
    local env version
    conda env list | tail -n +3 |
        while read line; do
            env=$(echo "$line" | cut -f 1 -d ' ')
            [ ! -z "$env" ] && echo "alias pyenv_$env='source activate $env'" >> $tmpfile
        done
    [ -f "$tmpfile" ] && source "$tmpfile"
    $remove && rm $tmpfile
    alias sa='source activate'
    alias sda='source deactivate'
    alias notebook='jupyter notebook'
    export CONDA_ENV_ALIASES_SET=1
}

set_python_dev_aliases() {
    alias pspi="python setup.py install"
    alias pspd="python setup.py develop"
    
    SANDBOX="$HOME/Desktop/sandbox"
    alias sandbox="cd $SANDBOX"

    case "$OSTYPE" in
        linux*) 
            PYCHARM_DIR="$(find /opt -maxdepth 1 -type d -name 'pycharm*' | sort -V | tail -n 1)"
            alias pycharm="$PYCHARM_DIR/bin/pycharm.sh"
            ;;
        darwin*) 
            PYCHARM_DIR='/Applications/PyCharm\ CE.app'
            alias pycharm='$PYCHARM_DIR/Contents/MacOS/pycharm &'
            ;;
    esac
}


killjupyter() {
    local ports=($@) killed=() nk=()
    local pid port dir_ p i n STATUS=0 USAGE="Usage: $FUNCNAME [-a] [PORT [PORT ...]]"
    
    case $1 in
        -h|--help|'') echo $USAGE; return 1 ;;
        -a|--all) ports=($(jupyter notebook list --json | jq -r '.port')) ;;
        -*) echo "Unknown flag: $1"; echo "$USAGE"; return 1 ;;
    esac
    
    [ ${#ports[@]} -le 0 ] && echo "No ports selected or no jupyter servers running" && return 0
    
    ports=($(for p in ${ports[@]}; do echo $p; done | sort | uniq))
    local f=mktemp    
    jupyter notebook list --json | jq '.pid, .port, .notebook_dir' | xargs -n3 > $f
    
    while read line; do
        pid=$(echo $line | cut -f 1 -d ' ')
        port=$(echo $line | cut -f 2 -d ' ')
        dir_="${line#$pid $port }"
        n=${#ports[@]}
        
        for (( i=0; i < ${#ports[@]}; i++)); do
            p=${ports[i]}
            if [[ "$p" == "$port" ]]; then
                if kill -0 $pid; then
                    echo "Killing server on port $port at dir '$dir_'"
                    if kill -15 $pid; then
                        killed=(${killed[@]} $port);
                        unset 'ports[i]'
                        echo "Sucess"
                    else
                        echo "Failure"
                    fi
                fi
                break
            fi
        done
        # reindex in case we've `unset` anything; arrays are basically hash tables with int keys in bash
        ports=(${ports[@]})
    done < "$f"
    
    echo
    [ ${#killed[@]} -gt 0 ] && echo "Killed jupyter servers on ports ${killed[@]}"
    [ ${#ports[@]} -gt 0 ] && echo "No jupyter servers were running on ports ${ports[@]}" && STATUS=2
    [ ${#nk[@]} -gt 0 ] && echo "Problem killing jupyter servers with pids ${nk[@]} on ports ${nkp[@]}" && STATUS=1
    echo
    [ -e $f ] && rm $f
    return $STATUS
}

# completion showing the ports open on servers
_killjupyter() {
    local flags=('-a' '-h')
    COMPREPLY=($(jupyter notebook list --json | jq '.port' | uniq))
    if [[ $COMP_CWORD -ge 1 && $(expr length "${COMP_WORDS[-1]}") -le 0 ]]; then
        COMPREPLY=(${COMPREPLY[@]} ${flags[@]})
    elif [[ ${COMP_WORDS[-1]#-} != ${COMP_WORDS[-1]} ]]; then
        COMPREPLY=(${flags[@]})
    fi
    # COMPREPLY=(${COMPREPLY[@]} $COMP_CWORD  "'" ${COMP_WORDS[-1]} "'")
}
complete -o filenames -o nospace -F _killjupyter killjupyter


# alias for a new quick-and-dirty new ipython notebook
# default working directory is $SANDBOX
scratchpad() {
    local ENV DIR msg begincmd endcmd
    case "$1" in
        -h|--help)
            echo 'Usage: scratchpad [ENV] [-w | -d WORKING_DIR]'
            echo 'Start a jupyter notebook server in a specified directory using environment $ENV and redirect its ' \
                 'stdout and stderr to a log file, $JUPYTER_LOG, while saving its pid as $JUPYTER_PID.'
            echo
            echo 'By default, ENV is whichever environment is active, and the working dir is '"$SANDBOX"
            echo "type 'tail -f \$JUPYTER_LOG' to watch the log file and 'kill \$JUPYTER_PID' to stop the server"
            echo '-w indicates to start the server in the current working directory and -d can be used to specify a custom dir.'
            return 1 
            ;;
        -*)
            ;;
        *)
            ENV="$1"
            shift
            ;;
    esac

    DIR="$SANDBOX"
    CWD="$(pwd)"

    if [[ ! -z $1 ]]; then
        case $1 in
            "-w")
                DIR="."
                shift
                ;;
            "-d")
                DIR="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    fi


    if [[ ! -z "$ENV" ]]; then
        msg="anaconda environment $ENV"
        begincmd="source activate $ENV"
        endcmd="source deactivate"
    else
        msg="current anaconda environment"
        begincmd=""
        endcmd=""
    fi
    msg="Starting new Jupyter notebook in $DIR using $msg"

    if $begincmd; then
        JUPYTER_LOG="$(mktemp /tmp/XXXX.jupyter.log)"
        cd "$DIR"
        echo "$msg"
        jupyter notebook &>"$JUPYTER_LOG" &
        JUPYTER_PID=$!
        echo "Jupyter server PID is JUPYTER_PID=$JUPYTER_PID"
        echo "Notebook server is logging to JUPYTER_LOG=$JUPYTER_LOG"
        cd "$CWD"
        $endcmd
    else
        echo "Error: no anaconda environment $ENV"
        return 1
    fi
    return 0    
}

# completion showing the ports open on servers
_scratchpad() {
    [[ -z "${CONDA_ENVS[@]}" ]] && 
        CONDA_ENVS=($(conda env list | cut -f 1 -d ' ' | 
                          while read line; do
                              [[ ! -z $line ]] && [[ "${line}" == "${line#\#}" ]] && echo "$line"; 
                          done; )
                   )
    local flags=('-w' '-d' '-h') last=${COMP_WORDS[-1]}
    
    if [[ $COMP_CWORD  -eq 1 ]]; then
        if [[ ${last#-} = ${last} ]]; then
            [ ! -z $last ] && COMPREPLY=(${CONDA_ENVS[@]}) || COMPREPLY=(${CONDA_ENVS[@]} ${flags[@]})
            return
        fi
    fi
    
    if [[ $COMP_CWORD  -gt 1 && "${COMP_WORDS[-2]}" == '-d' ]]; then
        [ ! -z "$last" ] && COMPREPLY=($(ls -d "$last"* 2> /dev/null || echo )) || COMPREPLY=($(ls))
    elif [[ "${COMP_WORDS[-2]}" == '-w' ]]; then
        return
    else
        COMPREPLY=(${flags[@]/"$last"})
    fi
    # COMPREPLY=(${COMPREPLY[@]} $COMP_CWORD  "'" ${COMP_WORDS[-1]} "'")
}
complete -o filenames -o nospace -F _scratchpad scratchpad
