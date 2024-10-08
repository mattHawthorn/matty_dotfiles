#!/usr/bin/env bash

_complete_poetry() {
_bourbaki_complete """
-h,--help 0(?)
-V,--version 0(?)
-v,--verbose 0(*)
run
  - 1 _bourbaki_complete_from_stdout compgen -c
  - * _command_offset 2
  --ansi 0(?)
  --no-ansi 0(?)
  -V,--version 0(?)
  -h,--help 0(?)
  -v,--verbose 0(*)
  -q,--quiet 0(?)
  -n,--no-interaction 0(?)
  --no-plugins 0(?)
  --no-cache 0(?)
  -C,--directory 1(?) _filedir -d
add
  - + _bourbaki_complete_choices '<package-name>'
  -G,--group _bourbaki_complete_choices '<group-name>'
  -e,--editable 0(?)
  -E,--extras +(?) _bourbaki_complete_choices <extras-name>
  --optional 0(?)
  --python 1(?) _bourbaki_complete_choices <python-version>
  --platform 1(?) _bourbaki_complete_choices <platform-name>
  --source 1(?) _bourbaki_complete_choices <source-name>
  --allow-prereleases 0(?)
  --dry-run 0(?)
  --lock 0(?)
  --ansi 0(?)
  --no-ansi 0(?)
  -V,--version 0(?)
  -h,--help 0(?)
  -v,--verbose 0(*)
  -q,--quiet 0(?)
  -n,--no-interaction 0(?)
  --no-plugins 0(?)
  --no-cache 0(?)
  -C,--directory 1(?) _filedir -d
install
  --without *(?) _bourbaki_complete_choices '<group-name-to-exclude>'
  --with *(?) _bourbaki_complete_choices '<group-name-to-include>'
  --only *(?) _bourbaki_complete_choices '<group-name-to-include>'
  --sync 0(?)
  --no-root 0(?)
  --dry-run 0(?)
  -E,--extras *(?) _bourbaki_complete_choices '<extras-name>'
  --all-extras 0(?)
  --only-root 0(?)
  --ansi 0(?)
  --no-ansi 0(?)
  -V,--version 0(?)
  -h,--help 0(?)
  -v,--verbose 0(*)
  -q,--quiet 0(?)
  -n,--no-interaction 0(?)
  --no-plugins 0(?)
  --no-cache 0(?)
  -C,--directory 1(?) _filedir -d
build
check
config
  - 1(1) _bourbaki_complete_from_stdout _poetry_config_keys
  - 1(?) _bourbaki_complete_from_stdout _poetry_config_values
  --list 0(?)
export
help
init
list
lock
new
publish
remove
search
shell
show
update
version
about
cache
  clear
  list
debug
  info
  resolve
env
  info
  list
  remove
  use
self
  add
  install
  lock
  remove
  show
    plugins
  update
source
  add
  remove
  show
"""
}

_poetry_config_keys() {
  poetry config --list | cut -f 1 -d ' '
}

_poetry_config_values() {
  poetry config --list | cut -f 3 -d ' '
}

complete -o bashdefault -F _complete_poetry poetry

# `poetry run` alias
alias pr='poetry run'
complete -o bashdefault -F _root_command pr
