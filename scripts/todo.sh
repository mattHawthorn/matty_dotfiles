# to-do list

TODO_FILE=~/.todo/.todo
DONE_FILE=~/.todo/.done
TODO_DATE_FMT='%F@%H:%M'
TODO_CMDS="add finish drop rm resume next list ls bump push reorder finished done snapshot"

[ ! -d $(dirname $TODO_FILE) ] && mkdir $(dirname $TODO_FILE)
[ ! -e $TODO_FILE ] && touch $TODO_FILE
[ ! -e $DONE_FILE ] && touch $DONE_FILE

usage() {
	echo "Usage: todo (finish|drop|rm|bump|push) [ -E ]  TODO_LIST_QUERY"
    echo "       todo (list|ls)  [ [ -E ] TODO_LIST_QUERY ]"
    echo "       todo (resume|revive|finished|done)  [ [ -E ] DONE_LIST_QUERY ]"
    echo "       todo next"
    echo "       todo add  LIST_ITEM"
    echo "       todo reorder [ ROW_NUM1 [ROW_NUM2 [ ... ] ] ]"
    echo "       todo snapshot"
}

todo() {
	local cmd="$1"; shift
    local grepargs='-i' line
    if [ "$1" == '-E' ]; then
        shift
        grepargs='-i -E'
    fi
	local item="$(_escape "$@")"
	
	case "$cmd" in
	    
        next) echo; head -1 $TODO_FILE && echo
            ;;
		
		add) grep -qiE "^$item\$" $TODO_FILE && echo "'$item' is already on your todo list!" && return 1
            local ntasks=$(($(wc -l $TODO_FILE | cut -f 1 -d ' ') + 1))
            echo "$item" >> $TODO_FILE && echo "Added item '$item' at position $ntasks successfully!"
    	    ;;

        snapshot)
            local fn
            for fn in "$TODO_FILE" "$DONE_FILE"; do
                cat $fn > "$fn$(date +$TODO_DATE_FMT).snapshot"
            done
            ;;
            
	    list|ls|finished|done) 
            echo
            local sub
            [ "$cmd" == ls ] && cmd=list 
            [ "$cmd" == list ] && grepargs="-n $grepargs" && sub=:
            [ "$cmd" == done ] && cmd=finished
            [ "$cmd" == finished ] && local TODO_FILE=$DONE_FILE && sub=$'\t'
            
            grep $grepargs "$item" $TODO_FILE | { while read line; do echo "     $line" | tr "$sub" $'\t' ; done; }
            echo
            ;;
        
        finish|drop|bump|resume|revive|push|rm)
            [ "$cmd" == rm ] && cmd=drop
            [ "$cmd" == revive ] && cmd=resume
            
            if [ -z "$item" ]; then
                echo "Error: You must specify an item or item query to $cmd!"
                return 1
            fi
            
            local infile=$TODO_FILE outfile=$DONE_FILE
            if [ "$cmd" == resume ]; then
                infile=$DONE_FILE
                outfile=$TODO_FILE
            fi
            
            if ! grep -q $grepargs "$item" $infile; then
                echo "Error: No item matching $item in $infile!"
                return 1
            fi
            
            local ntasks=$(grep -c $grepargs "$item" $infile)
            local n=1 all=false

            if [ $ntasks -gt 1 ]; then
            	local msg="Choose a task 1-$ntasks or type 'a' to $cmd them all:"
                echo "$ntasks match the query '$item'"
                echo "$msg"
                echo
                grep $grepargs "$item" $infile | nl -n rn -w 6
                echo
                
                while read -p '? ' n; do
                    case $n in
                        a)  all=true; break ;;
                        *)  if ! [[ "$n" =~ ^[0-9]+$ ]]; then
                                echo "Misunderstood input '$n'; $msg"
                            else
                                if [ $n -lt 1 ] || [ $n -gt $ntasks ]; then
                                    echo "Input out of range; $msg"
                                    continue
                                else
                                    ntasks=1
                                    break
                                fi
                            fi 
                            ;;
                    esac
                done
            fi

            local suffix="ing"
            [ "$cmd" == drop ] && suffix="ping"
            if ! $all; then
                local item="$(grep $grepargs "$item" $infile | head -$n | tail -1)"
                echo "    ${cmd%e}""$suffix '$item' ..."
                item="^$(_escape "$item")\$"
                grepargs="${grepargs%-E} -E"
            else
                echo "    ${cmd%e}$suffix $ntasks ..."
            fi
            
            local tmpfile=$(mktemp)
            
            if [ "$cmd" == finish ]; then
            	grep $grepargs "$item" $infile | sort | uniq | {
                    while read line; do echo "$(date +$TODO_DATE_FMT)"$'\t'"$line"; done
                } > $tmpfile
                cat $outfile >> $tmpfile
                cat $tmpfile > $outfile && rm -f $tmpfile
            elif [ "$cmd" == resume ]; then
                grep $grepargs "$item" $infile | cut -f 2- -d $'\t' | sort | uniq | {
                    while read line; do
                        if ! grep -E "^$line\$" $outfile; then
                            echo "$line"
                        else
                            echo "'$line' is already on your todo list; skipping ..." >&2
                        fi
                    done
                } > $tmpfile
                cat $outfile >> $tmpfile
                cat $tmpfile > $outfile && rm -f $tmpfile
            elif [ "$cmd" == bump ]; then
                grep $grepargs "$item" $infile > $tmpfile
            fi
            
            grep -v $grepargs "$item" $infile >> $tmpfile
            [ "$cmd" == push ] && grep $grepargs "$item" $infile >> $tmpfile
            cat $tmpfile > $infile && rm -f $tmpfile
            
            local suffix="ed"
            [ "$cmd" == drop ] && suffix="ped"
            echo "${cmd%e}$suffix $ntasks tasks successfully!"
            ;;
            
        reorder)
            if [ -z "$item" ]; then
                echo "Error: You must specify a list of rows to $cmd!"
                return 1
            fi
            
            local ntodo=$(wc -l $TODO_FILE | cut -f 1 -d ' ')
            local tmpfile=$(mktemp) ntasks=$(wc -l $TODO_FILE | cut -f 1 -d ' ') reorder=$'\n' i=1 n
            local args=($(echo $@ | tr ' ' $'\n' | sort -n | uniq))
            if [ ${#args[@]} -lt $# ]; then
                echo "Error: repeated row number: $@!"
                return 1
            fi
            
            for n in "$@"; do
                if [[ "$n" =~ ^[0-9]+$ ]]; then
                    if [ $n -lt 1 ] || [ $n -gt $ntasks ]; then
                        echo "Error: only $ntasks tasks in todo list but got $n!"
                        rm -f $tmpfile
                        return 1
                    fi
                    line="$(sed "$n!d" $TODO_FILE)"
                    echo "$line" >> $tmpfile
                    reorder="$reorder    $line --> $i"$'\n'
                    ((i++))
                else
                    echo "Error: nonnumeric input: $n"
                    rm -f $tmpfile
                    return 1
                fi
            done
            n=1
            cat $TODO_FILE | {
                while read line; do
                    if [ ${#args[@]} -eq 0 ] || [ $n -lt ${args[0]} ]; then
                        echo "$line" >> $tmpfile
                    elif [ ${#args[@]} -eq 0 ]; then
                        args=()
                    elif [ $n -eq ${args[0]} ]; then
                        args=(${args[@]:1:$#})
                    fi
                    ((n++))
                done
            } && cat $tmpfile > $TODO_FILE 
            local ntodonow=$(wc -l $TODO_FILE | cut -f 1 -d ' ')
            [ $ntodo -eq $ntodonow ] && rm -f $tmpfile || 
                echo "Something's wrong- $ntodo lines in the original .todo and $ntodonow in the new version; "\
                     "you may recover your .todo from $tmpfile"
            echo $'\n'"Reordered:$reorder""successfully!"$'\n'
            ;;

        -h|--help) usage
            ;;
        
        *) 
            if [ ! -z "$cmd" ]; then 
                echo "Unknown command: $cmd"
                echo
            fi
            usage 
            ;;
	esac
}

_escape() {
	echo "$@" | sed -E 's/([\$	])/\\\1/g'
}

_todo(){
    local last="${COMP_WORDS[$COMP_CWORD]}"
    if [ $COMP_CWORD -eq 1 ]; then
        COMPREPLY=($(compgen -W "$TODO_CMDS" "$last" | sort))
    elif [ $COMP_CWORD -gt 1 ]; then
        case "${COMP_WORDS[1]}" in
            finish|drop|rm|list|ls|bump|push|resume|revive|done|finished)
                local queryfile=$TODO_FILE
                case "${COMP_WORDS[1]}" in
                	resume|revive|done|finished) queryfile=$DONE_FILE ;;
				esac
				local words="$(_escape "$(cat $queryfile)")"
                COMPREPLY=($(compgen -W "$words" "$last" | sort))
                ;;
            reorder) COMPREPLY=($(compgen -W "$(seq 1 $(wc -l $TODO_FILE  | cut -f 1 -d ' ') | sort -n)" "$last"))
                return
                ;;
        esac
    fi
}

complete -o nospace -F _todo todo
