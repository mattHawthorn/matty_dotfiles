#!/usr/bin/env bash

_complete_databricks() {
_bourbaki_complete """
-h,--help 0(?)
-v,--version 0(?)
--debug 0(?)
--profile 1(?) _bourbaki_complete_choices datasci prod dev qa
clusters
  -h,--help 0(?)
  list
    -h,--help 0(?)
    --output 1 _bourbaki_complete_choices JSON TABLE
    --profile 1(?) _bourbaki_complete_choices datasci prod dev qa
  list-node-types
    --profile 1(?) _bourbaki_complete_choices datasci prod dev qa
fs
  cat
    - 1 _bourbaki_complete_choices PATH
    -h,--help 0(?)
    --profile 1(?) _bourbaki_complete_choices datasci prod dev qa
  cp
    - 1 _bourbaki_complete_choices SRC
    - 1 _bourbaki_complete_choices DST
    -r,--recursive 0(?)
    -h,--help 0(?)
    --profile 1(?) _bourbaki_complete_choices datasci prod dev qa
  ls
    - + _bourbaki_complete_choices PATH
    -h,--help 0(?)
    -l 0(?)
    --absolute 0(?)
    --profile 1(?) _bourbaki_complete_choices datasci prod dev qa
jobs
  get
    -h,--help 0(?)
    --job-id 1(1) _bourbaki_complete_from_stdout _db_list_job_ids
    --profile 1(?) _bourbaki_complete_choices datasci prod dev qa
  list
    -h,--help 0(?)
    --output _bourbaki_complete_choices JSON TABLE
    --profile 1(?) _bourbaki_complete_choices datasci prod dev qa
  run-now
    -h,--help 0(?)
    --job-id 1(1) _bourbaki_complete_from_stdout _db_list_job_ids
    --jar-params _bourbaki_complete_choices JSON_ARRAY
    --notebook-params _bourbaki_complete_choices JSON_OBJECT
    --python-params _bourbaki_complete_choices JSON_ARRAY
    --spark-submit-params JSON_ARRAY
    --profile 1(?) _bourbaki_complete_choices datasci prod dev qa
runs
  get
    -h,--help 0(?)
    --profile 1(?) _bourbaki_complete_choices datasci prod dev qa
    --run-id 1(1) _bourbaki_complete_from_stdout _db_list_run_ids
  get-output
    -h,--help 0(?)
    --profile 1(?) _bourbaki_complete_choices datasci prod dev qa
    --run-id 1(1) _bourbaki_complete_from_stdout _db_list_run_ids
  list
    -h,--help 0(?)
    --profile 1(?) _bourbaki_complete_choices datasci prod dev qa
"""
}

_which_dbprofile() {
  local cmd
  cmd="${COMP_WORDS[0]}"
  if [ "$cmd" == "dbdatasci" ] || [ "$cmd" == "dbprod" ] || [ "$cmd" == "dbdev" ]; then
    echo "${cmd#db}"
  else
    i=1
    while [ $i -lt ${#COMP_WORDS[@]} ]; do
      [ "${COMP_WORDS[$i]}" == "--profile" ] && cmd="${COMP_WORDS[$((i+1))]}" && break
      ((i++))
    done
    [ -z "$cmd" ] || echo "$cmd"
  fi
}

_db_list_run_ids() {
  local profile
  profile=$(_which_dbprofile)
  [ -z "$profile" ] || databricks --profile $profile runs list | cut -f 1 -d ' '
}

_db_list_job_ids() {
  local profile
  profile=$(_which_dbprofile)
  [ -z "$profile" ] || databricks --profile $profile jobs list | cut -f 1 -d ' '
}

alias dbdatasci='databricks --profile datasci'
alias dbdev='databricks --profile dev'
alias dbprod='databricks --profile prod'

dbconnect() {
  local env
  env=$1; shift
  # alias for databricks-connect to manage different envs, since it doesn't support a single config file for all envs
  [ ! -f ~/.databricks-connect.d/$env ] && echo "dbconnect takes a positional arg, one of: $(ls -x ~/.databricks-connect.d)" && return 1
  [ $# -eq 0 ] && databricks-connect && return $? || return $?
  [ -L ~/.databricks-connect ] && rm ~/.databricks-connect
  ln -sT ~/.databricks-connect.d/$env ~/.databricks-connect && databricks-connect "$@" || return $?
}

complete -o bashdefault -F _complete_databricks databricks
complete -o bashdefault -F _complete_databricks dbdatasci
complete -o bashdefault -F _complete_databricks dbdev
complete -o bashdefault -F _complete_databricks dbprod
