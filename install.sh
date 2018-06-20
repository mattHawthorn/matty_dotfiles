if [ "$1" = '-x' ] || [ "$1" = "--no-prompt" ]; then
    CMD=symlink; shift
    echo "Symlinking files without prompts"
else
    CMD=prompt_symlink
fi

if [ "$1" = "--dir" ]; then
    DIR="$2"; shift 2
    if [ ! -d "$DIR" ]; then
        echo "$DIR is not a directory!"
        exit 1
    fi
else
    DIR=~
fi

echo "Installing symlinks in $DIR"

LN_FLAGS=()
while [ "${1#-}" != "$1" ]; do
    LN_FLAGS=("${LN_FLAGS[@]}" "$1"); shift
done
LN_FLAGS=("${LN_FLAGS[@]}" "-s")

echo "Passing flags ${LN_FLAGS[@]} to ln"

FILES=("$@")

DOTFILESDIR="$(realpath $(dirname $BASH_SOURCE))"
TMPFILE="$(mktemp)"

if [ ${#FILES[@]} -eq 0 ]; then
    echo "Finding relevant config files in $DOTFILESDIR"
    find $DOTFILESDIR -maxdepth 1 -name '.*' -not -name '.gitignore' -not -name '.git' -exec echo {} \; > $TMPFILE
    echo "$DOTFILESDIR/scripts" >> $TMPFILE
else
    for FILE in "${FILES[@]}"; do
        echo "$DOTFILESDIR/$FILE" >> $TMPFILE
    done
fi

NFILES=$(wc -l $TMPFILE | cut -f 1 -d ' ')
if [ $NFILES -eq 0 ]; then
    echo "No files to symlink!"
    exit 1
fi

prompt_symlink() { 
    local a
    read -p "symlink $1? " a
    case "$a" in 
        y|Y) symlink "$1" 
        ;; 
    esac;
}

symlink() {
    ln ${LN_FLAGS[@]} "$1" "$DIR" &&
                echo $'\n'"    Success symlinking $1 in $DIR"$'\n' ||
                echo $'\n'"    Error symlinking $1 in $DIR!"$'\n'
}

for line in $(cat $TMPFILE | sort); do "$CMD" "$line"; done;
rm $TMPFILE

[ -e .bash_profile ] && echo $'\n'"Run 'source ~/.bash_profile' to take advantage of your new shell configuration"$'\n'
echo Finished!
echo
