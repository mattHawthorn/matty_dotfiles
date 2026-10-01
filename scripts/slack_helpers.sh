[ ! "$BASHUTILS_IMPORTED" == 1 ] && source "$(dirname "$BASH_SOURCE")/bashutils.sh"

# Slack Web API helpers. Each workspace needs a user token (xoxp-...) with the `search:read`, `files:read`,
# `users:read`, `channels:history`, `groups:history`, `im:history` and `mpim:history` user scopes, either
# exported as SLACK_TOKEN_<WORKSPACE> (e.g. SLACK_TOKEN_TRILLIANT) or saved in ~/.slack/tokens/<workspace>
# (e.g. ~/.slack/tokens/trilliant). A user token belongs to exactly one workspace, so choosing the token chooses
# the workspace.

slack-token() {
  # Usage: slack-token [workspace]
  local workspace="${1-trilliant}"
  local var="SLACK_TOKEN_$(tr 'a-z-' 'A-Z_' <<<"$workspace")" file="$HOME/.slack/tokens/$workspace"
  if [ -n "${!var}" ]; then
      echo "${!var}"
  elif [ -f "$file" ]; then
      tr -d '[:space:]' < "$file"
  else
      echo "$var is not set and $file does not exist" >&2
      return 1
  fi
}

slack-api() {
  # Usage: slack-api <token> <method> [param=value ...]
  local token="$1" method="$2"; shift 2
  local params=() param
  for param in "$@"; do
      params+=(--data-urlencode "$param")
  done
  curl -sS -G --retry 3 -H "Authorization: Bearer $token" "https://slack.com/api/$method" "${params[@]}" \
    | jq -c --arg method "$method" 'if .ok then . else error("\($method): \(.error)") end'
}

slack-api-pages() {
  # Usage: slack-api-pages <token> <method> <container jq path, "" for top level> <items key> [param=value ...]
  # Emits one item per line from Slack's page-numbered endpoints (search.*, files.list), whose page count
  # sits at <container>.paging.pages.
  local token="$1" method="$2" container="$3" items="$4"; shift 4
  local page=1 response
  while :; do
      response="$(slack-api "$token" "$method" "$@" page="$page")" || return
      jq -c "${container}.${items}[]" <<<"$response"
      [ "$page" -lt "$(jq "${container}.paging.pages // 1" <<<"$response")" ] || break

      page=$((page + 1))
  done
}

resolve-user-id() {
  # Usage: resolve-user-id <token> <user_id>
  # Prints the user's display name, falling back to their full name, their handle, and then the ID itself.
  # Needs the `users:read` scope.
  slack-api "$1" users.info user="$2" \
    | jq -r '.user as $user | [$user.profile.display_name, $user.real_name, $user.name] | map(select((. // "") != "")) | .[0] // $user.id'
}

# jq definitions shared by the programs below. Files made by people have no username.
_slack_jq_author='def author: {id: .user, name: (.username | if . == "" then null else . end)};'

slack-last-n-days() {
  # Usage: slack-last-n-days [-w|--workspace name] [n_days]
  # Emits one event per JSON value, oldest first: messages by me, messages and canvases mentioning me, and
  # canvases created by me, since local midnight n_days ago. A message in a thread carries the thread's root
  # (author, text, reply count), fetched with one call per thread. Slack's API exposes no canvas comments; a canvas
  # mention's time is the canvas's last update, since the mention itself carries no timestamp.
  local workspace=trilliant n_days=1
  while [ "$#" -gt 0 ]; do
      local arg="$1"; shift
      case "$arg" in
          -h|--help) echo "Usage: slack-last-n-days [-w|--workspace name] [n_days]"; return ;;
          -w|--workspace) workspace="$1"; shift ;;
          -*) echo "Unknown option: $arg" >&2; return 1 ;;
          *) n_days="$arg" ;;
      esac
  done
  local token; token="$(slack-token "$workspace")" || return
  local me; me="$(slack-api "$token" auth.test | jq -r .user_id)" || return
  local since="$(days-ago "$n_days" %s)"
  local after="after:$(days-ago "$((n_days + 1))")"  # `after:` excludes the named day

  local events; events="$({
      slack-api-pages "$token" search.messages .messages matches query="from:<@$me> $after" count=100 \
        | jq -c '{kind: "comment", item: .}'
      slack-api-pages "$token" search.messages .messages matches query="<@$me> $after" count=100 \
        | jq -c '{kind: "mention", item: .}'
      slack-api-pages "$token" search.files .files matches query="<@$me> $after" count=100 \
        | jq -c '{kind: "mention", item: .}'
      slack-api-pages "$token" files.list "" files user="$me" ts_from="$since" count=100 \
        | jq -c '{kind: "created", item: .}'
  } | jq -n -c --arg me "$me" --argjson since "$since" "$_slack_jq_author"'
      def channel_type: if .is_im then "im" elif .is_mpim then "mpim" elif .is_private then "private" else "public" end;
      def message($kind):
        (.permalink | capture("[?&]thread_ts=(?<ts>[0-9.]+)").ts // null) as $thread_ts  # a thread root has its own ts here
        | {
          kind: $kind,
          scope: (if $thread_ts != null and $thread_ts != .ts then "thread" else "channel" end),
          epoch: (.ts | tonumber),
          ts,
          channel: {
            id: .channel.id,
            name: .channel.name,
            type: (.channel | channel_type),
            permalink: (.permalink | sub("/p[0-9]+(\\?.*)?$"; ""))
          },
          thread: (
            if $thread_ts == null then null
            else {id: $thread_ts, permalink: (.permalink | sub("/p[0-9]+\\?.*$"; "/p" + ($thread_ts | sub("\\."; ""))))}  # the root message
            end
          ),
          author: author,
          text,
          permalink
        };
      def canvas($kind; $epoch):
        {kind: $kind, scope: "document", epoch: $epoch, id, title, author: author, permalink};
      def is_canvas: .filetype == "quip";  # canvases are served as Quip documents

      [
        inputs
        | .kind as $kind
        | .item
        | if has("ts") then
            select($kind == "comment" or .user != $me) | message($kind)
          else
            select(is_canvas)
            | if $kind == "created" then canvas($kind; .created) else select(.user != $me) | canvas($kind; .updated // .created) end
          end
        | select(.epoch >= $since)
        | .time = (.epoch | floor | todate)
      ]
      | unique_by([.kind, .permalink])
      | sort_by(.epoch)
      | .[]
  ')" || return

  # Search results omit thread roots, so each thread's root is fetched separately; the root comes first in replies
  local roots="$(
    jq -r 'select(.thread != null) | [.channel.id, .thread.id] | @tsv' <<<"$events" \
      | sort -u \
      | while IFS=$'\t' read -r channel ts; do
            slack-api "$token" conversations.replies channel="$channel" ts="$ts" limit=1 \
              | jq -c --arg channel "$channel" '.messages[0] | {key: "\($channel) \(.ts)", value: .}'
        done \
      | jq -s -c from_entries
  )"
  jq -c --argjson roots "$roots" "$_slack_jq_author"'
      if .thread == null then . else
        .thread += ($roots["\(.channel.id) \(.thread.id)"] | if . == null then {} else {author: author, text, reply_count} end)
      end
  ' <<<"$events"
}

