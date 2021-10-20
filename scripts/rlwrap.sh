#!/bin/bash

QSH_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

[[ -z "$QSH_RLWRAP_SHELL_COMMAND" ]] && QSH_RLWRAP_SHELL_COMMAND="!>>"
[[ -z "$QSH_RLWRAP_PAGER" ]] && QSH_RLWRAP_PAGER="$QSH_SCRIPTS/qsh-pager"
[[ ! -z "$QSH_PROMPT" ]] && QSH_RLWRAP_PROMPT=-S "$QSH_PROMPT"

QSH_RLWRAP_SHELL_COMMAND="$QSH_RLWRAP_SHELL_COMMAND" \
QSH_RLWRAP_PAGER="$QSH_RLWRAP_PAGER" \
  rlwrap -a -A -m -N -n -C qsh -t dumb -z "$QSH_SCRIPTS/qsh-rlwrap" $QSH_RLWRAP_PROMPT -- $*

