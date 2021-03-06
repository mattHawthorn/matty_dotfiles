#!/usr/bin/env bash

# Python helper-outers

_set_py_not_stdlib_script() {
local IFS=''
read -r -d '' PY_NOT_STDLIB_SCRIPT <<"EOF"
import sys, os
bname = os.path.basename
args = sys.argv[1:] if len(sys.argv) >= 1 else []

include_stdlib = False
include_versions = True

if args:
    while args and args[0].startswith("-"):
        if args[0] == "--no-versions":
            include_versions=False
        elif args[0] in ("-s", "--include-stdlib"):
            include_stdlib=True
        else:
            raise ValueError("Unknown flag or option: {}".format(args[0]))
        args = args[1:]
        
if not args:
    exit(0)

dirs = []
for n in sys.path:
    if bname(n) == ("site-packages") or bname(n) == ("dist-packages"):
        break
    dirs.append(n)

def is_stdlib(name):
    return name in sys.builtin_module_names or \
           any(os.path.exists(os.path.join(d, name)) or
               os.path.isfile(os.path.join(d, name + '.py')) or
               any(n.startswith(name + '.') for n in os.listdir(d))
               for d in dirs if os.path.isdir(d))

for f in args:
    if f in sys.builtin_module_names:
        continue
    try:
        mod = __import__(f)
    except:
        pass
        print(f)
        # print("Not importable: {}".format(f), file=sys.stderr)
    else:
        if include_stdlib or not is_stdlib(f):
            if not include_versions or not hasattr(mod, "__version__"):
                print(f)
            else:
                print("{}=={}".format(f, getattr(mod, "__version__")))
EOF
}
_set_py_not_stdlib_script


pydeps() {
    local flags=()
    local modname_pattern='([a-zA-Z_][.a-zA-Z0-9_]*)'
    local interpreter="python"
    local import_pattern pyscript modname requirements
    local filename_pat=".*\.(py|pyx|pxd)"

    while [ "$1" != "${1#-}" ]; do
        case "$1" in
            -h) echo "USAGE: pydeps [-h] [-s|--include-stdlib] [--no-cython] [--no-versions] [-n|--namespace NAMESPACE_PATTERN] [-i|--interpreter PYTHON INTERPRETER] [MODULE_DIR]"
                return 1
                ;;
            -s|--include-stdlib|--no-versions) flags=("$1" "${flags[@]}"); shift
                ;;
            --namespace|-n) modname_pattern="($2\.$modname_pattern)"; shift 2
                ;;
            --no-cython) filename_pat=".*\.py"; shift
                ;;
            --interpreter|-i) interpreter="$2"; shift 2
                ;;
            *) echo "Unknown option: $1"; return 1
                ;;
        esac
    done

    [ $# -gt 0 ] && dir="$1" || dir="$(pwd)"

    modname="$(basename $dir)"
    import_pattern="^(from|import)\s+$modname_pattern"
    
    mods="$(
    find "$dir" -regextype posix-egrep -regex "$filename_pat" -type f -exec grep -oE "$import_pattern" '{}' \; |
        sed -E 's/(^(from|import)\s+)//' | sort | uniq | {
            while read line; do [ "$line" == "$modname" ] || echo "$line"; done
        }
    )"
    
    "$interpreter" -c "$PY_NOT_STDLIB_SCRIPT" ${flags[@]} $mods
}


pydeptree() {
    local dir arg importer imported nocython=false lib="$(basename $(pwd))"
    for arg in "$@"; do
        [ arg == '--no-cython' ] && nocython=true
    done
    
    echo 'digraph "'"$(basename $(pwd))"' dependency graph" {'
    for dir in $(ls); do
        if [ -d "$dir" ] && ( [ -f "$dir/__init__.py" ] || [ -f "$dir/setup.py" ] ); then
            importer="$lib.$dir"
            cd "$dir"
            pydeps "$@" --no-versions | while read imported; do
                echo '    "'"$importer"'" -> "'"$imported"'"'
            done
            cd ..
        elif ( $nocython && [ "${dir%.py}" != "$dir" ] ) || 
             ( ! $nocython && ( [ "${dir%.py}" != "$dir" ] || [ "${dir%.pyx}" != "$dir" ] || [ "${dir%.pxd}" != "$dir" ] ) ); then
            importer="$lib.${dir%.py}"
            pydeps "$@" --no-versions "$dir" | while read imported; do
                echo '    "'"$importer"'" -> "'"$imported"'"'
            done
        fi
    done
    echo '}'
}


