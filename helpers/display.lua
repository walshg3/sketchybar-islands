local M = {}

local cache_file = "/tmp/sketchybar_display_mode"

-- Detect via AeroSpace monitor names instead of `sketchybar --query displays`:
-- a nested bar query during config load hits a busy bar and fails, while the
-- aerospace CLI is always answerable. Only built-in monitor(s) => notch mode.
local function mode_from_monitors(monitors)
  if type(monitors) ~= "string" or monitors:match "^%s*$" then
    return nil
  end
  for line in monitors:gmatch "[^\r\n]+" do
    if not line:find "Built%-in" then
      return "wide"
    end
  end
  return "notch"
end

function M.detect(callback)
  sbar.exec("/opt/homebrew/bin/aerospace list-monitors --format %{monitor-name}", function(monitors)
    callback(mode_from_monitors(monitors))
  end)
end

function M.mode(callback)
  M.detect(function(mode)
    callback(mode or "wide")
  end)
end

local function refresh(reload_on_change)
  M.detect(function(mode)
    if not mode then
      return
    end
    sbar.exec("cat " .. cache_file .. " 2>/dev/null || true", function(cached)
      cached = type(cached) == "string" and cached:match "^%s*(.-)%s*$" or ""
      if cached == mode then
        return
      end
      sbar.exec("printf '%s' " .. mode .. " > " .. cache_file, function()
        if reload_on_change and cached ~= "" then
          -- Kickstart, not --reload: see items/theme.lua.
          sbar.exec "launchctl kickstart -k gui/$(id -u)/homebrew.mxcl.sketchybar"
        end
      end)
    end)
  end)
end

local watcher = sbar.add("item", "display.mode_watcher", {
  drawing = false,
  updates = true,
})

watcher:subscribe({ "display_change", "system_woke" }, function()
  refresh(true)
end)

refresh(false)

return M
