#!/bin/bash

PANE_ID=$1
QSH_SQL_CLIENT=$2
QSH_PAGER_COMMAND=$3
QSH_NO_CHANGE_PROMPT=$4
OSH_PROMPT=$5
OUTPUT_FILE=$6

# Force the pager to be the QSH pager
tmux send-keys -t $PANE_ID "\\P $QSH_PAGER_COMMAND";
tmux send-keys -t $PANE_ID "C-m";

# Change the prompt
if [[ -z "$QSH_NO_CHANGE_PROMPT" ]]; then
  if [[ -z "$QSH_PROMPT" ]]; then
    QSH_PROMPT="mysql://\u@\h:\p/\d";
  fi;

  tmux send-keys -t $PANE_ID "\\R [qsh] $QSH_PROMPT\n>>> ";
  tmux send-keys -t $PANE_ID "C-m";
fi;

# Clear the screen
tmux send-keys -t $PANE_ID "\! clear";
tmux send-keys -t $PANE_ID "C-m";

echo -e "select 'INITIALIZED' as \"qsh ($QSH_SQL_CLIENT)\";" > "$OUTPUT_FILE";

