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

start pyenv_init

# pyenv
if [ -d "$HOME/.pyenv/bin" ]; then
  export PATH="$HOME/.pyenv/bin:$PATH"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

finish pyenv_init

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
[ -d ~/.bash-git-prompt ] && export GIT_PROMPT_ONLY_IN_REPO=1 && source ~/.bash-git-prompt/gitprompt.sh

# extra path munging for specific machines, if needed
[ -f ~/.bash_add_path ] && source ~/.bash_add_path


start aliases

# basic aliases
alias ll='ls -lF'
alias la='ls -alF'

alias whattime='date +%T'

# development sandbox
for _dir in  ~/sandbox ~/Desktop/sandbox; do
    if [ -d "$_dir" ]; then
        export SANDBOX="$_dir"
        alias sandbox='cd "$SANDBOX"'
        break
    fi
done
unset _dir

# browser
case "$OSTYPE" in
    linux*)
        export BROWSER=firefox ;;
    darwin*)
        export BROWSER='open -a firefox -g' ;;
esac

alias shrug='echo "¯\_(ツ)_/¯"'
alias fuckthis='echo "(╯°□°)╯︵ ┻━┻"'
alias fuckthisisfine='echo "(┛❍ᴥ❍)┛彡┻━┻"'

alias shython='source $HOME/scripts/shython.sh'
alias pr='poetry run'

finish aliases


finish shell_config


start source_custom_scripts

# custom scripts/utils
for module in clipboard datify todo mathutils papertitle fileutils gitutils anyq; do
    source "$HOME/scripts/$module.sh"
done

mono() {
  # monorepo CLI
  run_from_repo_root poetry run mono "$@"
}

[ -f ~/.sdkman/bin/sdkman-init.sh ] && source ~/.sdkman/bin/sdkman-init.sh

start python_setup

source "$HOME/scripts/pyutils.sh"
# tell pipenv to always create envs inside the project where the env is defined
export PIPENV_VENV_IN_PROJECT=1

start pyenv_setup
# pyenv setup
if which pyenv > /dev/null; then
    export PYENV_ROOT="$HOME/.pyenv"
    [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi
finish pyenv_setup

finish python_setup


# docker
source "$HOME/scripts/dockerutils.sh"

start completions

# completions
source "$HOME/scripts/bash_completion.sh"

# stack completions
which stack > /dev/null && eval "$(stack --bash-completion-script stack)"

install_custom_bash_completions() {
    if [ -d ~/.bash_completion.d/ ]; then
        for completion_script in ~/.bash_completion.d/*; do
            [[ -r "$completion_script" ]] && . "$completion_script"
        done
    fi
}

install_custom_bash_completions

finish completions

finish source_custom_scripts


# os-specific
case "$OSTYPE" in
    darwin*)
        export EMAIL_ADDRESS=matt.hawthorn@trillianthealth.com
        ;;
    linux*)
        export EMAIL_ADDRESS=hawthorn.matthew@gmail.com
        # music player
        alias music=rhythmbox
        if [ ! -t 0 ] && [ -n "$BASH" ] && [ -r ~/.bashrc ]; then
            start source_bashrc
            . ~/.bashrc
            finish source_bashrc
        fi
        ;;
esac


# custom keyboard setup, if available
which ckb-next >/dev/null && ( ps -C ckb-next >/dev/null || ckb-next & >/dev/null )


start conda_init

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$("$HOME/anaconda3/bin/conda" 'shell.bash' 'hook' 2> /dev/null)"
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

finish conda_init

# added by travis gem
[ -f /home/matt/.travis/travis.sh ] && source /home/matt/.travis/travis.sh

start mise_setup
eval "$($HOME/.local/bin/mise activate bash)"
finish mise_setup

finish bash_profile
