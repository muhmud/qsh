" Vim plugin for qsh
" Last Change:  2020 Nov 12
" Maintainer:   Muhmud Ahmad
" License:      This file is placed in the public domain.

let s:save_cpo = &cpo
set cpo&vim

" Only do this when not done yet for this buffer
if exists("g:loaded_qsh")
  finish
endif
let g:loaded_qsh = 1

" Script variable(s)
let s:qsh_enabled = $QSH_ENABLE == 1 ? 1 : 0
let s:qsh_keys_mapped = 0

" Buffer variable(s)
let b:command_prefix= ""

function QshApplyDefaultKeyMappings()
  if s:qsh_keys_mapped == 0
    " Alt+e (for execute)
    vnoremap <silent> <unique> <Esc>e :call QshExecuteSelection()<CR>
    vnoremap <silent> <unique> <M-e> :call QshExecuteSelection()<CR>
    vnoremap <silent> <unique> <F5> :call QshExecuteSelection()<CR>
    inoremap <silent> <unique> <Esc>e <C-O>:call QshExecuteLine()<CR>
    inoremap <silent> <unique> <M-e> <C-O>:call QshExecuteLine()<CR>
    inoremap <silent> <unique> <F5> <C-O>:call QshExecuteLine()<CR>
    nnoremap <silent> <unique> <Esc>e :call QshExecuteLine()<CR>
    nnoremap <silent> <unique> <M-e> :call QshExecuteLine()<CR>
    nnoremap <silent> <unique> <F5> :call QshExecuteLine()<CR>

    " Alt+y
    inoremap <silent> <unique> <Esc>y <C-O>:call QshExecuteAll()<CR>
    inoremap <silent> <unique> <M-y> <C-O>:call QshExecuteAll()<CR>
    nnoremap <silent> <unique> <Esc>y :call QshExecuteAll()<CR>
    nnoremap <silent> <unique> <M-y> :call QshExecuteAll()<CR>

    " Alt+g (for go)
    inoremap <silent> <unique> <Esc>g <C-O>:call QshExecute()<CR>
    inoremap <silent> <unique> <M-g> <C-O>:call QshExecute()<CR>
    nnoremap <silent> <unique> <Esc>g :call QshExecute()<CR>
    nnoremap <silent> <unique> <M-g> :call QshExecute()<CR>

    " Alt+G
    inoremap <silent> <unique> <Esc>G <C-O>:call QshExecute("^---$" 0)<CR>
    inoremap <silent> <unique> <M-G> <C-O>:call QshExecute("^---$", 0)<CR>
    nnoremap <silent> <unique> <Esc>G :call QshExecute("^---$", 0)<CR>
    nnoremap <silent> <unique> <M-G> :call QshExecute("^---$", 0)<CR>

    " Alt+p
    vnoremap <silent> <unique> <Esc>p :call QshSetPrefix()<CR>
    vnoremap <silent> <unique> <M-p> :call QshSetPrefix()<CR>
    nnoremap <silent> <unique> <Esc>p :call QshUnsetPrefix()<CR>
    nnoremap <silent> <unique> <M-p> :call QshUnsetPrefix()<CR>
    inoremap <silent> <unique> <Esc>p <C-O>:call QshUnsetPrefix()<CR>
    inoremap <silent> <unique> <M-p> <C-O>:call QshUnsetPrefix()<CR>

    " Alt+d (for describe)
    vnoremap <silent> <unique> <Esc>d :call QshExecuteNamedScriptVisually("describe")<CR>
    vnoremap <silent> <unique> <M-d> :call QshExecuteNamedScriptVisually("describe")<CR>
    nnoremap <silent> <unique> <Esc>d :call QshExecuteNamedScript("describe")<CR>
    nnoremap <silent> <unique> <M-d> :call QshExecuteNamedScript("describe")<CR>
    inoremap <silent> <unique> <Esc>d <C-O>:call QshExecuteNamedScript("describe")<CR>
    inoremap <silent> <unique> <M-d> <C-O>:call QshExecuteNamedScript("describe")<CR>

    " Alt+r (for rows)
    vnoremap <silent> <unique> <Esc>r :call QshExecuteNamedScriptVisually("select-some")<CR>
    vnoremap <silent> <unique> <M-r> :call QshExecuteNamedScriptVisually("select-some")<CR>
    nnoremap <silent> <unique> <Esc>r :call QshExecuteNamedScript("select-some")<CR>
    nnoremap <silent> <unique> <M-r> :call QshExecuteNamedScript("select-some")<CR>
    inoremap <silent> <unique> <Esc>r <C-O>:call QshExecuteNamedScript("select-some")<CR>
    inoremap <silent> <unique> <M-r> <C-O>:call QshExecuteNamedScript("select-some")<CR>

    " Alt+t (for tidy)
    vnoremap <silent> <unique> <Esc>t :call QshExecuteNamedSnippetVisually("format")<CR>
    vnoremap <silent> <unique> <M-t> :call QshExecuteNamedSnippetVisually("format")<CR>

    " Alt+v
    vnoremap <silent> <unique> <Esc>v :call QshExecuteScriptVisually()<CR>
    vnoremap <silent> <unique> <M-v> :call QshExecuteScriptVisually()<CR>
    nnoremap <silent> <unique> <Esc>v :call QshExecuteScript()<CR>
    nnoremap <silent> <unique> <M-v> :call QshExecuteScript()<CR>
    inoremap <silent> <unique> <Esc>v <C-O>:call QshExecuteScript()<CR>
    inoremap <silent> <unique> <M-v> <C-O>:call QshExecuteScript()<CR>

    " Alt+Space
    vnoremap <silent> <unique> <Esc><Space> :call QshExecuteSnippetVisually()<CR>
    vnoremap <silent> <unique> <M-Space> :call QshExecuteSnippetVisually()<CR>
    nnoremap <silent> <unique> <Esc><Space> :call QshExecuteSnippet()<CR>
    nnoremap <silent> <unique> <M-Space> :call QshExecuteSnippet()<CR>
    inoremap <silent> <unique> <Esc><Space> <C-O>:call QshExecuteSnippet()<CR>
    inoremap <silent> <unique> <M-Space> <C-O>:call QshExecuteSnippet()<CR>

    let s:qsh_keys_mapped = 1
  endif
