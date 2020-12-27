#!/usr/bin/env bash

_complete_conda() {
_bourbaki_complete """
-h,--help 0(?)
-V,--version 0(?)
activate
  - 1 _bourbaki_complete_from_stdout _list_conda_envs
  -h,--help 0(?)
  --stack 0(?)
  --no-stack 0(?)
deactivate
install
  - + _bourbaki_complete_choices PACKAGE_NAME
  -h,--help 0(?)
  --file 1(*) _bourbaki_complete_files .txt
  -n,--name 1(?) _bourbaki_complete_from_stdout _list_conda_envs
  -c,--channel 1(?)
  --use-local 0(?)
  --override-channels 0(?)
  --strict-channel-priority 0(?)
  --no-channel-priority 0(?)
  --only-deps 0(?)
  --force-reinstall 0(?)
  --freeze-installed,--no-update-deps 0(?)
  --update-deps 0(?
  -S,--satisfied-skip-solve 0(?)
  --update-all,--all 0(?)
  --copy 0(?)
  -m,--mkdir 0(?)
  --offline 0(?)
  -d,--dry-run 0(?)
  --json 0(?)
  -q,--quiet 0(?)
  -v,--verbose 0(*)
  -y,--yes 0(?)
  --download-only 0(?)
  --show-channel-urls 0(?)
create
  -h,--help 0(?)
  --clone 1(?) ENV
  --file 1(*) _bourbaki_complete_files .txt
  --dev 0(?)
  -n,--name 1(?) _bourbaki_complete_from_stdout _list_conda_envs
  -c,--channel
  -p,--prefix 1(?) PATH
  --use-local 0(?)
  --override-channels 0(?)
  --strict-channel-priority 0(?)
  --no-channel-priority 0(?)
  --only-deps 0(?)
  --offline 0(?)
  -d,--dry-run 0(?)
  --json 0(?)
  -q,--quiet 0(?)
  -v,--verbose 0(*)
  -y,--yes 0(?)
  --download-only 0(?)
  --show-channel-urls 0(?)
env
  -h,--help 0(?)
  list
    -h,--help 0(?)
    --json 0(?)
    -q,--quiet 0(?)
    -v,--verbose 0(*)
  create
    -h,--help 0(?)
    -n,--name 1(?) _bourbaki_complete_from_stdout _list_conda_envs
    -f,--file 1(?) _bourbaki_complete_files .yml .yaml
    --offline 0(?)
    --force 0(?)
    --prune 0(?)
    --json 0(?)
    -q,--quiet 0(?)
    -v,--verbose 0(*)
  remove
    -h,--help 0(?)
    -n,--name 1(?) _bourbaki_complete_from_stdout _list_conda_envs
    -d,--dry-run 0(?)
    --json 0(?)
    -q,--quiet 0(?)
    -v,--verbose 0(*)
    -y,--yes 0(?)
  update
    -h,--help 0(?)
    -n,--name 1(?) _bourbaki_complete_from_stdout _list_conda_envs
    -f,--file 1(?) _bourbaki_complete_files .yml .yaml
    --prune 0(?)
    --json 0(?)
    -q,--quiet 0(?)
    -v,--verbose 0(*)
list
  - ?(?) PACKAGE_REGEX
  -h,--help 0(?)
  -n,--name 1(?) _bourbaki_complete_from_stdout _list_conda_envs
  --show-channel-urls 0(?)
  -c,--canonical 0(?)
  -f,--full-name 0(?)
  --explicit 0(?)
  --md5 0(?)
  -e,--export 0(?)
  -r,--revisions 0(?)
  --no-pip 0(?)
  --json 0(?)
  -q,--quiet 0(?)
  -v,--verbose 0(*)
search
  - 1 _bourbaki_complete_choices CONDA_MATCHSPEC_PATTERN
  -h,--help 0(?)
  --envs 0(?)
  -i,--info 0(?)
  --platform 1(?) _bourbaki_complete_choices osx-32 osx-64 linux-32 linux-64 win-32 win-64
  -c,--channel 1(?)
  --use-local 0(?)
  --offline 0(?)
  --json 0(?)
  -q,--quiet 0(?)
  -v,--verbose 0(*)
update
  - + _bourbaki_complete_choices PACKAGE_NAME
  -h,--help 0(?)
  --file 1(*) _bourbaki_complete_files .txt
  -n,--name 1(?) _bourbaki_complete_from_stdout _list_conda_envs
  -c,--channel 1(?)
  --use-local 0(?)
  --override-channels 0(?)
  --strict-channel-priority 0(?)
  --no-channel-priority 0(?)
  --only-deps 0(?)
  --force-reinstall 0(?)
  --freeze-installed,--no-update-deps 0(?)
  --update-deps 0(?
  -S,--satisfied-skip-solve 0(?)
  --update-all,--all 0(?)
  --copy 0(?)
  --offline 0(?)
  -d,--dry-run 0(?)
  --json 0(?)
  -q,--quiet 0(?)
  -v,--verbose 0(*)
  -y,--yes 0(?)
  --download-only 0(?)
  --show-channel-urls 0(?)
clean
  -h,--help 0(?)
  -d,--dry-run 0(?)
  --json 0(?)
  -q,--quiet 0(?)
  -v,--verbose 0(*)
  -y,--yes 0(?)
  -a,--all 0(?)
  -i,--index-cache 0(?)
  -p,--packages 0(?)
  -t,--tarballs 0(?)
info
  -h,--help 0(?)
  -a,--all 0(?)
  --base 0(?)
  -e,--envs 0(?)
  -s,--system 0(?)
  --json 0(?)
  -q,--quiet 0(?)
  -v,--verbose 0(*)
uninstall
  - + _bourbaki_complete_choices PACKAGE_NAME
  -h,--help 0(?)
  -n,--name 1(?) _bourbaki_complete_from_stdout _list_conda_envs
  -c,--channel 1(?)
  --use-local 0(?)
  --all 0(?)
  --offline 0(?)
  -d,--dry-run 0(?)
  --json 0(?)
  -q,--quiet 0(?)
  -v,--verbose 0(*)
  -y,--yes 0(?)
"""
}


[ -z "$_CONDA_PREFIX" ] && _CONDA_PREFIX=$(conda info --base)

_list_conda_envs() {
  ls $_CONDA_PREFIX/envs
}

complete -o bashdefault -F _complete_conda conda
complete -o bashdefault -F _complete_conda mamba
