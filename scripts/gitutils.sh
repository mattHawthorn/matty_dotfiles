#!/usr/bin/env bash

alias thisbranch='git symbolic-ref --short HEAD'

alias thisremote='git remote show | head -1'

alias pushthis='git push $(thisremote) $(thisbranch)'

alias pullthis='git fetch; git merge $(thisremote)/$(thisbranch)'

cd-repo-root() {
    # Change the current working directory to the repo root.
    local old;
    while [ ! -d .git/ ]; do
        old="$(pwd)";
        cd ..;
        [ "$(pwd)" = "$old" ] && echo "no repo root found" && return 1 || continue;
    done
}

run-from-repo-root() {
    # Run a shell command from the repo root, no matter where you are in the repo.
    # Does not mutate your current working directory, since the command is run in a subshell.
    # Usage:
    #    run-from-repo-root <any> <shell> <command> ...
    ( cd-repo-root && "$@" )
}

update_gh_token() {
    local token="$1" remote="${2:-origin}" url new_url
    if [ -z "$token" ]; then
        echo "Must pass token as first arg"
        return 1
    fi
    url="$(git remote get-url "${remote}")"
    if [ $? -ne 0 ]; then
        echo "Error getting URL for remote '${remote}'; does it exist?"
        return 1
    fi
    if [ "${url#https:}" != "$url" ]; then
        if [ "${url#*@}" == "$url" ]; then
            echo "Warning: no token in existing URL ${url}; adding one in"
            new_url="https://${token}@${url#https://}"
        else
            new_url="https://${token}@${url#*@}"
        fi
        echo "Updating token for remote '${remote}' URL ${url} to ${new_url}"
        git remote set-url "$remote" "$new_url"
    else
        echo "Non-https remote '${remote}' URL ${url}; can't update token"
        return 1
    fi
}

git-cp() {
    # Make a copy of a path (file or directory) while retaining git VCS history on both copies.
    # This is useful when performing complex refactors where a large source file may be split into multiple smaller
    # files and line-by-line authorship information is valuable to aid future readers in troubleshooting or
    # understanding. At the end of the operation, both files have identical history but can be edited independently;
    # e.g. code may be removed from both files, resulting in what looks like a split of the original file that preserves
    # authorship of the original lines.
    # This should be invoked with a clean staging area (no files waiting to be committed), otherwise some pre-commit
    # checks could be skipped. This is because, in the course of the operation, `git commit` is run with `--no-verify`
    # both for speed and because the new copy may be in an invalid state. It is expected that you will manually fix
    # imports in the copy along with any other edits you apply, which can be verified in a subsequent manual commit.
    #
    # For a detailed explanation of how this works, see:
    # https://dev.to/deckstar/how-to-git-copy-copying-files-while-keeping-git-history-1c9j
    #
    # Usage:
    #   git-cp <from-path> <to-path> [<temp-copy-path>]
    #
    #   The last argument may be omitted in which case `<to-path>.copy` will be used in its place.
    #   In either case, the temporary path is removed by the end of the operation, so the name is immaterial.
    #   We only provide the option to allow avoidance of the extremely unlikely scenario that a path already exists at
    #   `<to-path>.copy`.
    #
    # Example:
    #   git-cp foo.py bar.py
    #
    #   results in two files, foo.py and bar.py, with identical git history

    local from="$1" to="$2" copy="${3-}" mv_commit;
    [ -z "$copy" ] && copy="$from.copy";
    git mv "$from" "$to";
    git commit --no-verify -m "git mv $from $to";
    mv_commit="$(git rev-parse HEAD)";
    git reset --hard HEAD^;
    git mv "$from" "$copy";
    git commit --no-verify -m "git mv $from $copy (tmp)";
    git merge "$mv_commit";
    git commit --no-verify -a -m "merge mv commits, copying $from to $to and $copy";
    git mv "$copy" "$from";
    git commit --no-verify -m "git mv $copy $from (restored)"
}

add-lockfiles() {
    # Add all updated lockfiles to the git staging area. Saves you from having to perform gymnastics to add *only*
    # the lockfiles that have changed as a result some update in one library, while avoiding adding other changes
    # you wish to include in a subsequent commit.
    # Requires git (diff), grep.
    run-from-repo-root git add $(git diff --name-only | grep uv.lock)
}

