# OS-agnostic clipboard

case "$OSTYPE" in
    linux*) alias clip="xclip -sel clip"
            alias unclip="xclip -sel clip -o" ;;
    darwin*) alias clip="pbcopy"
             alias unclip="pbpaste" ;;
esac

