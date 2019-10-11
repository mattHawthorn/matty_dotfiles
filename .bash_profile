# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# do this first to make GNU utils available in this script on Mac OS X
which brew > /dev/null && source "$HOME/scripts/homebrew_setup.sh"

# general bash helpers; some are needed to run this script
source "$HOME/scripts/bashutils.sh"


start bash_profile

start shell_config
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


start aliases

# basic aliases
alias ll='ls -lF'
alias la='ls -alF'

# development sandbox
if [ -d ~/Desktop/sandbox ]; then
    SANDBOX=~/Desktop/sandbox/
    alias sandbox='cd "$SANDBOX"'
fi

# google calendar CLI
if which gcalcli > /dev/null; then
    alias today='gcalcli agenda --nodeclined --no-military'
    alias thisweek='gcalcli calw --no-military'
    alias thismonth='gcalcli calm --no-military'
fi

finish -s aliases


finish -s shell_config


start source_custom_scripts

# custom scripts/utils
for module in clipboard datify todo mathutils papertitle fileutils gitutils; do
    source "$HOME/scripts/$module.sh"
done

alias shython='source $HOME/scripts/shython.sh'


start python_setup

source "$HOME/scripts/pyutils.sh"
export PATH="$HOME/anaconda3/bin/:$PATH"
set_python_dev_aliases
set_conda_env_aliases ~/.conda_env_aliases

finish -s python_setup


# docker
source "$HOME/scripts/dockerutils.sh"

# completions
# >> source "$HOME/scripts/bash_completion.sh"
# >> install_bash_completions
# Actually, this is the recommended way by the authors of bash_completion:
[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion

finish -s source_custom_scripts


# os-specific
case "$OSTYPE" in
    darwin*)
        export EMAIL_ADDRESS=matthew.hawthorn@snagajob.com
        TEX_BIN="/usr/local/texlive/2018basic/bin/x86_64-darwin"
        ;;
    linux*)
        export EMAIL_ADDRESS=hawthorn.matthew@gmail.com
        # music player
        alias music=rhythmbox
        if [ ! -t 0 ] && [ -n "$BASH" ] && [ -r ~/.bashrc ]; then
            start source_bashrc
            . ~/.bashrc
            finish -d source_bashrc
        fi
        ;;
esac


# custom keyboard setup, if available
which ckb-next >/dev/null && ( ps -C ckb-next >/dev/null || ckb-next & >/dev/null )


# added by Anaconda3 2018.12 installer
start conda_init

# <<< conda init <<<
# added by Anaconda3 2019.07 installer
# >>> conda init >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$(CONDA_REPORT_ERRORS=false "$HOME/anaconda3/bin/conda" shell.bash hook 2> /dev/null)"
if [ $? -eq 0 ]; then
    \eval "$__conda_setup"
else
    if [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
        . "$HOME/anaconda3/etc/profile.d/conda.sh"
        CONDA_CHANGEPS1=false conda activate base
    else
        \export PATH="$HOME/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda init <<<

finish -s conda_init

finish -s bash_profile