pydeptreeviz() {
    local outfile="$1"
    if [ -z "$outfile" ] || [ "${outfile#-}" != "$outfile" ]; then
        outfile="$(mktemp).pdf"
    else
        shift
    fi
    
    local ext="${outfile#${outfile%.*}.}"
    local tmpfile="$(mktemp)"
    pydeptree "$@" | tee "$tmpfile"
    echo "writing dependency visualization to $outfile"
    dot -T$ext "$tmpfile" > "$outfile" && echo "wrote dependency visualization to $outfile" && open "$outfile"
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
    alias pspb="python setup.py build"
    alias pspt="python setup.py test"
    
    SANDBOX="$HOME/Desktop/sandbox"
    alias sandbox="cd $SANDBOX"

    case "$OSTYPE" in
        linux*) 
            PYCHARM_DIR="$(find /opt -maxdepth 1 -type d -name 'pycharm*' | sort -V | tail -n 1)"
            alias pycharm="$PYCHARM_DIR/bin/pycharm.sh"
            charm() {
                $PYCHARM_DIR/bin/pycharm.sh $@ &
            }
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


pushd_() {
    pushd "$1" > /dev/null
}

popd_() {
    popd > /dev/null
}

namespaceify() {
    local name dir_ pkg_dir tmp mods=() 
    local mv_setup_py='touch setup.py' mv_setup_cfg='' mv_setup_py_msg='' mv_setup_cfg_msg='' testdir=''
    local ns_init="__import__('pkg_resources').declare_namespace(__name__)"
    local SAFE=1
    
    while [ "$1" != "${1#-}" ]; do
        case "$1" in
            -x) local SAFE=0; shift
                ;;
            -t) local testdir="$2"; shift 2
                ;;
        esac
    done

    if [ -z "$1" ]; then 
        dir_="$(pwd)"
    else
        dir_="$1"
    fi
   
    name="$(basename $dir_)"

    pushd_ "$dir_"

    pushd_ ..
    if [ -f "setup.py" ]; then
        mv_setup_py="cp $(pwd)/setup.py ./"
        mv_setup_py_msg=" from $(pwd)/setup.py"
    fi
    if [ -f "setup.cfg" ]; then
        mv_setup_cfg="cp $(pwd)/setup.cfg ./"
        mv_setup_cfg_msg=" from $(pwd)/setup.cfg"
    fi
    popd_

    tmp="$(mktemp -d)"

    for subdir in $(ls); do
        [ ! -d "$subdir" ] || [ "$subdir" = "__pycache__" ] && continue
        if [ ! -f "$subdir/__init__.py" ]; then
            echo "$subdir appears not to be a python module (no __init__.py); skipping."
            continue
        fi
        
        echo creating subpackage "$subdir"
        
        safely mv "$subdir" "$tmp/" &&
            safely mkdir "$subdir" &&
            safely pushd_ "$subdir" &&
            safely mkdir "$name" && 
            safely pushd_ "$name" && 
            safely mv "$tmp/$subdir" ./ &&
            echo "creating default __init__.py" &&
            safely eval echo '"'"$ns_init"'"' ">__init__.py" &&
            safely popd_ && 
            echo "creating setup.py$mv_setup_py_msg" &&
            safely $mv_setup_py &&
            ( [ ! -z "$mv_setup_cfg" ] && echo "creating setup.cfg$mv_setup_cfg_msg" && safely $mv_setup_cfg || true ) &&
            echo "generating requirements.txt from parsed imports" &&
            safely eval pydeps -n "$name" "$name" ">requirements.txt" &&
            ( [ ! -z "$testdir" ] && echo "creating directory for test suite in $testdir/" && mkdir "$testdir" || true ) &&
            safely popd_
        
        if [ $? -ne 0 ]; then
            echo Error: failed to create subpackage "$subdir"
        else        
            mods=("${mods[@]}" "$subdir")
        fi
        echo
    done
    
    popd_

    rm -rf "$tmp"
    
    if [ ${#mods[@]} -gt 0 ]; then
        echo
        echo "Namespaced the following submodules in $name:"
        for m in ${mods[@]}; do echo $m; done; echo
        echo "You may need to check that setup.py and requirements.txt are correct in each submodule."
        [ ! -z "$testdir" ] && echo "You may also need to migrate your test suites to $testdir/ in each submodule."
        echo "The dummy requirements.txt files written therein contain module names as in found in import statements;"
        echo "These in general may not match distribution names as found in PyPI and installed by pip."
        if [ -f "$dir_/__init__.py" ]; then
            echo "__init__.py still exists in $dir_; if there is any setup logic there it will need to be transferred to the submodules"
        fi
        echo "Be sure to put 'namspace_packages=['$name'], zip_safe=False' in the setuptools.setup() call of each submodule's __init__.py"
    else
        echo
        echo "No modules were namespaced in $name!"
    fi
    echo
}
