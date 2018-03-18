#!/bin/bash

# Print help
if [ "$1" == "-h" ]
then
    echo """
        First argument is a path to a repo config file.
        repo config file allows # for comments and all other lines are read as follows:
            1) directory of the project
            2) master (develop) branch
            3...) branches to merge by default
        further args (if given) are branches into which to merge the master branch.
        """
    exit 0
fi


# get args from config file
if [[ -e $1 ]]
then
    # read the configuration from the file line by line
    OLDIFS=$IFS
    IFS=$'\n'
    i=0
    for line in $(cat $1)
    do
        if [[ "${line:0:1}" == "#" ]] || [[ ${#line} < 1 ]]
        then
            continue
        else
            case "$i" in
                0 ) 
                   PROJECTHOME=$(echo "${line}" | tr -d '[\n]')
                   #echo project home: $PROJECTHOME
                   ;;
                1 ) 
                   MASTER=$(echo "${line}" | tr -d '[[:space:]]')
                   #echo master branch: $MASTER
                   ;;
                * ) 
                   BRANCH=$(echo "${line}" | tr -d '[[:space:]]')
                   #echo branch: $BRANCH
                   BRANCHES="$BRANCHES $BRANCH"
                   ;;
            esac
            i=$((i+1))
        fi
    done
    IFS=$OLDIFS
else
    echo "Must supply a valid repo config file"
    exit 1
fi


# navigate to the directory and set the log file
if ! cd $PROJECTHOME
then
    echo "Not a directory: $PROJECTHOME" | tee -a $MERGELOG
    exit 1
fi

if ! PROJECTNAME=$(basename `git rev-parse --show-toplevel`) #$(basename `$PROJECTHOME`)
then
    echo "Not a git repository: $PROJECTHOME" | tee -a $MERGELOG
    exit 1
fi

MERGELOG="/tmp/merge_log_$PROJECTNAME.log"


## what branch was I on?
STATUS="$(git status)"
CURRENTBRANCH="$(echo $STATUS | cut -d " " -f 3)"


date >> $MERGELOG
echo >> $MERGELOG

echo "currently on $CURRENTBRANCH of $PROJECTNAME" | tee -a $MERGELOG
echo 

echo "checking out $MASTER branch" | tee -a $MERGELOG
git checkout $MASTER | tee -a $MERGELOG
echo "pulling most recent changes to $MASTER branch" | tee -a $MERGELOG

echo | tee -a $MERGELOG
git pull | tee -a $MERGELOG
echo | tee -a $MERGELOG


# pipes to tee should fail when the piping command fails
set -o pipefail
# add any branches that were passed at the cmd line
for branch in $BRANCHES ${@:2}
do
    echo "checking out branch $branch" | tee -a $MERGELOG
    if git checkout $branch | tee -a $MERGELOG; then
        echo "merging $MASTER into branch $branch" | tee -a $MERGELOG
        echo | tee -a $MERGELOG
        git merge $MASTER | tee -a $MERGELOG
        echo | tee -a $MERGELOG
    else
        echo "no branch $branch" | tee -a $MERGELOG
    fi
done


echo "returning to $CURRENTBRANCH"
git checkout $CURRENTBRANCH
echo >> $MERGELOG

exit 0
