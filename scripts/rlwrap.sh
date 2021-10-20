#!/bin/bash

QSH_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

rlwrap -a -A -m -N -n -C qsh -t dumb -z "$QSH_SCRIPTS/qsh-rlwrap" -- $*

