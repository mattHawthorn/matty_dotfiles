gh-login() {
  gh api user -q .login
}
alias date=gdate

iso-n-days-ago() {
  local n_days="${1-0}"
  date -d "-${n_days} days" --iso-8601
}

gh-recent-prs() {
  # Usage: gh-recent-prs [-d n_days] [-f json-field ...] [-s open|closed|merged ...] [-S qualifier ...] [--involves login | --involves-me] [-q query]
  # Emits one PR per JSON value, newest update first. `-q` is a jq filter applied to each PR.
  local n_days=1 fields=(number state author updatedAt title) states=() searches=() query=""
  while [ "$#" -gt 0 ]; do
      local arg="$1"; shift;
      case "$arg" in
          -h|--help)
              echo "Usage: gh-recent-prs [-d|--days n_days] [-f|--fields json-field ...] [-s|--states open|closed|merged ...] [-S|--search github-search-qualifiers ...] [--involves login | --involves-me] [-q|--query jq-filter]"
              return
              ;;
          -d|--days) n_days="$1"; shift ;;
          -f|--fields)
              while [ "$#" -gt 0 ] && [ "${1#-}" == "${1}" ]; do
                  local field="$1"; shift
                  fields+=("$field")
              done
              ;;
          -s|--states)
              while [ "$#" -gt 0 ] && [ "${1#-}" == "${1}" ]; do
                  local state="$1"; shift
                  states+=("$(echo "$state" | tr 'a-z' 'A-Z')")
              done
              ;;
          -S|--search)
              while [ "$#" -gt 0 ] && [ "${1#-}" == "${1}" ]; do
                  local search="$1"; shift
                  searches+=("$search")
              done
              ;;
          --involves-me) set -- --involves "$(gh-login)" "$@" ;;
          --involves)
              local login="$1"; shift
              searches+=("involves:$login" "reviewed-by:$login")  # `involves:` does not cover reviews
              ;;
          -q|--query) query="$1"; shift ;;
          *) echo "Unknown option: $arg" >&2; return 1 ;;
      esac
  done
  local prev_date=$(iso-n-days-ago "$n_days")
  local json_fields=()
  for field in "${fields[@]}"; do
      json_fields+=("--json" "$field")
  done

  # GitHub search qualifiers cannot be OR'd, so each alternative is a separate search and the results are
  # deduplicated below. `is:closed` includes merged PRs.
  local state_qualifiers=()
  case "$(printf '%s\n' "${states[@]}" | sort -u | xargs)" in
      ""|"CLOSED MERGED OPEN") state_qualifiers=("") ;;
      "OPEN") state_qualifiers=("is:open") ;;
      "MERGED") state_qualifiers=("is:merged") ;;
      "CLOSED") state_qualifiers=("is:closed is:unmerged") ;;
      "CLOSED MERGED") state_qualifiers=("is:closed") ;;
      "CLOSED OPEN") state_qualifiers=("is:unmerged") ;;
      "MERGED OPEN") state_qualifiers=("is:open" "is:merged") ;;
      *) echo "Unknown state in: ${states[*]}; expected open, closed and/or merged" >&2; return 1 ;;
  esac
  [ "${#searches[@]}" -gt 0 ] || searches=("")
  local qualifiers=() search state_qualifier
  for search in "${searches[@]}"; do
      for state_qualifier in "${state_qualifiers[@]}"; do
          qualifiers+=("$search $state_qualifier")
      done
  done

  # Filter by update date server-side and page through results by narrowing the upper bound of the
  # date range, since `gh pr list` alone can only return a limited number of PRs sorted by creation date.
  # Pages are small because GitHub's GraphQL node budget rejects pages of 50+ PRs when fetching commits.
  local page_size=40 qualifier upper page pages=""
  for qualifier in "${qualifiers[@]}"; do
      upper='*'
      while :; do
          page="$(gh pr list "${json_fields[@]}" -s all -S "updated:${prev_date}..${upper} ${qualifier} sort:updated-desc" -L "$page_size" -q '.[]')" || return
          [ -n "$page" ] || break

          pages+="$page"$'\n'  # one PR per line
          [ "$(wc -l <<<"$page")" -lt "$page_size" ] && break

          local oldest="$(tail -n 1 <<<"$page" | jq -r .updatedAt)"
          [ "$oldest" == "$upper" ] && break

          upper="$oldest"  # inclusive, so the boundary PR is fetched twice and deduplicated below
      done
  done
  jq -s "unique_by(.number) | sort_by(.updatedAt) | reverse | .[]${query:+ | ($query)}" <<<"$pages"
}

