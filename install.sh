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

DOTFILESDIR="$(pwd)"
cd ~

TMPFILE="$(mktemp)"
find $DOTFILESDIR -maxdepth 1 -name '.*' -not -name '.gitignore' -not -name '.git' -exec echo {} \; > $TMPFILE
echo "$DOTFILESDIR/scripts" >> $TMPFILE

for line in $(cat $TMPFILE | sort); do prompt_symlink "$line"; done;
rm $TMPFILE

[ -f .bash_profile ] && source .bash_profile
cd "$DOTFILESDIR"
echo finished
