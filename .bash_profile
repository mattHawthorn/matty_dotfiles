# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# do this first to make GNU utils available in this script on Mac OS X
which brew > /dev/null && source "$HOME/scripts/homebrew_setup.sh"


start bash_profile

# interactive shell config

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
# shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# prompt format
if [[ -z "$SSH_CLIENT" ]]; then
    PS1='\u:\w\$ '
else
    PS1='\u@\h:\w\$'
fi


# bash-git-prompt
[ -d ~/.bash-git-prompt ] && GIT_PROMPT_ONLY_IN_REPO=1 && source ~/.bash-git-prompt/gitprompt.sh


# extra path munging for specific machines, if needed
[ -f ~/.bash_add_path ] && source ~/.bash_add_path

# work-specific aliases

# music player
alias music="/Applications/QuodLibet.app/Contents/MacOS/run ~/Git/quodlibet/quodlibet/quodlibet.py &"

# start of day script:
alias gettowork="~/scripts/getToWork.sh"

# SNL logins
alias chodb='tsql -H CHODB05'
alias snldb='tsql -H SNLSQLDEV'
alias sshprod='ssh dmzchodswprd01.snlnet.int'
alias sshstg='ssh dmzchodswstg01.snlnet.int'
alias sshdev='ssh ashdswdev02.snl.int'
alias sshchodsdev="ssh $USER@CHODSDEV01"

# vpn
alias spglobalvpn='/opt/cisco/anyconnect/bin/vpn connect us-remote.spglobal.com/vpn'


# basic aliases
alias ll='ls -lF'
alias la='ls -alF'


start source_custom_scripts

# custom scripts/utils
for module in clipboard datify todo mathutils papertitle fileutils gitutils bashutils; do
    source "$HOME/scripts/$module.sh"
done

TEX_BIN="/usr/local/texlive/2018basic/bin/x86_64-darwin"
[ -d "$TEX_BIN" ] && export PATH="$TEX_BIN:$PATH"

alias shython='source $HOME/scripts/shython.sh'

start python_setup
source "$HOME/scripts/pyutils.sh"
export PATH="$HOME/anaconda3/bin/:$PATH"
set_python_dev_aliases
set_conda_env_aliases ~/.conda_env_aliases
# domino project start helper
which domino > /dev/null && source "$HOME/scripts/dominonew.sh"
finish -s python_setup

# docker
source "$HOME/scripts/dockerutils.sh"

# completions
# >> source "$HOME/scripts/bash_completion.sh"
# >> install_bash_completions
# Actually, this is the recommended way by the authors of bash_completion:
[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion

# python completions via argcomplete
export PYTHON_ARGCOMPLETE_OK=true

finish -s source_custom_scripts

# development sandbox
if [ -d ~/Desktop/sandbox ]; then
    SANDBOX=~/Desktop/sandbox/
    alias sandbox='cd "$SANDBOX"'
fi

case "$OSTYPE" in
    darwin*) export EMAIL_ADDRESS=matthew.hawthorn@spglobal.com ;;
    linux*) export EMAIL_ADDRESS=hawthorn.matthew@gmail.com ;;
esac

# .profile
case "$OSTYPE" in
    linux*)
        if [ ! -t 0 ] && [ -n "$BASH" ] && [ -r ~/.bashrc ]; then
            start source_bashrc
            . ~/.bashrc
            finish -d source_bashrc
        fi
        ;;
esac

finish -s bash_profile

# added by Anaconda3 2018.12 installer
# >>> conda init >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$(CONDA_REPORT_ERRORS=false "$HOME/anaconda3/bin/conda" shell.bash hook 2> /dev/null)"
if [ $? -eq 0 ]; then
    \eval "$__conda_setup"
else
    if [ -f ~/anaconda3/etc/profile.d/conda.sh ]; then
        . "$HOME/anaconda3/etc/profile.d/conda.sh"
        CONDA_CHANGEPS1=false conda activate base
    else
        \export PATH="$HOME/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda init <<<
