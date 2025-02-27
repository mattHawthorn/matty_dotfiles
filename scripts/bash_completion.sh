# OS-agnostic bash completions

install_bash_completions() {
    local prefix="$1" suffix
    case "$OSTYPE" in
        linux*)
            [[ -r /usr/local/etc/bash_completion ]] && . /usr/local/etc/bash_completion
            BASHCOMPLETIONDIR="/etc/bash_completion.d"
            [[ -d "/etc/bash_completion.d" ]] && . /etc/bash_completion.d/*
    	      ;;
        darwin*)
            if which brew > /dev/null; then
                BREW_PREFIX="$(brew --prefix)"
                [[ -r "$BREW_PREFIX/etc/bash_completion" ]] && . "$BREW_PREFIX/etc/bash_completion"
                [[ -r "$BREW_PREFIX/etc/profile.d/bash_completion.sh" ]] && . "$BREW_PREFIX/etc/profile.d/bash_completion.sh"
                if [[ -d "$BREW_PREFIX/etc/bash_completion.d/" ]]; then
                    for suffix in bash-builtins sh git git-completion.bash tar rsync gzip gpg gpg2 python openssl sqlite3; do
                        if [[ -r "$BREW_PREFIX/etc/bash_completion.d/$suffix" ]]; then
                            echo "$prefix$suffix completions"
                            . "$BREW_PREFIX/etc/bash_completion.d/$suffix"
                        fi
                    done
                fi
            fi
            ;;
    esac
    export BASH_COMPLETIONS_SET=1
}

install_custom_bash_completions() {
    if [ -d ~/.bash_completion.d/ ]; then
        for completion_script in ~/.bash_completion.d/*; do
            [[ -r "$completion_script" ]] && . "$completion_script"
        done
    fi
}