endfunction

function QshEnable()
  let s:qsh_enabled = 1
  if g:qsh_enable_key_mappings == 1
    call QshApplyDefaultKeyMappings()
  endif
endfunction

command QshEnable :call QshEnable()

function QshDisable()
  let s:qsh_enabled = 0
endfunction

command QshDisable :call QshDisable()

" By default, keys will be mapped
if !exists("g:qsh_enable_key_mappings")
  let g:qsh_enable_key_mappings=1
endif

if s:qsh_enabled == 1
  call QshEnable()
endif

function s:FindNonVisualLineRange(delimiter, includeDelimiter)
  let current_char = matchstr(getline('.'), '\%' . col('.') . 'c.')
  if current_char == a:delimiter
    normal h
  endif

  " Search for the previous delimiter
  let [ previousLine, previousPos ] = searchpos(a:delimiter, "bnWe")

  " If no delimiter was found, use the start of the document
  if previousLine == 0 && previousPos == 0
    let previousLine = 1
    let previousPos = 0
  endif

  " Search forwards for the next delimiter
  let [ nextLine, nextPos ] = searchpos(a:delimiter, "nW" .. (a:includeDelimiter == 1 ? "e" : ""))

  " If no delimiter was found, use the end of the document
  if nextLine == 0 && nextPos == 0
    let nextLine = line('$')
    let nextPos = col([ nextLine, col('$') ])
  elseif nextPos == 1 && a:includeDelimiter == 0
    let nextLine -= 1
    let nextPos = col([ nextLine, col('$') ])
  endif

  if current_char == a:delimiter
    normal l
  endif

  let rangeStart = getpos(".")
  let rangeStart[1] = previousLine
  let rangeStart[2] = previousPos

  let rangeEnd = getpos(".")
  let rangeEnd[1] = nextLine
  let rangeEnd[2] = nextPos

  return [ rangeStart, rangeEnd ]
endfunction

function s:FindNonVisualLines(delimiter, includeDelimiter)
  let [ rangeStart, rangeEnd ] = s:FindNonVisualLineRange(a:delimiter, a:includeDelimiter)

  " Get the lines and adjust appropriately for the required position range
  let lines = getline(rangeStart[1], rangeEnd[1])
  let lines[0] = lines[0][rangeStart[2]:]

  return lines
endfunction

function s:FindVisualLines()
  " Get the start and end of the range
  let rangeStart = getpos("'<")
  let rangeEnd = getpos("'>")

  let lines = getline(rangeStart[1], rangeEnd[1])
  let lines[0] = lines[0][rangeStart[2]-1:]
  let lines[-1] = lines[-1][:rangeEnd[2] - rangeStart[2]]

  return lines
endfunction

function s:FindTargetRange()
  " Set range start/end to the current position
  let rangeStart = getpos(".")
  let rangeEnd = getpos(".")

  let [ matchLine, matchPos ] = searchpos("[^A-Za-z0-9_.-]", "bne", line("."))
  if matchLine != 0 
    let rangeStart[1] = matchLine
    let rangeStart[2] = matchPos + 1
  else
    let rangeStart[2] = 1
  endif

  let [ matchLine, matchPos ] = searchpos("[^A-Za-z0-9_.-]", "n", line("."))
  if matchLine != 0 
    let rangeEnd[1] = matchLine
    let rangeEnd[2] = matchPos - rangeStart[2]
  else
    let rangeEnd[2] = col([ rangeEnd[1], "$" ])
  endif

  return [ rangeStart, rangeEnd ]
