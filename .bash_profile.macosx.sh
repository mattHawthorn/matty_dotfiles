# If not running interactively, don't do anything
[ -z "$PS1" ] && return

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

# completions
BASHCOMPLETIONDIR="/usr/local/etc/bash_completion.d"
if [ -d $BASHCOMPLETIONDIR ]; then
    for f in $(ls "$BASHCOMPLETIONDIR"); do source "$BASHCOMPLETIONDIR/$f"; done
else
    unset  BASHCOMPLETIONDIR
fi

# bash-git-prompt
[ -d ~/.bash-git-prompt ] && GIT_PROMPT_ONLY_IN_REPO=1 && source ~/.bash-git-prompt/gitprompt.sh

# work-specific aliases

# music player
alias music="/Applications/QuodLibet.app/Contents/MacOS/run ~/Git/quodlibet/quodlibet/quodlibet.py"

# start of day script:
alias gettowork="~/scripts/getToWork.sh"

# SNL logins
alias chodb='tsql -H CHODB05'
alias snldb='tsql -H SNLSQLDEV'
alias sshprod='ssh dmzchodswprd01.snlnet.int'
alias sshstg='ssh dmzchodswstg01.snlnet.int'
alias sshdev='ssh ashdswdev02.snl.int'

# vpn
alias spglobalvpn='/opt/cisco/anyconnect/bin/vpn connect us-remote.spglobal.com/vpn'


# basic aliases
alias ll='ls -lF'
alias la='ls -alF'

# custom scripts/utils
source "$HOME/scripts/bashutils.sh"
source "$HOME/scripts/clipboard.sh"
source "$HOME/scripts/safely.sh"
source "$HOME/scripts/mathutils.sh"
source "$HOME/scripts/papertitle.sh"
source "$HOME/scripts/fileutils.sh"
source "$HOME/scripts/pyutils.sh"
which brew > /dev/null && source "$HOME/scripts/homebrew_setup.sh"
which domino > /dev/null && source "$HOME/scripts/dominonew.sh"

export PATH="$HOME/anaconda3/bin/:$PATH"
set_python_dev_aliases
set_conda_env_aliases

alias datify="$HOME/scripts/datify.sh"
