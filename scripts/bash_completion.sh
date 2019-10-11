# OS-agnostic bash completions

install_bash_completions() {
    case "$OSTYPE" in
        linux*) 
            BASHCOMPLETIONDIR="/etc/bash_completion.d"
            if [ -d $BASHCOMPLETIONDIR ]; then
    		        . $BASHCOMPLETIONDIR/*
            else
                unset  BASHCOMPLETIONDIR
            fi
    	      ;;
        darwin*) 
            BASHCOMPLETIONDIR="/usr/local/etc/bash_completion.d"
            bashcompletion="$(dirname $BASHCOMPLETIONDIR)/bash_completion"
            if [ -d "$BASHCOMPLETIONDIR" ] && [ -f "$bashcompletion" ]; then
    	          . "$bashcompletion"
    	      else
    	          unset  BASHCOMPLETIONDIR bashcompletion
    	      fi
            ;;
    esac
    export BASH_COMPLETIONS_SET=1
}

[ -z $BASH_COMPLETIONS_SET ] && install_bash_completions
