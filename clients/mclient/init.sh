#!/bin/bash

PANE_ID=$1
QSH_SQL_CLIENT=$2
QSH_PAGER_COMMAND=$3
QSH_NO_CHANGE_PROMPT=$4
OSH_PROMPT=$5
OUTPUT_FILE=$6

echo -e "select 'INITIALIZED' as \"qsh ($QSH_SQL_CLIENT)\";" > "$OUTPUT_FILE";
tmux send-keys -t "$PANE_ID" "C-m";

