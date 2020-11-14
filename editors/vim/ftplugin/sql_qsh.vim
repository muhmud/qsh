" Vim plugin for qsh
" Last Change:  2020 Nov 12
" Maintainer:   Muhmud Ahmad
" License:      This file is placed in the public domain.

let s:save_cpo = &cpo
set cpo&vim

" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

function QshExecuteSelection() range
  echo
  normal gv

  " Get the start and end of the ranges
  let rangeStart = getpos("'<")
  let rangeEnd = getpos("'>")

  if rangeStart != rangeEnd
    let lines = getline(rangeStart[1], rangeEnd[1])

    let lines[0] = lines[0][rangeStart[2]-1:]
    let lines[-1] = lines[-1][:rangeEnd[2]-1]

    " Write to the requested file
    call writefile(lines, $QSH_EXECUTE_QUERY)

    echo "Qsh: Sending Query >>>"
    call system($QSH)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

