
local micro = import("micro")
local shell = import("micro/shell")
local ioutil = import("io/ioutil")

local QSH_EXECUTE_QUERY = os.getenv("QSH_EXECUTE_QUERY")
local QSH = os.getenv("QSH")

function ExecuteSelection(bp)
  if bp.Buf:FileType() ~= "sql" then
    return true
  end

  local cursor = bp.Buf:GetActiveCursor()
  if cursor and cursor:HasSelection() then
    ioutil.WriteFile(QSH_EXECUTE_QUERY, cursor:GetSelection(), 438)

    micro.InfoBar():Message("Qsh: Sending Query >>>")
    shell.ExecCommand(QSH)
  end
end

