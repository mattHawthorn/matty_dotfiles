#!/usr/bin/env bash
[ ! "$BASHUTILS_IMPORTED" == 1 ] && source "$(dirname "$BASH_SOURCE")/bashutils.sh"

# create a new Domino project
DOMINOUSER="matthawthorn"
DOMINOPATH="$HOME/Domino"
DOMINOTEMPLATEPATH="$DOMINOPATH/ProjectTemplate"

alias mydomino='cd $DOMINOPATH/$DOMINOUSER'

if [ -d "$DOMINOPATH" ]; then
    for group in $(ls "$DOMINOPATH"); do
        [ -d "$DOMINOPATH/$group" ] && eval "alias $group='cd \$DOMINOPATH/$group'"
    done
fi
unset group


_dominonewusage(){
    echo
    echo "Create a new domino project and initialize it with a template"
    echo 
    echo "Usage: dominonew [-x] USER/REPO_NAME [TEMPLATE_DIR] "
    echo "  if not passed explicitly, USER and TEMPLATE_DIR can be specified"
    echo "  with the environment variables DOMINOUSER and DOMINOTEMPLATEPATH"
    echo "  respectively. TEMPLATE_DIR is only optional if the latter is set;"
    echo "  otherwise the call to dominonew will fail with an error message."
    echo
    echo "  A leading -x flag tells dominonew to actually execute any filesystem-"
    echo "  altering commands; otherwise they are simply printed for review"
    echo
    echo "  NOTE: you must also set the DOMINOPATH variable to the root dir of "
    echo "  your domino projects before using dominonew."
}


dominonew(){
  SAFE=1
  if [[ -z "$DOMINOPATH" ]]; then
    echo "Your DOMINOPATH environment variable is not set! Do so first and create the directory"
    echo
    _dominonewusage
    return 2
  fi
  
  local user name template
  
  case "$1" in
    "") _dominonewusage; return 1 ;;
    -h|--help) _dominonewusage; return 1 ;;
    -x) SAFE="$UNSAFECODE"; shift ;;
  esac
  
  if [[ -z "$2" && -z "$DOMINOTEMPLATEPATH" ]]; then
    echo "No template path was specified; either pass a template dir via 'dominonew \$user/\$name $templatedir' or set the environment variable DOMINOTEMPLATEPATH"
    return 1
  elif [[ ! -z "$2" ]]; then
    if [[ ! -d "$DOMINOPATH/$2" ]]; then
        echo "$2 is not an existing directory and therefore cannot serve as a template!"
        return 1
    fi
    template="$DOMINOPATH/$2"
  else
    template=$DOMINOTEMPLATEPATH
    if [[ ! -d "$template" ]]; then
        echo "your DOMINOTEMPLATEPATH=$template variable is not an existing directory and therefore cannot serve as a template!"
        return 2
    fi
  fi
  
  user="$(dirname $1)"
  name="$(basename $1)"
  
  if [[ "$user" == "." || "$user" == "" ]]; then
    if [[ -z "$DOMINOUSER" ]]; then
      echo "no user was specified; either pass one via 'dominonew \$user/\$name' or set the environment variable DOMINOUSER"
      return 1
    fi
  fi
  if [[ -z "$user" ]]; then
      echo "no user was specified; using $DOMINOUSER by default"
      user=$DOMINOUSER
  fi
  
  local newdir="$DOMINOPATH/$user/$name"
  if [[ -e "$newdir" ]]; then
    echo "$newdir already exists! aborting"
    return 1
  fi
  
  echo
  echo "NEW DOMINO REPOSITORY AT $newdir FOR USER $user WITH TEMPLATE $template"
  echo
  
  echo "copying contents of $template to $newdir"
  if ! safely cp -r "$template" "$newdir"; then
    echo "$(dirname $newdir) does not exist; please create it first"
    return 1
  fi
  
  echo "removing $newdir/.domino"
  safely rm -rf "$newdir/.domino"
  
  echo "initializing repo"
  local olddir="$(pwd)"
  cd "$newdir"
  echo "initializing domino repo in $newdir with owner $user"
  safely domino init -owner "$user"

  echo "new domino repo created successfully at $newdir with owner $user"
  cd "$olddir"
}

_dominonew(){
  if [[ $COMP_CWORD -gt 2 ]]; then
    COMPREPLY=()
    return
  fi
  local d lastword="${COMP_WORDS[$COMP_CWORD]}"
  if [[ -d "$DOMINOPATH/$lastword" ]]; then
    COMPREPLY=(
        $(for d in $(ls -d "$DOMINOPATH/$lastword"/*/); do
            echo $(basename "$d");
          done )
    )
  else
    COMPREPLY=(
      $( for d in $(ls -d "$DOMINOPATH"/*/); do
           [[ $(basename "$d") = $lastword* ]] && echo $(basename "$d");
         done )
    )
  fi
}

complete -o filenames -o nospace -F _dominonew dominonew
