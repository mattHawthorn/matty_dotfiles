# expose and configure homebrew-installed software

if ! which brew; then
  export PATH="/opt/homebrew/bin/:$PATH"
fi
BREW_PREFIX="$(brew --prefix)"

whereisit() {
    # like whereis, but this will find brew-intstalled executables.
    # tells you the location of the executable and the man pages, if they exist.
    # and whether it's symlinked to another location (as homebrew does)
    local loc pathinfo manpath
    loc=$(which "$1" 2> /dev/null)
    [[ $? != 0 ]] && return 1
    pathinfo="$(linkname $loc)"
    [[ $? != 0 ]] && return 1
    manpath="$(man -w $1 2> /dev/null)"
    [[ $? == 0 ]] && manpath="$(linkname $manpath)" || manpath=""
    echo "$1:"
    echo "$pathinfo"
    [[ ! -z "$manpath" ]] && echo "$manpath"
}

linkname() {
    # echo the path, followed by -> /path/it/links/to if the path is a symlink
    # (parsed from ls -l output)
    local loc="$1"
    local t=$(filetype "$loc")
    local fields
    fields=($(ls -l "$loc"))
    local numfields=${#fields[@]}
    case "$t" in
        [-d]) echo "${fields[-1]:0}" ;;
        l) echo "${fields[@]:$((numfields - 3))}" ;;
        *) return 1
    esac
    return 0
}

filetype() {
    local out=$(ls -l "$1")
    [[ -z "$out" ]] && return 1
    echo "${out:0:1}"
    return 0
}


# override mac-provided command line tools with newer GNU versions
GNU_PREFIX=$BREW_PREFIX/opt
GNUPATH=$GNU_PREFIX/coreutils/libexec/gnubin/
GNUMANPATH=$GNU_PREFIX/coreutils/libexec/gnuman/
MAKEPATH=$GNU_PREFIX/make/libexec/gnubin/
MAKEMANPATH=$GNU_PREFIX/make/libexec/gnuman/
FINDPATH=$GNU_PREFIX/findutils/libexec/gnubin/
FINDMANPATH=$GNU_PREFIX/findutils/libexec/gnuman/
GCCPATH=$GNU_PREFIX/gcc/bin/
GCCMANPATH=$GNU_PREFIX/gcc/share/man/
SEDPATH=$GNU_PREFIX/gnu-sed/libexec/gnubin/
SEDMANPATH=$GNU_PREFIX/gnu-sed/libexec/gnuman/

for _P in "$SEDPATH" "$GCCPATH" "$MAKEPATH" "$FINDPATH" "$GNUPATH"; do
    [ -e "$_P" ] && export PATH="$_P:$PATH"
done

for _P in "$SEDMANPATH" "$GCCMANPATH" "$MAKEMANPATH" "$FINDMANPATH" "$GNUMANPATH"; do
    [ -e "$_P" ] && export MANPATH="$_P:$MANPATH"
done

unset _P
