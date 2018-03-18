#!/bin/bash

#Script to construct new easy-install.pth in python site-packages directory.  Backs up original if present.

SCRIPTS="/scripts"
SITEPACKAGES="~/anaconda3/lib/python3.5/site-packages"
ORIGINAL="easy-install.pth"

E_BADARGS=85

if [ ! -n "$1" ]
then
  echo "Usage: `basename $0` [options]  [path to python site packages]"
  echo "options: -d : use default path $SITEPACKAGES"
  exit $E_BADARGS
fi

if [ "$1" != "-d" ]
then
  SITEPACKAGES="$1"
  cd $SITEPACKAGES
  pwd
fi


EXT="${ORIGINAL##*.}"
BASE="${ORIGINAL%.*}"

if [[ -e $ORIGINAL ]]
then
  VERSION=1
  BACKUP="$BASE.backup$VERSION.$EXT"
  while [[ -e $BACKUP ]]
    do VERSION=`expr $VERSION + 1`
    BACKUP="$BASE.backup$VERSION.$EXT"
    done
    
  echo "Backing up $ORIGINAL to $BACKUP"

cp $ORIGINAL $BACKUP
fi

echo "Making new $ORIGINAL in $SITEPACKAGES based on directory content"


echo "import sys; sys.__plen = len(sys.path)" > $ORIGINAL
find . -maxdepth 1 -name \*.egg >> $ORIGINAL
ls -1 *.egg-link | xargs -n1 head -1 >> $ORIGINAL
echo "import sys; new=sys.path[sys.__plen:]; del sys.path[sys.__plen:]; p=getattr(sys,'__egginsert',0); sys.path[p:p]=new; sys.__egginsert = p+len(new)​" >> $ORIGINAL

exit
