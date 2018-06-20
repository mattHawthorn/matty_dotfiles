if [ "$1" = '-A' ]; then
    CMD=symlink; shift
else
    CMD=prompt_symlink
fi

LN_FLAGS="$@"

prompt_symlink() { 
    local a
    read -p "symlink $1? " a
    case "$a" in 
        y|Y) symlink "$1" 
        ;; 
    esac;
}

symlink() {
    ln $LN_FLAGS -s "$1" &&
                echo $'\n'"    $1 successfully symlinked"$'\n' ||
                echo $'\n'"    Error symlinking $1!"$'\n'
}

DOTFILESDIR="$(realpath $(dirname $BASH_SOURCE))"
TMPFILE="$(mktemp)"
find $DOTFILESDIR -maxdepth 1 -name '.*' -not -name '.gitignore' -not -name '.git' -exec echo {} \; > $TMPFILE
echo "$DOTFILESDIR/scripts" >> $TMPFILE

pushd ~ >/dev/null
for line in $(cat $TMPFILE | sort); do prompt_symlink "$line"; done;
rm $TMPFILE

[ -e .bash_profile ] && echo $'\n'"Run 'source ~/.bash_profile' to take advantage of your new shell configuration"$'\n'
popd >/dev/null
echo Finished!
echo
