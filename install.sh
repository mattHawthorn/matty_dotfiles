LN_FLAGS="$@"

prompt_symlink() { 
    local a
    read -p "symlink $1? " a
    case "$a" in 
        y|Y) ln $LN_FLAGS -s "$1" && 
                echo $'\n'"    $1 successfully symlinked"$'\n' || 
                echo $'\n'"    Error symlinking $1!"$'\n' 
        ;; 
    esac;
}

DOTFILESDIR="$(realpath $(dirname $BASH_SOURCE))"
TMPFILE="$(mktemp)"
find $DOTFILESDIR -maxdepth 1 -name '.*' -not -name '.gitignore' -not -name '.git' -exec echo {} \; > $TMPFILE
echo "$DOTFILESDIR/scripts" >> $TMPFILE

pushd ~
for line in $(cat $TMPFILE | sort); do prompt_symlink "$line"; done;
rm $TMPFILE

[ -e .bash_profile ] && source .bash_profile
popd

echo
echo Finished!
echo