branch-diff() {
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

authors () {
    git ls-tree --name-only -r HEAD "$@" | xargs -n1 git blame --line-porcelain \
        | grep '^author ' | cut -f 2- -d ' ' | sort | uniq -c | sort -nr
}

git-blame-json() {
  # Emit newline-delimited JSON (one compact object per line of a file) with the git blame info for that line:
  # commit, line_number, author, author_email, date, and commit_date.
  # `date` is the author date - when the line was originally written - which is also what `git blame` itself
  # displays. `commit_date` is the committer date - when the commit last got (re)applied to the branch, which
  # is what a rebase or amend rewrites. For a rebased or long-lived branch these can differ by weeks; use
  # `date` to ask when someone wrote a line and `commit_date` to ask when it arrived on this branch.
  # Both are ISO-8601 in UTC (e.g. 2026-08-09T23:32:19Z), so that they sort and compare consistently across
  # contributors' timezones rather than reflecting each author's local calendar. Since the format is
  # fixed-width and big-endian, string comparison against a bare date prefix works as you'd expect
  # (`.date < "2025-01-01"`), and `.date[:10]` gets you back the calendar day for grouping.
  # Requires git (blame), jq.
  #
  # Usage:
  #   git-blame-json <path> [<line-number> ...]
  #
  #   Line numbers restrict the blame (and therefore the output) to just those lines; duplicates are fine and
  #   collapse to a single object. If no line numbers are given, every line in the file is emitted.
  #   Nothing is emitted (and no error is raised) if git can't blame the path, e.g. it is untracked.
  #
  # Example:
  #   git-blame-json scripts/helpers.sh 5 84
  local args=() path="$1"; shift
  while [ $# -gt 0 ]; do
    args+=("-L" "$1,$1")
    shift
  done
  git blame --line-porcelain "${args[@]}" 2>/dev/null -- "$path" \
    | jq -Rn --indent 0 '[inputs
      | select(test("^([0-9a-f]{40} |author |author-mail |author-time |committer-time )"))] as $r
      | range(0; $r | length; 5) | $r[.:.+5] | select(length == 5) | {
        commit: (.[0] | split(" ")[0]),
        line_number: (.[0] | split(" ")[2] | tonumber),
        author: (.[1] | ltrimstr("author ")),
        author_email: (.[2] | ltrimstr("author-mail <") | rtrimstr(">")),
        date: (.[3] | ltrimstr("author-time ") | tonumber | todate),
        commit_date: (.[4] | ltrimstr("committer-time ") | tonumber | todate)
      }'
}

_rgblame_join() {
  # Merge git blame info into JSON match records (`{line_number, match}`) read from stdin, keyed on line
  # number, emitting one compact object per record. Records for lines that git can't blame get
  # `"state": "untracked"` in place of the blame fields.
  # Requires git (blame), jq.
  #
  # Usage:
  #   _rgblame_join <path> [<line-number> ...] < <json-match-records>
  #
  #   The line numbers are only used to narrow the blame, and should be those of the records on stdin.
  local path="$1"; shift
  jq --arg path "$path" --slurpfile blame <(git-blame-json "$path" "$@") --indent 0 \
    'INDEX($blame[]; "\(.line_number)") as $blame
    | {path: $path} + . + ($blame["\(.line_number)"] // {state: "untracked"})'
}

rgblame() {
  # invokable like rg, but outputs JSON with git commit info for each match.
  # All arguments are forwarded to `rg` verbatim, and each match becomes one compact JSON object containing the
  # path, line_number, matched text (`match`) and whole matching line without its line ending (`line`), merged
  # with the blame fields for that line (see `git-blame-json`).
  # Lines in files that git can't blame (e.g. untracked ones) get `"state": "untracked"` instead of blame fields.
  # Useful for answering "who wrote these, and when?" across a whole pattern's worth of matches at once, e.g.
  # to find who to ask about a deprecated call site, or to see whether a suspect idiom is recent or ancient.
  # Since the output is JSON, it composes with `jq` for further filtering, grouping and counting.
  # Requires rg, git (blame), jq.
  #
  # Caveats:
  #   Much slower than the equivalent `rg` invocation, because every file containing a match must be blamed:
  #   budget a few seconds per hundred matching files. Results stream out as each file is blamed, so a broad
  #   search is usable even before it finishes.
  #   Paths are reported by `rg` relative to the working directory, so run this from within the repo that
  #   contains the files being searched, otherwise git has nothing to blame and everything looks untracked.
  #   A line with more than one match on it yields one object per match, all with the same blame fields.
  #   `match` and `line` come from `rg`, which reports non-UTF-8 content as base64 rather than text, so both
  #   are null for a match on a line that isn't valid UTF-8. In multiline mode (`-U`) `line` holds the entire
  #   matched block, not a single line.
  #
  # Examples:
  #
  #   Who last touched each use of a function, and when:
  #       rgblame 'run-from-repo-root' scripts/
  #
  #   Count matches by author, most prolific first:
  #       rgblame -t py 'TODO' libs/ | jq -r .author | sort | uniq -c | sort -nr
  #
  #   Only matches that predate a given date:
  #       rgblame -t py 'TODO' libs/ | jq 'select(.date < "2025-01-01")'
  #
  #   A grep-like view annotated with who wrote each line and when:
  #       rgblame -t py 'TODO' libs/ | jq -r '"\(.date[:10]) \(.author): \(.line)"'

  # A single `jq` flattens the whole `rg --json` stream to one tab-separated line per match, so that the loop
  # below can read it with a builtin instead of spawning a process per match. The path goes last, since only
  # the final field of a `read` may contain the delimiter, and paths (unlike the other two fields) may
  # contain tabs. Matches for a given file arrive contiguously, so a change of path means the previous file
  # has been fully seen and can be blamed - and must also be blamed after the loop, for the final file.
  local line_no record path prev_path="" line_nos=() records=()
  rg "$@" --json \
    | jq -r 'select(.type == "match") | .data as $d | $d.submatches[]
      | {line_number: $d.line_number, match: .match.text, line: ($d.lines.text | rtrimstr("\n") | rtrimstr("\r"))}
      | "\(.line_number)\t\(tojson)\t\($d.path.text)"' \
    | {
        while IFS=$'\t' read -r line_no record path; do
          if [ "$path" != "$prev_path" ]; then
            if [ -n "$prev_path" ]; then
              printf '%s\n' "${records[@]}" | _rgblame_join "$prev_path" "${line_nos[@]}"
            fi
            prev_path="$path" line_nos=() records=()
          fi
          line_nos+=("$line_no") records+=("$record")
        done
        if [ -n "$prev_path" ]; then
          printf '%s\n' "${records[@]}" | _rgblame_join "$prev_path" "${line_nos[@]}"
        fi
      }
}
