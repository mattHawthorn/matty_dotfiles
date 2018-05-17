# to-do list

TODO_FILE=~/.todo/.todo
DONE_FILE=~/.todo/.done
TODO_DATE_FMT='%F@%H:%M'
TODO_CMDS="add finish drop rm resume next list ls bump push reorder finished done"

[ ! -d $(dirname $TODO_FILE) ] && mkdir $(dirname $TODO_FILE)
[ ! -e $TODO_FILE ] && touch $TODO_FILE
[ ! -e $DONE_FILE ] && touch $DONE_FILE

usage() {
	echo "Usage: todo (finish|drop|rm|resume|revive|bump|push) [ -E ]  TODO_LIST_QUERY"
    echo "       todo (list|ls)  [ [ -E ] TODO_LIST_QUERY ]"
    echo "       todo (finished|done)  [ [ -E ] DONE_LIST_QUERY ]"
    echo "       todo add  LIST_ITEM"
    echo "       todo reorder [ ROW_NUM1 [ROW_NUM2 [ ... ] ] ]"
    echo "       todo next"
}

todo() {
	local cmd="$1"; shift
    local grepargs='-i' line
    if [ "$1" == '-E' ]; then
        shift
        grepargs='-i -E'
    fi
	local item="$@"
	
	case "$cmd" in
	    add) grep -qiE "^$item\$" $TODO_FILE && echo "'$item' is already on your todo list!" && return 1
            local ntasks=$(($(wc -l $TODO_FILE | cut -f 1 -d ' ') + 1))
            echo "$item" >> $TODO_FILE && echo "Added item '$item' at position $ntasks successfully!"
    	    ;;
            
        finish|drop|bump|resume|revive|push|rm)
            [ "$cmd" == rm ] && cmd=drop
            [ "$cmd" == revive ] && cmd=resume
            
            if [ -z "$item" ]; then
                echo "Error: You must specify an item or item query to $cmd!"
                return 1
            fi
            
            if [ "$cmd" == resume ]; then
                local swap=$TODO_FILE
                local TODO_FILE=$DONE_FILE
                local DONE_FILE=$swap
                unset swap
            fi
            echo read from $TODO_FILE
            
            if ! grep -q $grepargs "$item" $TODO_FILE; then
                echo "Error: No item matching $item in $TODO_FILE!"
                return 1
            fi
            
            local ntasks=$(grep -c $grepargs "$item" $TODO_FILE)
            local n all=false msg="Choose a task 1-$ntasks or type 'a' to $cmd them all:"
            
            if [ $ntasks -gt 1 ]; then
                echo "$ntasks match the query '$item'"
                echo "$msg"
                echo
                grep $grepargs "$item" $TODO_FILE | nl -n rn -w 6
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
            else
                n=1
            fi
            
            if ! $all; then
                local item=$(grep $grepargs "$item" $TODO_FILE | head -$n | tail -1)
                echo "    ${cmd%e}""ing '$item' ..."
                item="^$item\$"
                grepargs="${grepargs%-E} -E"
            else
                echo "    ${cmd%e}""ing $ntasks ..."
            fi
            
            local tmpfile=$(mktemp)
            
            if [ "$cmd" == finish ]; then
                grep $grepargs "$item" $TODO_FILE | sort | uniq | {
                    while read line; do echo "$line"$'\t'"$(date +$TODO_DATE_FMT)"; done
                } > $tmpfile
                cat $DONE_FILE >> $tmpfile
                cat $tmpfile > $DONE_FILE && rm -f $tmpfile
            elif [ "$cmd" == resume ]; then
                grep $grepargs "$item" $TODO_FILE | cut -f -1 -d $'\t' | sort | uniq | {
                    while read line; do
                        if ! grep -E "^$line\$" $DONE_FILE; then
                            echo "$line"
                        else
                            echo "'$line' is already on your todo list; skipping ..." >&2
                        fi
                    done
                } > $tmpfile
                cat $DONE_FILE >> $tmpfile
                cat $tmpfile > $DONE_FILE && rm -f $tmpfile
            elif [ "$cmd" == bump ]; then
                grep $grepargs "$item" $TODO_FILE > $tmpfile
            fi
            
            grep -v $grepargs "$item" $TODO_FILE >> $tmpfile
            [ "$cmd" == push ] && grep $grepargs "$item" $TODO_FILE >> $tmpfile
            cat $tmpfile > $TODO_FILE && rm -f $tmpfile
            
            local suffix="ed"
            [ "$cmd" == drop ] && suffix="ped"
            echo "$cmd$suffix $ntasks tasks successfully!"
            ;;
            
        next) echo; head -1 $TODO_FILE && echo
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
            
        reorder)
            if [ -z "$item" ]; then
                echo "Error: You must specify a list of rows to $cmd!"
                return 1
            fi
            
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
            
            n=0
            cat $TODO_FILE | {
                while read line; do
                    if [ ${#args[@]} -eq 0 ] || [ $((n + 1)) -lt ${args[1]} ]; then
                        echo write
                        echo "$line" >> $tmpfile
                    elif [ $n -eq "${args[$n]}" ]; then
                        echo skip
                        args=(${args[@]:1:$#})
                    fi
                    ((n++))
                done
            }
            cat $tmpfile > $TODO_FILE && rm -f $tmpfile
            echo "Reordered:$reorder""successfully!"
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

_todo(){
    local last="${COMP_WORDS[$COMP_CWORD]}"
    if [ $COMP_CWORD -eq 1 ]; then
        COMPREPLY=($(compgen -W "$TODO_CMDS" "$last"))
    elif [ $COMP_CWORD -gt 1 ]; then
        case "${COMP_WORDS[1]}" in
            finish|drop|rm|list|ls|bump|push)
                COMPREPLY=($(compgen -W "$(cat $TODO_FILE)" "$last"))
                ;;
            resume|finished)
                COMPREPLY=($(compgen -W "$(cat $DONE_FILE)" "$last"))
                ;;
            reorder) COMPREPLY=($(compgen -W "$(seq 1 $(wc -l $TODO_FILE))" "$last"))
                return
                ;;
        esac
    fi
}

complete -o nospace -F _todo todo
