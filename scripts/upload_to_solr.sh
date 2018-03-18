#!/bin/bash
DOCDIR=$1;
# strip trailing slash if there
SOLRURL=${2%/}
RECURSIVE=$3
# get basename and full path to the script, stripping dotslash
ME=`basename $0`
#echo "IM $ME"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#echo "IM at $MYDIR"

case "$RECURSIVE" in
  -r)
    HOW="recursively"
    ;;
  *)
    HOW=""
    ;;
esac

if [ ! -d "$DOCDIR" ]; then
  echo "ERROR: directory $DOCDIR does not exist";
  exit
fi

cd $DOCDIR;
echo;
echo "uploading contents of $DOCDIR to $SOLRURL"" $HOW";

# get the files into an array
readarray -t FILES <<<"$(find . -maxdepth 1 -type f)";

for FILE in ${FILES[@]}; 
do
  # strip the leading dotslash
  FILE="${FILE#./}";
  # strip the trailing extension
  EXT="${FILE##*.}";
  #lowercase
  EXT="${EXT,,}";
  case "$EXT" in
    xml)
        TYPE="text"
        ;;
    json)
        TYPE="application"
        ;;
    *)
        echo "WARNING: illegal file extension $EXT: $FILE";
        continue
  esac
  # if you made it here you have a legal extension
  echo "uploading $FILE to $SOLRURL";
  curl $SOLRURL/update?commit=true --data-binary @$FILE -H Content-type:$TYPE/$EXT;
done

case "$RECURSIVE" in
  -r)
    readarray -t DIRS <<<"$(ls -d */)";
    for SUBDIR in ${DIRS[@]};
    do
        echo;echo;
        $MYDIR/$ME ${PWD%/}/$SUBDIR $SOLRURL $RECURSIVE;
    done
    ;;
  *)
    exit
    ;;
esac
