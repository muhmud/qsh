#!/bin/bash

PANE_ID=$1
QSH_SQL_CLIENT=$2
OUTPUT_FILE=$3

echo -e "select 'INITIALIZED' as \"qsh ($QSH_SQL_CLIENT)\";" > "$OUTPUT_FILE";

