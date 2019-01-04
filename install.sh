if [ "$1" = '-h' ] || [ "$1" = "--help" ]; then
    echo
    echo "Usage: ./install.sh [-x|--no-prompt] [--dir TARGET_DIR] [FILE1 [FILE2 [...]]]"
    echo
    echo "Install custom dotfiles into your home directory or alternately a custom directory."
    echo "Most files are symlinked directly but for some, whose parent apps have deeply nested "
    echo "configuration directories, a subset of custom configuration is copied into those "
    echo "corresponding directories in the target recursively."
    echo "To specify only a subset of the dotfiles, pass the desired files as trailing positional args."
    exit 0
fi

if [ "$1" = '-x' ] || [ "$1" = "--no-prompt" ]; then
    CMD=symlink; RCMD=rsymlink; shift
    echo "Symlinking files without prompts"
else
    CMD=prompt_symlink; RCMD=prompt_rsymlink
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

fullpath() {
    cd "$1" >/dev/null; pwd; cd - >/dev/null
}

LN_FLAGS=()
while [ "${1#-}" != "$1" ]; do
    LN_FLAGS=("${LN_FLAGS[@]}" "$1"); shift
done
LN_FLAGS=("${LN_FLAGS[@]}" "-s")

echo "Passing flags ${LN_FLAGS[@]} to ln"

FILES=("$@")
RECURSE_DIRS=(".ipython" ".atom")
EXTRAS=("scripts")
IGNORE=(".gitignore" ".git" ".DS_Store" ".idea")

DOTFILESDIR="$(fullpath $(dirname $BASH_SOURCE))"
TMPFILE="$(mktemp)"


if [ ${#FILES[@]} -eq 0 ]; then
    echo "Finding relevant config files in $DOTFILESDIR"
    echo
    
    cmd="find $DOTFILESDIR -maxdepth 1 -name '.*'"
    # exclude dirs which will be copied
    
    for file in ${RECURSE_DIRS[@]} ${IGNORE[@]}; do
        cmd="$cmd -not -name '$file'"
    done
    eval "$cmd -exec echo {} \\;" > $TMPFILE
    
    for file in ${EXTRAS[@]}; do
        echo "$DOTFILESDIR/$file" >> $TMPFILE
    done
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
    read -p "symlink $(basename $1)? " a
    case "$a" in 
        y|Y) symlink "$1" 
        ;; 
    esac;
}

symlink() {
    ln ${LN_FLAGS[@]} "$1" -t "$DIR" &&
                echo $'\n'"    Success symlinking $1 in $DIR"$'\n' ||
                echo $'\n'"    Error symlinking $1 in $DIR!"$'\n'
}

rsymlink() {
    local line path
    find "$1" -type d | while read line; do
        path=${line#$DOTFILESDIR}
        ! [ -d "$DIR/$path" ] && mkdir "$DIR/$path"        
    done
    find "$1" -type f | while read line; do
        path=${line#$DOTFILESDIR}
        if [ -f "$DIR/$path" ]; then
            echo "$DIR/$path already exists! refusing to overwrite"
        else
            ln ${LN_FLAGS[@]} "$DOTFILESDIR/$path" "$DIR/$path" 
        fi    
    done
}

prompt_rsymlink() { 
    local a
    read -p "recursively symlink $1 contents into $DIR/$1? " a
    case "$a" in 
        y|Y) rsymlink "$1" 
        ;; 
    esac;
}

for line in $(cat $TMPFILE | sort); do "$CMD" "$line"; done;
rm $TMPFILE

for line in ${RECURSE_DIRS[@]}; do "$RCMD" "$line"; done;

[ -e .bash_profile ] && echo $'\n'"Run 'source ~/.bash_profile' to take advantage of your new shell configuration"$'\n'
echo Finished!
echo
