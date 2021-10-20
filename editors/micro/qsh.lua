
local micro = import("micro")
local config = import("micro/config")
local buffer = import("micro/buffer")
local shell = import("micro/shell")
local util = import("micro/util")
local ioutil = import("io/ioutil")

local QSH_EXECUTE_QUERY = os.getenv("QSH_EXECUTE_QUERY")
local QSH_EXECUTE_QUERY_CURSOR = os.getenv("QSH_EXECUTE_QUERY_CURSOR")

local QSH = os.getenv("QSH")

------------------------------------------------------------------------------------------------
-- Plugin Hooks
------------------------------------------------------------------------------------------------

function init()
  config.MakeCommand("QshExecute", QshExecute, config.NoComplete)
  config.MakeCommand("QshExecuteSelection", ExecuteSelection, config.NoComplete)
  config.MakeCommand("QshExecuteAll", ExecuteAll, config.NoComplete)
  config.MakeCommand("QshExecuteScript", ExecuteScript, config.NoComplete)
  config.MakeCommand("QshExecuteNamedScript", QshExecuteNamedScript, config.NoComplete)
  config.MakeCommand("QshExecuteSnippet", ExecuteSnippet, config.NoComplete)
  config.MakeCommand("QshExecuteNamedSnippet", QshExecuteNamedSnippet, config.NoComplete)
end

------------------------------------------------------------------------------------------------
-- Command Adaptors (where required)
------------------------------------------------------------------------------------------------

function QshExecute(bp, args)
  Execute(bp,
    #args > 0 and args[1],
    #args > 1 and args[2]
  )
end

function QshExecuteNamedScript(bp, args)
  ExecuteNamedScript(bp, args[1])
end

function QshExecuteNamedSnippet(bp, args)
  ExecuteNamedSnippet(bp, args[1],
    #args > 1 and args[2],
    #args > 2 and args[3]
  )
end

function QshExecuteCompletion(bp, args)
  ExecuteNamedSnippet(bp,
    #args > 0 and args[1],
    #args > 1 and args[2]
  )
end

------------------------------------------------------------------------------------------------
-- Functions
------------------------------------------------------------------------------------------------

function FindDelimitedTarget(bp, delimiter, includeDelimiter, setSelection)
  -- Parameter defaults
  delimiter = delimiter or ";"
  includeDelimiter = tonumber(includeDelimiter) or 1
  setSelection = tonumber(setSelection) or 0

  local cursor = bp.Buf:GetActiveCursor()
  if cursor and not cursor:HasSelection() then
    -- Store the current position of the cursor
    local cursorLoc = buffer.Loc(cursor.Loc.X, cursor.Loc.Y)

    -- Find the previous and next instances of the delimiter
    local previousDelimiter = bp.Buf:FindNext(delimiter, bp.Buf:Start(), cursorLoc, cursorLoc, false, true)
    local nextDelimiter = bp.Buf:FindNext(delimiter, cursorLoc, bp.Buf:End(), cursorLoc, true, true)

    -- Ensure we don't include the previous instance of the delimiter
    local start = previousDelimiter[2]

    -- If we didn't find the delimiter when searching forward, we will go to the end of the
    -- document. If we did find it, we need to include the delimiter in the output if we are
    -- configured to do so
    local finish = nextDelimiter[2]
    if finish.X == 0 and finish.Y == 0 then
      finish = bp.Buf:End()
    elseif includeDelimiter == 0 then
      finish = nextDelimiter[1]
    end

    if setSelection == 1 then
      cursor:SetSelectionStart(start)
      cursor:SetSelectionEnd(finish)
    end

    return bp.Buf:Substr(start, finish)
  end

  return cursor:GetSelection()
end

function FindScriptTarget(bp)
  local cursor = bp.Buf:GetActiveCursor()
  if cursor and not cursor:HasSelection() then
    -- Store relevant cursor positions
    local cursorLoc = buffer.Loc(cursor.Loc.X, cursor.Loc.Y)
    local startLoc = buffer.Loc(0, cursor.Loc.Y)
    local endLoc = buffer.Loc(string.len(util.String(bp.Buf:LineBytes(cursor.Loc.Y))), cursor.Loc.Y)

    -- Find the previous and next instances of the target delimiter
    local targetDelimiter = "[^A-Za-z0-9_.-]"
    local targetStart = bp.Buf:FindNext(targetDelimiter, startLoc, cursorLoc, cursorLoc, false, true)
    local targetEnd = bp.Buf:FindNext(targetDelimiter, cursorLoc, endLoc, cursorLoc, true, true)

    -- If the target start was not found, use the first position on the line
    local start = targetStart[2]
    if start.X == 0 and start.Y == 0 then
      start = startLoc
    end

    -- If the target end was not found, use the end of the line
    local finish = targetEnd[1]
    if finish.X == 0 and finish.Y == 0 then
      finish = endLoc
    end

    micro.InfoBar():Message("this: " .. util.String(bp.Buf:Substr(start, finish)))
    return bp.Buf:Substr(start, finish)
  end

  return cursor:GetSelection()
end

