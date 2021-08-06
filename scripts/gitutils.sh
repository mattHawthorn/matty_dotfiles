#!/usr/bin/env bash

alias thisbranch='git symbolic-ref --short HEAD'

alias thisremote='git remote show'

alias pushthis='git push $(thisremote) $(thisbranch)'

alias pullthis='git fetch; git merge $(thisremote)/$(thisbranch)'

branch_diff() {
    if [ $# -eq 0 ]; then
        echo "Print a summary of the difference between two git refs in terms of commits."
        echo "This uses git log and so is interactive"
        echo
        echo "Usage:"
        echo "branch_diff <git-ref-1> [<git-ref-2>]"
        echo
        echo "if <git-ref-2> is ommitted, then the current ref is used in its place"
        return 1
    fi

    local that_branch that_branch current_ref common_ancestor common_ancestor_abbrev
    local this_lt_that that_lt_this
    current_ref="$(git rev-parse --abbrev-ref HEAD)"
    [ -z "$current_ref" ] && current_ref="$(git rev-parse HEAD)"
    that_branch="$1"; shift
    if [ ${#@} -gt 0 ]; then
        this_branch="$that_branch"
        that_branch="$1"
    else
        this_branch="$current_ref"
    fi

    common_ancestor="$(git merge-base $this_branch $that_branch)"
    common_ancestor_abbrev="$(git rev-parse --abbrev-ref $common_ancestor)"
    if git merge-base --is-ancestor "$that_branch" "$this_branch"; then that_lt_this=true; else that_lt_this=false; fi
    if git merge-base --is-ancestor "$this_branch" "$that_branch"; then this_lt_that=true; else this_lt_that=false; fi
    echo "Common ancestor commit of $this_branch and $that_branch is $common_ancestor"
    if [ ! -z "$common_ancestor_abbrev" ] && [ "$common_ancestor" != "$common_ancestor_abbrev" ]; then
        echo "$common_ancestor is also known as $common_ancestor_abbrev"
    fi

    if $that_lt_this; then
        echo
        echo "$that_branch is an ancestor of $this_branch"
    fi

    if ! $this_lt_that; then
    	echo
            echo "================================================"
            echo "Changes on $this_branch but not on $that_branch:"
            read
            git log "$this_branch" "^$that_branch"
	fi

    if git merge-base --is-ancestor "$this_branch" "$that_branch"; then
        echo
        echo "$this_branch is an ancestor of $that_branch"
    fi

    if ! $that_lt_this; then
        echo "================================================"
        echo "Changes on $that_branch but not on $this_branch:"
        read
	git log "$that_branch" "^$this_branch"
    fi
}
