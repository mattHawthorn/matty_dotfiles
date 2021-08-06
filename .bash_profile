# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# do this first to make GNU utils available in this script on Mac OS X
which brew > /dev/null && source "$HOME/scripts/homebrew_setup.sh"

# put haskell stack builds on the path
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin/:$PATH"

# python path - might be needed for `which` calls to python command line utils later in this script
[ -d "$HOME/anaconda3/bin/" ] && export PATH="$HOME/anaconda3/bin/:$PATH"

# kubectl path
[ -d $HOME/kubectl_*/bin ] && export PATH=$(echo $HOME/kubectl_*/bin)":$PATH"

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

alias whattime='date +%T'

# development sandbox
if [ -d ~/Desktop/sandbox ]; then
    SANDBOX=~/Desktop/sandbox/
    alias sandbox='cd "$SANDBOX"'
fi

# google calendar CLI
if which gcalcli > /dev/null; then
    alias today='gcalcli agenda --nodeclined --no-military --details url --details length --details email "$(date +"%a %H:00:00")" "$(date +"%a 11:59:59 PM")"'
    alias thisweek='gcalcli calw --no-military'
    alias thismonth='gcalcli calm --no-military'
fi

# browser
case "$OSTYPE" in
    linux*)
        export BROWSER=firefox ;;
    darwin*)
        export BROWSER='open -a firefox -g' ;;
esac

# goto meetings
hopinto() {
    local meetinglink
    if [ $# -eq 0 ]; then
        echo "searching for upcoming meetings"
        meetinglink=$(today | grep 'Hangout Link:' | head -1 | while read line; do echo ${line#*Hangout Link:}; done)
    else
        echo "searching for upcoming $1 meetings"
        meetinglink=$(today | grep -i -A 4 $1 | grep 'Hangout Link:' | head -1 | while read line; do echo ${line#*Hangout Link:}; done)
    fi
    if [ -z "$meetinglink" ]; then
        echo "No meeting link found! run 'today' to see upcoming events"
        return 1
    else
        echo "Entering $1 meeting at ${meetinglink}"
        $BROWSER "$meetinglink"
    fi
}
alias meeting='hopinto'
alias grooming='hopinto grooming'
alias scrum='hopinto scrum'
alias standup='hopinto scrum'

alias shrug='echo "¯\_(ツ)_/¯"'
alias fuckthis='echo "(╯°□°)╯︵ ┻━┻"'
alias fuckthisisfine='echo "(┛❍ᴥ❍﻿)┛彡┻━┻"'

alias shython='source $HOME/scripts/shython.sh'

finish -s aliases


finish -s shell_config


start source_custom_scripts

# custom scripts/utils
for module in clipboard datify todo mathutils papertitle fileutils gitutils; do
    source "$HOME/scripts/$module.sh"
done

[ -f ~/.sdkman/bin/sdkman-init.sh ] && source ~/.sdkman/bin/sdkman-init.sh

start python_setup

source "$HOME/scripts/pyutils.sh"
set_python_dev_aliases
set_conda_env_aliases ~/.conda_env_aliases
# s3 cache util writes here
export S3_CACHE_DIR=~/.s3_cache
export SAGEMAKER_PROJECT_DIR=~/git/snag/

finish -s python_setup


# docker
source "$HOME/scripts/dockerutils.sh"

# completions
# >> source "$HOME/scripts/bash_completion.sh"
# >> install_bash_completions
# Actually, this is the recommended way by the authors of bash_completion:
[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion

# stack completions
which stack && eval "$(stack --bash-completion-script stack)"

install_bash_completions() {
    if [ -d ~/.bash_completion.d/ ]; then
        for completion_script in $(ls ~/.bash_completion.d/); do
            source ~/.bash_completion.d/$completion_script
        done
    fi
}

install_bash_completions

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


start conda_init

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('$HOME/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
        . "$HOME/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="$HOME/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

finish -s conda_init

# added by travis gem
[ -f /home/matt/.travis/travis.sh ] && source /home/matt/.travis/travis.sh

finish -s bash_profile
