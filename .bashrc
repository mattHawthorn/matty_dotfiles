# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=10000
HISTFILESIZE=20000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy 
# aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias lld='ll -d'
alias la='ls -A'
alias l='ls -CF'

# git command aliases
alias gitco="git checkout"
alias gitcm="git commit"
alias gitci="git check-ignore"
alias gitst="git status"
alias gitfh="git fetch"


# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'


# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# math

tobase() { 
  local num="$1" base="$2" res="" sign=""
  [[ $num -lt 0 ]] && sign='-' && ((num *= -1))
  while [[ $num -gt 0 ]]; do
    res=$(( num % base ))$res
    ((num /= base))
  done
  echo "$sign$res"
}

binary() {
  tobase $1 2
}

# file inspection/mgmt utils

mkrdir() {
  # recursive mkdir
  local curdir=$(pwd)
  local dirs=$(echo $1 | cut -d "/" --output-delimiter=" " -f 1-)
  for d in ${dirs[@]}; do
    if [ ! -d $d ]; then
      mkdir $d
    fi
    cd $d
  done
  cd $curdir
}

robustcopy() {
    local from=$1 to=$2
    local flag=""
    if [ -d $from ]; then
        flag="${flag} -r"
        if [ -d $to ]; then
            flag="${flag} -T"
        fi
    fi
    cp $flag $from $to
}

ghost() {
    # make a file a 'ghost' - a symlink by the original name pointing to a 
    # copy moved to a specified location (likely a local code repo -
    # useful for version-controlling system files)
    local target=$1 dest=$2 copy=$3
    if [[ ! -z $copy && ! $copy = "-c" ]]; then
        echo "invalid flag: ${copy}; only -c is allowed, indicating to copy symlink references"
        return
    fi
    if [ -z $dest ]; then echo "no destination specified; aborting"; return; fi
    # expand glob if any
    targets=($target)
    if (( ${#targets[@]} > 1 )) && [ ! -d $dest ]; then
        echo "multiple targets specified but the destination is not a directory; aborting"
        return
    fi
    for target in ${targets[@]}; do
        if [ ! -e $target ]; then echo "${target} does not exist; aborting"; return; fi
        
        if [ -L $target ]; then
            local msg="${target} is already a symlink; "

            if [ $copy = "-c" ]; then
                echo "${msg}""copying referent to ${dest} and re-routing link"
                local referent=$(readlink $target)
                robustcopy $referent $dest
                rm $target
            else
                echo "${msg}""copying link to ${dest}"
                mv $target $dest
            fi
        else
            mv $target $dest
        fi

        if [ -d $dest ]; then
            newloc="${dest}/$(basename $target)"
        else
            newloc=$dest
        fi
        
        newloc="$(readlink -f $newloc)"
        ln -s -T $newloc $target
    done
}

backup() {
    # make a backup copy of the first arg in the dir specified by the second.
    # if no second arg is passed, make the backup in the current dir
    local f=$1 dest=$2
    if [ -z "$f" ]; then echo "no file specified; aborting"; return; fi
    if [[ ! -z $dest && ! -d $dest ]]; then
        echo "specified directory ${dest} does not exist";
        return;
    fi
    if [ -z $dest ]; then dest="."; fi
    # expand glob if any
    local files=($f)
    for f in ${files[@]}; do
        if [ ! ${f%%.backup} = $f ]; then
           echo "${f} appears to already be a backup file; skipping"
           continue
        fi
        local backupname="$(basename $f).backup"
        local backuploc="${dest}/${backupname}"
        robustcopy $f $backuploc
    done
}

largest() {
    du -hsx * | sort -rh | head -$1
}

rlargest() {
    local a=($(find . ${*:2} -printf '%s %p\n'| sort -nr | head -$1))
    for i in $(seq 0 $((${#a[@]} / 2 - 1))); do
        local size=${a[$((2 * i))]} name=${a[$((2 * i + 1))]}
        echo "$(numfmt --to=si ${size}) ${name}"
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


# Data science things

# BleiLab Dynamic Topic Model
alias DTM='/home/matt/Git/dtm/dtm/main'

# aliases to manage the python chaos
# but for some reason none of these work; see below
#alias pip2='usr/bin/pip2'
#alias pip3='usr/bin/pip'
alias pyconda2='/home/matt/anaconda3/envs/anaconda2/bin/python2.7'
alias pyconda3='/home/matt/anaconda3/bin/python3.5'
alias pyconda='/home/matt/anaconda3/bin/python3.5'
alias conda2='/home/matt/anaconda3/envs/anaconda2/bin/conda'
alias conda3='/home/matt/anaconda3/bin/conda'
alias condapip2='/home/matt/anaconda3/envs/anaconda2/bin/pip'
alias condapip3='/home/matt/anaconda3/bin/pip'
alias condapip='/home/matt/anaconda3/bin/pip'


SANDBOX="/home/matt/Desktop/sandbox"

# alias for a new quick-and-dirty new ipython notebook
# This assumes that anaconda3 is the default anaconda installation,
# with anaconda2 as an environment, using that alias
scratchpad() {
    # start a notebook 
    # usage: scratchpad [ENV] [-w | -d WORKING_DIR]
    # default working directory is $SANDBOX
    local ENV DIR msg begincmd endcmd
    case "$1" in
        -h|--help)
            echo 'usage: scratchpad [ENV] [-w | -d WORKING_DIR]'
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

# ipython2 and ipython3 are created as we would hope on install, but
# make symlinks to jupyter as jupyter2 and jupyter3 in appropriate directories
# do the same for conda, as above aliases are being overriden

# added by Anaconda3 3 installer
export PATH="$PATH:/home/matt/anaconda3/bin"
# added by Anaconda3 2.3.0 installer
# export PATH="$PATH:/home/matt/anaconda2/bin"

# pycharm
alias charm="/opt/pycharm-community-2016.3.2/bin/pycharm.sh"

# for haskell
#export PATH="$PATH:/home/matt/.local/bin"
#alias ghci="stack ghci"
#alias ghc="stack ghc"

#export PATH="$PATH:/opt/Adobe/Reader9/bin"

# texlive install
export PATH="$PATH:/usr/local/texlive/2017/bin/x86_64-linux"
export PATH="$PATH:/usr/local/texlive/2015/bin/x86_64-linux"
export MANPATH="$MANPATH:/usr/local/texlive/2017/texmf-dist/doc/man"
export INFOPATH="$INFOPATH:/usr/local/texlive/2017/texmf-dist/doc/info"

# spark location
SPARK_HOME="/opt/spark-1.6.1-bin-hadoop2.6/"

# gitprompt setup
GIT_PROMPT_ONLY_IN_REPO=1
source ~/.bash-git-prompt/gitprompt.sh

