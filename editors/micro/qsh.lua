
local micro = import("micro")
local config = import("micro/config")
local buffer = import("micro/buffer")
local shell = import("micro/shell")
local util = import("micro/util")
local ioutil = import("io/ioutil")

local QSH_EXECUTE_QUERY = os.getenv("QSH_EXECUTE_QUERY")
local QSH = os.getenv("QSH")

------------------------------------------------------------------------------------------------
-- Plugin Hooks
------------------------------------------------------------------------------------------------

function init()
  config.MakeCommand("QshExecute", QshExecute, config.NoComplete)
  config.MakeCommand("QshExecuteSelection", ExecuteSelection, config.NoComplete)
  config.MakeCommand("QshExecuteAll", ExecuteAll, config.NoComplete)
  config.MakeCommand("QshExecuteClientQuery", QshExecuteClientQuery, config.NoComplete)
  config.MakeCommand("QshExecuteNamedClientQuery", ExecuteNamedClientQuery, config.NoComplete)
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

function QshExecuteClientQuery(bp, args)
  ExecuteClientQuery(bp, args[1])
end

------------------------------------------------------------------------------------------------
-- Functions
------------------------------------------------------------------------------------------------

function Execute(bp, delimiter, includeDelimiter)
  if bp.Buf:FileType() ~= "sql" then
    return
  end

  -- Parameter defaults
  delimiter = delimiter or ";"
  includeDelimiter = tonumber(includeDelimiter) or 1

  local cursor = bp.Buf:GetActiveCursor()
  if cursor and not cursor:HasSelection() then
    -- Store the current position of the cursor
    local cursorLoc = buffer.Loc(cursor.Loc.X, cursor.Loc.Y)

    -- Find the previous and next instances of the delimiter
    local previousDelimiter = bp.Buf:FindNext(delimiter, bp.Buf:Start(), cursorLoc, cursorLoc, false, false)
    local nextDelimiter = bp.Buf:FindNext(delimiter, cursorLoc, bp.Buf:End(), cursorLoc, true, false)

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

    -- Write the output file
    ioutil.WriteFile(QSH_EXECUTE_QUERY, bp.Buf:Substr(start, finish), 438)

    -- Call back into qsh
    micro.InfoBar():Message("Qsh: Sending Query >>>")
    shell.ExecCommand(QSH)
  end
end

function ExecuteSelection(bp)
  if bp.Buf:FileType() ~= "sql" then
    return
  end

  local cursor = bp.Buf:GetActiveCursor()
  if cursor and cursor:HasSelection() then
    -- Write the output file
    ioutil.WriteFile(QSH_EXECUTE_QUERY, cursor:GetSelection(), 438)

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
  micro.InfoBar():Message("Qsh: Sending Script >>>")
  shell.ExecCommand(QSH)
end

function ExecuteClientQuery(bp, query)
  if bp.Buf:FileType() ~= "sql" then
    return
  end

  local cursor = bp.Buf:GetActiveCursor()
  if cursor and cursor:HasSelection() then
    -- Write the output file
    ioutil.WriteFile(QSH_EXECUTE_QUERY, cursor:GetSelection(), 438)
  end

  -- Call back into qsh
  micro.InfoBar():Message("Qsh: " .. query .. " >>>")
  shell.ExecCommand(QSH, "client-query", query);
end

function ExecuteNamedClientQuery(bp)
  if bp.Buf:FileType() ~= "sql" then
    return
  end

  local cursor = bp.Buf:GetActiveCursor()
  if cursor and cursor:HasSelection() then
    local query = util.String(cursor:GetSelection())

    -- Call back into qsh
    micro.InfoBar():Message("Qsh: " .. query .. " >>>")
    shell.ExecCommand(QSH, "client-query", query);
  end
end