function FindSnippetTarget(bp)
  local cursor = bp.Buf:GetActiveCursor()
  if cursor and not cursor:HasSelection() then
    -- Store relevant cursor positions
    local cursorLoc = buffer.Loc(cursor.Loc.X, cursor.Loc.Y)
    local startLoc = buffer.Loc(0, cursor.Loc.Y)
    local endLoc = buffer.Loc(string.len(util.String(bp.Buf:LineBytes(cursor.Loc.Y))), cursor.Loc.Y)

    -- Find the previous and next instances of the target delimiter
    local targetDelimiter = "[^(\\s]+\\s*\\([^()]*\\)"
    local targetStart = bp.Buf:FindNext(targetDelimiter, startLoc, endLoc, cursorLoc, false, true)

    -- If the target start was not found, use the current cursor position
    local start = targetStart[1]
    if start.X == 0 and start.Y == 0 then
      start = cursorLoc
    end

    local targetEnd = bp.Buf:FindNext("\\)", cursorLoc, endLoc, cursorLoc, true, true)

    -- If the target end was not found, try to search backwards
    local finish = targetEnd[2]
    if finish.X == 0 and finish.Y == 0 then
      targetEnd = bp.Buf:FindNext("\\)", startLoc, cursorLoc, cursorLoc, false, true)

      -- If we still don't find it, use the current cursor position
      finish = targetEnd[2]
      if finish.X == 0 and finish.Y == 0 then
        finish = cursorLoc
      end
    end

    cursor:SetSelectionStart(start)
    cursor:SetSelectionEnd(finish)
  end

  return cursor:GetSelection()
end

function Execute(bp, delimiter, includeDelimiter)
  if bp.Buf:FileType() ~= "sql" then
    return
  end

  -- Write the output file
  ioutil.WriteFile(QSH_EXECUTE_QUERY, FindDelimitedTarget(bp, delimiter, includeDelimiter), 438)

  -- Call back into qsh
  micro.InfoBar():Message("Qsh: Sending Query >>>")
  shell.ExecCommand(QSH)
end

function ExecuteSelection(bp, delimiter, includeDelimiter)
  if bp.Buf:FileType() ~= "sql" then
    return
  end

  local cursor = bp.Buf:GetActiveCursor()
  if cursor then
    if cursor:HasSelection() then
      -- Write the output file
      ioutil.WriteFile(QSH_EXECUTE_QUERY, cursor:GetSelection(), 438)
    else
      -- Get the current line
      local currentLine = util.String(bp.Buf:LineBytes(cursor.Loc.Y))

      -- Write the output file
      ioutil.WriteFile(QSH_EXECUTE_QUERY, currentLine, 438)
    end

    -- Call back into qsh
    micro.InfoBar():Message("Qsh: Sending Query >>>")
    shell.ExecCommand(QSH)
  end
end

function ExecuteAll(bp)
  if bp.Buf:FileType() ~= "sql" then
    return
  end

  -- Write the output file
  ioutil.WriteFile(QSH_EXECUTE_QUERY, bp.Buf:Substr(bp.Buf:Start(), bp.Buf:End()), 438)

  -- Call back into qsh
  micro.InfoBar():Message("Qsh: Sending >>>")
  shell.ExecCommand(QSH)
end

function ExecuteNamedScript(bp, script)
  if bp.Buf:FileType() ~= "sql" then
    return
  end

  -- Write the output file
  ioutil.WriteFile(QSH_EXECUTE_QUERY, FindScriptTarget(bp), 438)

  -- Call back into qsh
--  micro.InfoBar():Message("Qsh: " .. script .. " >>>")
  shell.ExecCommand(QSH, "scripts", script);
end

function ExecuteScript(bp)
  if bp.Buf:FileType() ~= "sql" then
    return
  end

  local script = string.gsub(util.String(FindScriptTarget(bp)), "\n", " ")

  -- Call back into qsh
  micro.InfoBar():Message("Qsh: " .. script .. " >>>")
  shell.ExecCommand(QSH, "scripts", script);
end

function ExecuteSnippet(bp)
  if bp.Buf:FileType() ~= "sql" then
    return
  end

  local cursor = bp.Buf:GetActiveCursor()
  local snippet = util.String(FindSnippetTarget(bp))

  if snippet ~= "" then
    -- Display a status message
    local message = "Qsh: *" .. snippet .. " >>>"
    micro.InfoBar():Message(message)

    -- Call back into qsh
    local result, err = shell.ExecCommand(QSH, "snippets", snippet)
    if err ~= nil then
      micro.InfoBar():Error(message .. " " .. result)
      return
    end

    -- Remove the last newline from the result
    result = string.sub(result, 1, string.len(result) - 1)

    if string.len(result) > 0 then
      cursor:DeleteSelection();
      bp.Buf:Insert(buffer.Loc(cursor.Loc.X, cursor.Loc.Y), result)
    end
  end
end

function ExecuteNamedSnippet(bp, snippet, delimiter, includeDelimiter)
  if bp.Buf:FileType() ~= "sql" then
    return
  end

  local cursor = bp.Buf:GetActiveCursor()

  -- Parameter defaults
  delimiter = delimiter or ";"
  includeDelimiter = tonumber(includeDelimiter) or 1

  FindDelimitedTarget(bp, delimiter, includeDelimiter, 1)

  -- Write the output file
  ioutil.WriteFile(QSH_EXECUTE_QUERY, cursor:GetSelection(), 438)

  -- Write the cursor position to a file
  ioutil.WriteFile(QSH_EXECUTE_QUERY_CURSOR, "{ " .. cursor.Loc.X .. ", " .. (cursor.Loc.Y - cursor.CurSelection[1].Y) .. " }", 438)

  -- Display a status message
  local message = "Qsh: @" .. snippet .. " >>>"

  -- Call back into qsh
  local result, err = shell.ExecCommand(QSH, "snippets", snippet)
  if err ~= nil then
    micro.InfoBar():Error(message .. " " .. result)
    return
  else
    micro.InfoBar():Message(message)
  end

  -- Remove the last newline from the result
  result = string.sub(result, 1, string.len(result) - 1)

  if string.len(result) > 0 then
    cursor:DeleteSelection();
    bp.Buf:Insert(buffer.Loc(cursor.Loc.X, cursor.Loc.Y), result)
  end
end