endfunction

function s:FindTarget()
  let [ rangeStart, rangeEnd ] = s:FindTargetRange()

  let lines = getline(rangeStart[1], rangeEnd[1])
  let lines[0] = lines[0][rangeStart[2]-1:]
  let lines[-1] = lines[-1][:rangeEnd[2]-1]

  return lines
endfunction

function s:VisuallySelectRange(rangeStart, rangeEnd)
  call setpos(".", a:rangeStart)
  normal v
  call setpos(".", a:rangeEnd)
endfunction

function QshSetPrefix()
  if s:qsh_enabled != 1
    return
  endif

  echo
  normal gv

  let b:command_prefix = join(s:FindVisualLines())
  echo "Qsh: Prefix Set - " .. b:command_prefix
endfunction

function QshUnsetPrefix()
  if s:qsh_enabled != 1
    return
  endif

  let b:command_prefix = ""
  echo "Qsh: Prefix Unset"
endfunction

function QshExecute(delimiter = ";", includeDelimiter = 1)
  if s:qsh_enabled != 1
    return
  endif

  " Add prefix if it's been set
  let lines = s:FindNonVisualLines(a:delimiter, a:includeDelimiter)
  if b:command_prefix != ""
    let lines[0] = b:command_prefix .. " " .. lines[0]
  endif

  " Write to the requested file
  call writefile(s:FindNonVisualLines(a:delimiter, a:includeDelimiter), $QSH_EXECUTE_QUERY)

  echo "Qsh: Sending Query >>>"
  call system($QSH)
endfunction

function QshExecuteSelection() range
  if s:qsh_enabled != 1
    return
  endif

  echo
  normal gv

  " Add prefix if it's been set
  let lines = s:FindVisualLines()
  if b:command_prefix != ""
    let lines[0] = b:command_prefix .. " " .. lines[0]
  endif

  " Write to the requested file
  call writefile(s:FindVisualLines(), $QSH_EXECUTE_QUERY, "b")

  echo "Qsh: Sending Query >>>"
  call system($QSH)
endfunction

function QshExecuteLine()
  if s:qsh_enabled != 1
    return
  endif

  " Add prefix if it's been set
  let line = getline(".")
  if b:command_prefix != ""
    let line = b:command_prefix .. " " .. line
  endif

  " Write to the requested file
  call writefile([ line ], $QSH_EXECUTE_QUERY, "b")

  echo "Qsh: Sending Query >>>"
  call system($QSH)
endfunction

function QshExecuteAll()
  if s:qsh_enabled != 1
    return
  endif

  " Write to the requested file
  call writefile(getline(1, line('$')), $QSH_EXECUTE_QUERY)

  echo "Qsh: Sending Script >>>"
  call system($QSH)
endfunction

function s:ExecuteScript(script)
  let message = "Qsh: " . a:script . " >>>"

  let result = system("$QSH scripts " . shellescape(a:script))
  if v:shell_error != 0
    echo message .. " " .. result
  else
    echo message
  endif
endfunction

function QshExecuteScript()
  if s:qsh_enabled != 1
    return
  endif

  echo

  " Write to the requested file
  let script = join(s:FindTarget())

  " Execute the script
  call s:ExecuteScript(script)
endfunction

function QshExecuteScriptVisually() range
  if s:qsh_enabled != 1
    return
  endif

  echo
  normal gv

  let script = join(s:FindVisualLines())

  " Execute the script
  call s:ExecuteScript(script)
endfunction

function QshExecuteNamedScript(script)
  if s:qsh_enabled != 1
    return
  endif

  echo

  " Write to the requested file
  call writefile(s:FindTarget(), $QSH_EXECUTE_QUERY)

  " Execute the script
  call s:ExecuteScript(a:script)
endfunction

function QshExecuteNamedScriptVisually(script) range
  if s:qsh_enabled != 1
    return
  endif

  echo
  normal gv

  " Write to the requested file
  call writefile(s:FindVisualLines(), $QSH_EXECUTE_QUERY)

  " Execute the script
  call s:ExecuteScript(a:script)
endfunction

function QshExecuteNamedScriptNonVisually(script, delimiter = ";", includeDelimiter = 1)
  if s:qsh_enabled != 1
    return
  endif

  echo

  " Write to the requested file
  call writefile(s:FindNonVisualLines(a:delimiter, a:includeDelimiter), $QSH_EXECUTE_QUERY)

  " Execute the script
  call s:ExecuteScript(a:script)
