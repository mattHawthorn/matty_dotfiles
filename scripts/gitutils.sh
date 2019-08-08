#!/usr/bin/env bash

alias thisbranch='git symbolic-ref --short HEAD'

alias thisremote='git remote show'

alias pushthis='git push $(thisremote) $(thisbranch)'

alias pullthis='git fetch; git merge $(thisremote)/$(thisbranch)'
