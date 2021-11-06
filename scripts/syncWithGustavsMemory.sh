#!/bin/bash
DESTINATIONHOME="/media/matt/Gustav's_memory/home/matt"
SOURCEHOME="/home/matt"

FONTS="/Fonts"
MUSIC="/Music"
DATA="/Datasets"
PICTURES="/Pictures"
PROJECTS="/Projects"
DOCUMENTS="/Documents"
GIT="/git"
CERTS="/certs"
SCRIPTS="/scripts"

# -r: recursive
# -v: verbose
# -h: human-readable
# -o: preserve owner
# -t: preserve modification time
#      good for files which are edited often or where history is of interest
#      (documents, photos, etc.)
# -p: preserve permissions
# --ignore-existing: skip files that already exist on destination
#     use for folders with unedited contents (music, movies, etc.)
# --delete: delete files which are not present on the source
#     use for folders which stay authoritative and up-to-date on the source

echo "Backing up $SOURCEHOME$FONTS to $DESTINATIONHOME"
rsync -rvh --ignore-existing  $SOURCEHOME$FONTS $DESTINATIONHOME
echo
echo
echo

echo "Backing up $SOURCEHOME$MUSIC to $DESTINATIONHOME"
rsync -rvh --ignore-existing  $SOURCEHOME$MUSIC $DESTINATIONHOME
echo
echo
echo

echo "Backing up $SOURCEHOME$DATA to $DESTINATIONHOME"
rsync -rvh $SOURCEHOME$DATA $DESTINATIONHOME
echo
echo
echo

echo "Backing up $SOURCEHOME$PICTURES to $DESTINATIONHOME"
rsync -rvht --ignore-existing  $SOURCEHOME$PICTURES $DESTINATIONHOME
echo
echo
echo

echo "Backing up $SOURCEHOME$PROJECTS to $DESTINATIONHOME"
rsync -rvht  $SOURCEHOME$PROJECTS $DESTINATIONHOME
echo
echo
echo

echo "Backing up $SOURCEHOME$GIT to $DESTINATIONHOME"
rsync -rvht  $SOURCEHOME$GIT $DESTINATIONHOME
echo
echo
echo

echo "Backing up $SOURCEHOME$DOCUMENTS to $DESTINATIONHOME"
rsync -rvht  $SOURCEHOME$DOCUMENTS $DESTINATIONHOME
echo
echo
echo

echo "Backing up $SOURCEHOME$SCRIPTS to $DESTINATIONHOME"
rsync -rvht  $SOURCEHOME$SCRIPTS $DESTINATIONHOME
echo
echo
echo

echo "Backing up $SOURCEHOME$CERTS to $DESTINATIONHOME"
rsync -rvht $SOURCEHOME$CERTS $DESTINATIONHOME
echo
echo
echo

echo "Backing up dotfiles in $SOURCEHOME to $DESTINATIONHOME"
rsync -rvh --filter='include **/.*' --filter='include **/.***' --filter='exclude **/*' $SOURCEHOME $DESTINATIONHOME