endfunction

function s:ExecuteSnippet(snippet, rangeStart, rangeEnd)
  let lines = getline(a:rangeStart[1], a:rangeEnd[1])

  let snippet = a:snippet
  if snippet == ""
    let endRange = a:rangeEnd[2] - a:rangeStart[2] 
    if strpart(lines[-1], a:rangeEnd[2] - 1, 1) == ")"
      let endRange += 1
    endif
  else
    let endRange = a:rangeEnd[2] - 1
  endif

  " Store the parts of the lines that we need to keep
  let lineStart = strpart(lines[0], 0, a:rangeStart[2] - 1)
  let lineEnd = strpart(lines[-1], a:rangeEnd[2])

  " Amend the selection so that we only have the selected part
  let lines[0] = strpart(lines[0], a:rangeStart[2] - 1)
  let lines[-1] = strpart(lines[-1], 0, endRange)

  " Handle named snippets
  if (snippet == "")
    let snippet = join(lines)
  else
    " Write to the requested file
    call writefile(lines, $QSH_EXECUTE_QUERY)
  endif

  " Display a message to the user
  let message = "Qsh: *" . snippet . " >>>"

  let result = system("$QSH snippets " . shellescape(snippet))
  if v:shell_error != 0
    echo message .. " " .. result
  else
    echo message

    " Prepare the results
    let result = split(result, '\n')[:-1]
    if (len(result) > 0)
      let result_column = len(result) == 1 ? len(lineStart) + len(result[0]) : len(result[-1])

      let result[0] = lineStart . result[0]
      let result[-1] = result[-1] . lineEnd

      exec 'normal "_d'
      let result_length = len(result)
      let i = 0
      while i < result_length
        if i == 0 || i + 1 == result_length
          call setline(a:rangeStart[1] + i, result[i])
        else
          call append(a:rangeStart[1] + i - 1, result[i])
        endif

        let i += 1
      endwhile

      " Position the cursor at the end of the snippet
      call setpos(".", [ a:rangeStart[0], a:rangeStart[1] + len(result) - 1, result_column + 1, a:rangeStart[3] ])
    endif
  endif
endfunction

function QshExecuteSnippet()
  if s:qsh_enabled != 1
    return
  endif

  echo

  " Set range start/end to the current position
  let rangeStart = getpos(".")
  let rangeEnd = getpos(".")
  let snippet = ''

  let [ matchLine, matchPos ] = searchpos("[^(\t ]\\+\\s*([^()]*)", "bn", line("."))
  if matchLine != 0 
    let rangeStart[1] = matchLine
    let rangeStart[2] = matchPos
  endif

  let [ matchLine, matchPos ] = searchpos(")", "ne", line("."))
  if matchLine != 0 
    let rangeEnd[1] = matchLine
    let rangeEnd[2] = matchPos
  else
    let [ matchLine, matchPos ] = searchpos(")", "bne", line("."))
    if matchLine != 0 
      let rangeEnd[1] = matchLine
      let rangeEnd[2] = matchPos
    endif
  endif

  call s:VisuallySelectRange(rangeStart, rangeEnd)
  call s:ExecuteSnippet("", rangeStart, rangeEnd)
endfunction

function QshExecuteSnippetVisually() range
  if s:qsh_enabled != 1
    return
  endif

  echo
  normal gv

  " Get the start and end of the range
  let rangeStart = getpos("'<")
  let rangeEnd = getpos("'>")

  call s:ExecuteSnippet("", rangeStart, rangeEnd)
endfunction

function QshExecuteNamedSnippet(snippet)
  if s:qsh_enabled != 1
    return
  endif

  echo

  " Find the target range
  let [ rangeStart, rangeEnd ] = s:FindTargetRange()

  call s:VisuallySelectRange(rangeStart, rangeEnd)
  call s:ExecuteSnippet(a:snippet, rangeStart, rangeEnd)
endfunction

function QshExecuteNamedSnippetVisually(snippet) range
  if s:qsh_enabled != 1
    return
  endif

  echo
  normal gv

  " Get the start and end of the range
  let rangeStart = getpos("'<")
  let rangeEnd = getpos("'>")

  call s:ExecuteSnippet(a:snippet, rangeStart, rangeEnd)
endfunction

function QshExecuteNamedSnippetNonVisually(snippet, delimiter = ";", includeDelimiter = 1)
  if s:qsh_enabled != 1
    return
  endif

  echo

  " Get the start and end of the range
  let [ rangeStart, rangeEnd ] = s:FindNonVisualLineRange(a:delimiter, a:includeDelimiter)

  call s:VisuallySelectRange(rangeStart, rangeEnd)
  call s:ExecuteSnippet(a:snippet, rangeStart, rangeEnd)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

