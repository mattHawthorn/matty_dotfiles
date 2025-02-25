# OS-agnostic bash completions

install_bash_completions() {
    case "$OSTYPE" in
        linux*)
            [[ -r /usr/local/etc/bash_completion ]] && . /usr/local/etc/bash_completion
            BASHCOMPLETIONDIR="/etc/bash_completion.d"
            [[ -d "/etc/bash_completion.d" ]] && . /etc/bash_completion.d/*
    	      ;;
        darwin*)
            if which brew; then
                BREW_PREFIX="$(brew --prefix)"
                [[ -r "$BREW_PREFIX/etc/bash_completion" ]] && . "$BREW_PREFIX/etc/bash_completion"
                [[ -r "$BREW_PREFIX/etc/profile.d/bash_completion.sh" ]] && . "$BREW_PREFIX/etc/profile.d/bash_completion.sh"
                if [[ -d "$BREW_PREFIX/etc/bash_completion.d/" ]]; then
                    for _suffix in bash-builtins sh tar rsync gzip gpg gpg2 python openssl sqlite3; do
                        if [[ -r "$BREW_PREFIX/etc/bash_completion.d/$_suffix" ]]; then
                            echo "        ... $_suffix completions"
                            . "$BREW_PREFIX/etc/bash_completion.d/$_suffix"
                        fi
                    done
                fi
            fi
            ;;
    esac
    export BASH_COMPLETIONS_SET=1
}

[ -z $BASH_COMPLETIONS_SET ] && install_bash_completions
