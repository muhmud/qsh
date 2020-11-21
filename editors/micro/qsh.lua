
local micro = import("micro")
local buffer = import("micro/buffer")
local shell = import("micro/shell")
local util = import("micro/util")
local ioutil = import("io/ioutil")

local QSH_EXECUTE_QUERY = os.getenv("QSH_EXECUTE_QUERY")
local QSH = os.getenv("QSH")

function Execute(bp, delimiter, includeDelimiter)
  if bp.Buf:FileType() ~= "sql" then
    return true
  end

  -- Parameter defaults
  delimiter = delimiter or ";"
  includeDelimiter = includeDelimiter or 0

  -- Other variable(s)
  local delimiterLength = string.len(delimiter)

  local cursor = bp.Buf:GetActiveCursor()
  if cursor and not cursor:HasSelection() then
    -- Store the current position of the cursor
    local cursorLoc = buffer.Loc(cursor.Loc.X, cursor.Loc.Y)

    -- Find the previous and next instances of the delimiter
    local previousDelimiter = bp.Buf:FindNext(delimiter, bp.Buf:Start(), cursorLoc, cursorLoc, false, false)
    local nextDelimiter = bp.Buf:FindNext(delimiter, cursorLoc, bp.Buf:End(), cursorLoc, true, false)

    -- Ensure we don't include the previous instance of the delimiter, unless we didn't find
    -- the delimiter, so we would start from the beginning of the document
    local start = previousDelimiter[1]
    if start.X ~= 0 and start.Y ~= 0 then
      start = buffer.Loc(start.X + delimiterLength, start.Y);
    end

    -- If we didn't find the delimiter when searching forward, we will go to the end of the
    -- document. If we did find it, we need to include the delimiter in the output if we are
    -- configured to
    local finish = nextDelimiter[1]
    if finish.X == 0 and finish.Y == 0 then
      finish = bp.Buf:End()
    elseif includeDelimiter == 1 then
      finish = buffer.Loc(finish.X + delimiterLength, finish.Y)
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
    return true
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
    return true
  end

  -- Write the output file    
  ioutil.WriteFile(QSH_EXECUTE_QUERY, bp.Buf:Substr(bp.Buf:Start(), bp.Buf:End()), 438)

  -- Call back into qsh
  micro.InfoBar():Message("Qsh: Sending Script >>>")
  shell.ExecCommand(QSH)
end

