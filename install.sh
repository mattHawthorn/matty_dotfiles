prompt_symlink() { 
    local a
    printf "symlink $1?"
    read a
    case "$a" in 
        y|Y) ln -s "$1" && echo "$1 symlinked";; 
    esac;
}

DOTFILESDIR="$(pwd)"
cd ~

TMPFILE="$(mktemp)"
find $DOTFILESDIR -maxdepth 1 -name '.*' -not -name '.gitignore' -not -name '.git' -exec echo {} \; > $TMPFILE
echo scripts >> $TMPFILE

for line in $(cat $TMPFILE); do prompt_symlink "$line"; done;
rm $TMPFILE

[ -f .bash_profile ] && source .bash_profile
cd "$DOTFILESDIR"
echo finished
