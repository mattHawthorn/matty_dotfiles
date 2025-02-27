# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# do this first to make GNU utils available in this script on Mac OS X
if ! which brew > /dev/null; then
  export PATH="/opt/homebrew/bin/:$PATH"
fi
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
[ -d ~/.bash-git-prompt ] && export GIT_PROMPT_ONLY_IN_REPO=1 && source ~/.bash-git-prompt/gitprompt.sh

# extra path munging for specific machines, if needed
[ -f ~/.bash_add_path ] && source ~/.bash_add_path

# custom keyboard setup, if available
which ckb-next >/dev/null && ( ps -C ckb-next >/dev/null || ckb-next & >/dev/null )


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

case "$OSTYPE" in
    linux*)
        export EMAIL_ADDRESS=hawthorn.matthew@gmail.com
        export BROWSER=brave
        if [ ! -t 0 ] && [ -n "$BASH" ] && [ -r ~/.bashrc ]; then
            start source_bashrc
            . ~/.bashrc
            finish source_bashrc
        fi
        ;;
    darwin*)
        export EMAIL_ADDRESS=matt.hawthorn@trillianthealth.com
        # from homebrew_setup.sh
        set_gnu_aliases "      "
        ;;
esac

alias ghci="stack ghci"
alias ghc="stack ghc"

alias shrug='echo "¯\_(ツ)_/¯"'
alias fuckthis='echo "(╯°□°)╯︵ ┻━┻"'
alias fuckthisisfine='echo "(┛❍ᴥ❍)┛彡┻━┻"'

alias shython='source $HOME/scripts/shython.sh'
alias pr='poetry run'
alias ur='uv run'
complete -o bashdefault -F _root_command pr
complete -o bashdefault -F _root_command ur

finish aliases

finish shell_config


start dev_setup

[ -f ~/.sdkman/bin/sdkman-init.sh ] && source ~/.sdkman/bin/sdkman-init.sh

# put haskell stack builds on the path
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin/:$PATH"

# kubectl path
[ -d $HOME/kubectl_*/bin ] && export PATH=$(echo $HOME/kubectl_*/bin)":$PATH"

if which mise > /dev/null; then
    start mise_setup
    eval "$($HOME/.local/bin/mise activate bash)"
    finish mise_setup
fi

start python_setup

source "$HOME/scripts/pyutils.sh"

# pyenv setup
if which pyenv > /dev/null; then
    start pyenv_setup
    export PYENV_ROOT="$HOME/.pyenv"
    [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
    finish pyenv_setup
fi

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$("$HOME/anaconda3/bin/conda" 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    start conda_init
    eval "$__conda_setup"
    finish conda_init
else
    if [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
        start conda_init
        . "$HOME/anaconda3/etc/profile.d/conda.sh"
        finish conda_init
    else
        if [ -d "$HOME/anaconda3/bin" ]; then
            start conda_init
            export PATH="$HOME/anaconda3/bin:$PATH"
            finish conda_init
        fi
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# added by travis gem
[ -f /home/matt/.travis/travis.sh ] && source /home/matt/.travis/travis.sh

finish python_setup

finish dev_setup


start source_custom_scripts

# custom scripts/utils
for module in clipboard datify todo mathutils papertitle fileutils gitutils anyq dockerutils; do
    source "$HOME/scripts/$module.sh"
done

mono() {
  # monorepo CLI
  run_from_repo_root poetry run mono "$@"
}

start completions

source "$HOME/scripts/bash_completion.sh"

[ -z $BASH_COMPLETIONS_SET ] && install_bash_completions "      "

install_custom_bash_completions

# stack completions
which stack > /dev/null && eval "$(stack --bash-completion-script stack)"

finish completions

finish source_custom_scripts

finish bash_profile