slack-emoji-map() {
  # Usage: slack-emoji-map
  # Prints a JSON object mapping Slack's standard emoji short names (e.g. joy, +1, skin-tone-3) to their characters.
  # Slack's names come from iamcal/emoji-data, published on npm as emoji-datasource; the map is built from it on
  # first use and cached. Custom workspace emoji are images, so they have no entry.
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/slack-helpers/emoji.json"
  if [ ! -s "$cache" ]; then
      mkdir -p "$(dirname "$cache")" || return
      curl -sSf --retry 3 https://cdn.jsdelivr.net/npm/emoji-datasource/emoji.json \
        | jq -c '
            def from_hex: ascii_downcase | explode | map(if . >= 97 then . - 87 else . - 48 end) | reduce .[] as $digit (0; . * 16 + $digit);
            map(.short_names[] as $name | {key: $name, value: (.unified | split("-") | map(from_hex) | implode)}) | from_entries
          ' > "$cache.tmp" \
        && mv "$cache.tmp" "$cache" \
        || { rm -f "$cache.tmp"; return 1; }
  fi
  cat "$cache"
}

slack-to-md() {
  # Usage: slack-last-n-days 7 | slack-to-md [-w|--workspace name]
  # Groups events by channel (or by canvas), then by thread, most recent interaction (message, canvas or mention
  # of me) first. Messages within a thread read oldest first.
  # User IDs are resolved to names via the workspace's API. Requires jq >= 1.7: strflocaltime in 1.6 gets the DST
  # offset wrong.
  local workspace=trilliant
  while [ "$#" -gt 0 ]; do
      local arg="$1"; shift
      case "$arg" in
          -h|--help) echo "Usage: slack-last-n-days 7 | slack-to-md [-w|--workspace name]"; return ;;
          -w|--workspace) workspace="$1"; shift ;;
          *) echo "Unknown option: $arg" >&2; return 1 ;;
      esac
  done
  local token; token="$(slack-token "$workspace")" || return
  local events; events="$(jq -s -c .)" || return
  local users="$(
    jq -r '
        .[]
        | (.author.id, .thread.author.id, (select(.channel.type == "im") | .channel.name),
           (.text, .thread.text | values | scan("<@([UW][A-Z0-9]+)") | .[0]))
        | values
    ' <<<"$events" \
      | sort -u \
      | while read -r id; do
            jq -n -c --arg id "$id" --arg name "$(resolve-user-id "$token" "$id" || echo "$id")" '{key: $id, value: $name}'
        done \
      | jq -s -c from_entries
  )"
  local emoji; emoji="$(slack-emoji-map)" || emoji='{}'  # without the map, :name: stays as-is

  jq -r --argjson users "$users" --argjson emoji "$emoji" '
    def local_time: strflocaltime("%Y-%m-%d %H:%M %Z");
    def user_name: $users[.] // .;
    def is_list_item: test("^ *- ");
    def markdown_lines:  # Slack bullets are characters, and its line breaks would otherwise be joined by Markdown
      split("\n")
      | map(sub("^(?<indent> *)[•◦▪▫] "; "\(.indent)- "))
      | . as $lines
      | [
          range(length) as $i
          | if $i > 0 and $lines[$i] != "" and $lines[$i - 1] != ""
               and ($lines[$i] | is_list_item) != ($lines[$i - 1] | is_list_item)
            then "" else empty end,  # a list needs blank lines around it to start and end
            $lines[$i]
        ]
      | map(if . == "" or is_list_item then . else . + "  " end)  # trailing double space is a hard line break
      | join("\n");
    def mrkdwn:  # Slack escapes only &, < and >, so unescaping goes last
      gsub("<@(?<id>[UW][A-Z0-9]+)(\\|[^>]*)?>"; "@" + (.id | user_name))
      | gsub("<#(?<id>C[A-Z0-9]+)\\|(?<name>[^>]+)>"; "#" + .name)
      | gsub("<#(?<id>C[A-Z0-9]+)\\|?>"; "#" + .id)
      | gsub("<!subteam\\^[A-Z0-9]+\\|(?<label>[^>]+)>"; .label)
      | gsub("<!(?<name>here|channel|everyone)(\\|[^>]*)?>"; "@" + .name)
      | gsub("<(?<url>[a-z]+:[^|>]+)\\|(?<label>[^>]+)>"; if .label == .url then "<\(.url)>" else "[\(.label)](\(.url))" end)
      | gsub("<(?<url>[a-z]+:[^>]+)>"; "<\(.url)>")
      | gsub("&lt;"; "<") | gsub("&gt;"; ">") | gsub("&amp;"; "&")
      | gsub(":(?<name>[a-z0-9_+-]+):"; $emoji[.name] // ":\(.name):")  # custom emoji have no character and stay as-is
      | markdown_lines;
    def body_lines: gsub("\r"; "") | sub("\n+$"; "") | select(. != "") | "", .;
    def quoted: split("\n") | map(if . == "" then ">" else "> " + . end) | join("\n");
    def channel_heading:
      if .type == "im" then "DM with \(.name | user_name)"
      elif .type == "mpim" then "Group DM with \(.name | ltrimstr("mpdm-") | sub("-[0-9]+$"; "") | split("--") | join(", "))"
      elif .type == "private" then "🔒 #\(.name)"
      else "#\(.name)" end;
    def most_recent_first: sort_by(map(.epoch) | max) | reverse;
    def message_entry:
      "### \(.epoch | local_time) · \(.author.id | user_name) · [link](\(.permalink))", (.text // "" | mrkdwn | body_lines), "";
    def document_entry:
      "- \(.epoch | local_time): \({created: "created", mention: "mentions you (time of last update)"}[.kind] // .kind)";
    def thread_section:  # the root is shown under the heading, so it is left out of the messages below it
      .[0].thread as $thread
      | if $thread == null then "## Outside threads", ""
        else
          "## [Thread started\($thread.author.id | if . then " by \(user_name)" else "" end), \($thread.id | tonumber | local_time)](\($thread.permalink))\($thread.reply_count | if . then " · \(.) replies" else "" end)",
          ($thread.text // empty | mrkdwn | body_lines | if . == "" then . else quoted end),
          ""
        end,
      (map(select(.ts != $thread.id)) | sort_by(.epoch)[] | message_entry);

    group_by(if .scope == "document" then "document \(.id)" else "channel \(.channel.id)" end)
    | most_recent_first
    | .[]
    | if .[0].scope == "document" then
        "# 📄 [\(.[0].title)](\(.[0].permalink))", "", (sort_by(.epoch)[] | document_entry), ""
      else
        "# [\(.[0].channel | channel_heading)](\(.[0].channel.permalink))", "", (group_by(.thread.id // "") | most_recent_first[] | thread_section)
      end
  ' <<<"$events"
}
