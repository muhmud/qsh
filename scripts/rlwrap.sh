#!/bin/bash

which rlwrap > /dev/null 2>&1;
if [[ $? -ne 0 ]]; then
  echo "Could not find rlwrap, which is needed to make this connection";
  exit -1;
fi;

which perl > /dev/null 2>&1;
if [[ $? -ne 0 ]]; then
  echo "Could not find perl, which is needed for rlwrap connections";
  exit -1;
fi;

QSH_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
QSH_TMP=/tmp/qsh

PANE_ID=$(tmux display-message -p '#{pane_id}')
CLIENT_PANE=$QSH_TMP/client.${PANE_ID}

[[ -z "$QSH_RLWRAP_SHELL_COMMAND" ]] && QSH_RLWRAP_SHELL_COMMAND="!>>"
[[ -z "$QSH_RLWRAP_PAGER" ]] && QSH_RLWRAP_PAGER="$QSH_SCRIPTS/qsh-pager"
[[ ! -z "$QSH_PROMPT" ]] && QSH_RLWRAP_PROMPT=-S "$QSH_PROMPT"

QSH_RLWRAP_SHELL_COMMAND="$QSH_RLWRAP_SHELL_COMMAND" \
QSH_RLWRAP_PAGER="$QSH_RLWRAP_PAGER" \
QSH_RLWRAP_CLIENT_PANE="$CLIENT_PANE" \
QSH_FILE_TYPE="$QSH_FILE_TYPE" \
  rlwrap -a -A -m -N -n -C qsh -t dumb -z "$QSH_SCRIPTS/qsh-rlwrap" $QSH_RLWRAP_PROMPT -- $*