gh-work-last-n-days() {
  local me="$(gh-login)"
  local n_days="${1-1}"
  local prev_date=$(iso-n-days-ago "$n_days")
  # `--involves` misses commits pushed to PRs the user neither opened, reviewed, commented on nor was mentioned in
  local prs="$(gh-recent-prs -d "${n_days}" --involves "$me" -f createdAt url headRefName baseRefName isDraft mergeCommit reviews comments commits \
    | jq -c "
        (.reviews = ([.reviews[] | select(.body != \"\" and .author.login == \"$me\" and .submittedAt >= \"$prev_date\")] | sort_by(.submittedAt)))
        | (.comments = ([.comments[] | select(.author.login == \"$me\" and .createdAt >= \"$prev_date\")] | sort_by(.createdAt)))
        | (.commits = ([.commits[] | select(any(.authors[]; .login == \"$me\") and .committedDate >= \"$prev_date\")] | sort_by(.committedDate)))
    "
  )"

  # A PR lists every commit on its head branch that its base lacks, so merging main (or a stacked branch) into it
  # pulls in commits native to other PRs. GitHub knows which merged PR introduced a commit; ask Github only for the
  # commits that appear in more than one fetched PR, and fall back to the lowest PR number where that is ambiguous.
  local owners="$(
    jq -s -r '[.[] | .number as $n | .commits[] | {oid, n: $n}] | group_by(.oid) | map(select(length > 1) | .[0].oid) | .[]' <<<"$prs" \
    | while read -r oid; do
          gh api "repos/{owner}/{repo}/commits/$oid/pulls" -q "select(length == 1) | {key: \"$oid\", value: .[0].number}"
      done \
    | jq -s 'from_entries'
  )"

  jq -s --argjson owners "$owners" --arg me "$me" --arg prev_date "$prev_date" '
      map(.number) as $numbers
      | (map(select(.mergeCommit != null) | {key: .mergeCommit.oid, value: .baseRefName}) | from_entries) as $merged_into
      | (
         map(.number as $n | .commits[] | {oid, n: $n}) | group_by(.oid)  # list of list of {commit#, PR#} grouped by commit
         | map(
            {
               key: .[0].oid,
               value: ($owners[.[0].oid] as $o | if $o != null and ([$o] | inside($numbers)) then $o else (map(.n) | min) end)
            }  # {commit#, PR#} where PR# is the PR that owns the commit (or the lowest-numbered PR if ambiguous)
         ) | from_entries
      ) as $native  # commit# -> owner PR# mapping for all commits
      | .[]
      | . as $pr
      | (
         .commits |= map(select(
            # the PR owns the commit, and it is not another PRs merge commit unless that PR merged into this branch
            $native[.oid] == $pr.number
            and ($merged_into[.oid] == null or $merged_into[.oid] == $pr.headRefName)
         ))
      )
      | select(
         (.reviews | length > 0) or (.comments | length > 0) or (.commits | length > 0) or (.author.login == $me and .createdAt >= $prev_date)
      )
  ' <<<"$prs"
}

gh-work-to-md() {
  # Usage: gh-work-last-n-days 7 | gh-work-to-markdown
  # Requires jq >= 1.7: strflocaltime in 1.6 gets the DST offset wrong.
  jq -r '
    def status_emoji: {OPEN: "🟢", MERGED: "🟣", CLOSED: "🔴"}[.] // .;
    def verdict: {
      APPROVED: "✅ approved",
      CHANGES_REQUESTED: "❌ changes requested",
      COMMENTED: "💬 commented",
      DISMISSED: "🚫 dismissed",
      PENDING: "⏳ pending"
    }[.] // .;
    def local_time: fromdateiso8601 | strflocaltime("%Y-%m-%d %H:%M %Z");
    def body_lines: gsub("\r"; "") | sub("\n+$"; "") | select(. != "") | "", .;
    def entry(heading; body): "### \(heading)", (body | body_lines), "";
    def section(name; items): if (items | length) > 0 then "## \(name):", "", items[] else empty end;
    def commit_message:  # GitHub truncates long headlines with "…" and moves the remainder to the start of the body
      if (.messageHeadline | endswith("…")) and (.messageBody | startswith("…"))
      then .messageHeadline[:-1] + .messageBody[1:] else .messageHeadline + "\n\n" + .messageBody end
      | split("\n") | map(select(test("^co-authored-by:"; "i") | not)) | join("\n");  # rendered as a list instead
    def co_authors: .authors[1:] | select(length > 0) | "", "Co-authors:", (.[] | "- \(.name)\(if .login then " (\(.login))" else "" end)");

    "# \(.state | status_emoji) #\(.number) \(.title)",
    "",
    section("Comments"; [.comments[] | entry(.createdAt | local_time; .body)]),
    section("Reviews"; [.reviews[] | entry("\(.submittedAt | local_time): \(.state | verdict)"; .body)]),
    section("Commits"; [(.commits // [])[] |
      "### \(.committedDate | local_time): `\(.oid[:8])`", co_authors, (commit_message | body_lines), ""
    ]),
    ""
  '
}

gh-work-to-html() {
  # Usage: gh-work-last-n-days 7 | gh-work-to-html [out_dir] [--no-open]
  # Writes index.html (a copy of gh_work.html, which renders client-side) and data.js beside it, then opens it.
  local out_dir="${XDG_CACHE_HOME:-$HOME/.cache}/gh-work" should_open=true arg
  for arg in "$@"; do
      case "$arg" in
          -h|--help) echo "Usage: gh-work-to-html [out_dir] [--no-open]"; return ;;
          --no-open) should_open=false ;;
          -*) echo "Unknown option: $arg" >&2; return 1 ;;
          *) out_dir="$arg" ;;
      esac
  done
  mkdir -p "$out_dir" || return
  jq -s -r '"window.GH_WORK = " + ({generated: (now | todate), prs: .} | tojson) + ";"' > "$out_dir/data.js" || return
  cp "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/gh_work.html" "$out_dir/index.html" || return
  echo "$out_dir/index.html"
  if [ "$should_open" == true ]; then
      open "$out_dir/index.html"
  fi
}
