local icons = require "icons"
local theme = require "colors"
local colors = theme.sections.brew

local brew = sbar.add("item", "right.brew", {
  position = "right",
  drawing = false,
  updates = true, -- default when_shown never wakes a hidden item
  update_freq = 21600,
  icon = {
    string = icons.gear,
    color = colors.icon,
  },
  label = { string = "0" },
  background = { drawing = false },
  popup = { align = "center" },
})

local function clear_popup()
  sbar.remove "/brew.outdated\\.*/"
end

local function set_count(count)
  local color = count >= 10 and colors.alert or colors.icon
  brew:set {
    drawing = count > 0,
    icon = { color = color },
    label = { string = tostring(count), color = color },
  }
end

local function refresh_count()
  sbar.exec(
    [[/usr/bin/python3 -c "import signal, subprocess; signal.signal(signal.SIGCHLD, signal.SIG_DFL); out = subprocess.run(['/opt/homebrew/bin/brew', 'outdated', '--quiet'], capture_output=True, text=True, check=True).stdout; print(sum(1 for line in out.splitlines() if line.strip()))"]],
    function(output)
      set_count(tonumber(output) or 0)
    end
  )
end

local function refresh_popup(show_popup)
  sbar.exec(
    [[/usr/bin/python3 -c "import signal, subprocess; signal.signal(signal.SIGCHLD, signal.SIG_DFL); print(subprocess.run(['/opt/homebrew/bin/brew', 'outdated', '--quiet'], capture_output=True, text=True, check=True).stdout, end='')"]],
    function(output)
      local packages = {}
      for package in output:gmatch "[^\r\n]+" do
        packages[#packages + 1] = package
      end

      local count = #packages
      set_count(count)
      brew:set { popup = { drawing = count > 0 and show_popup or false } }

      clear_popup()
      if not show_popup then
        return
      end

      for index = 1, math.min(count, 10) do
        sbar.add("item", "brew.outdated." .. index, {
          position = "popup." .. brew.name,
          label = { string = packages[index] },
          icon = { drawing = false },
          background = { drawing = false },
        })
      end
    end
  )
end

brew:subscribe({ "routine", "system_woke" }, function()
  refresh_count()
end)

-- First check at config load; the routine tick is up to 6h away.
refresh_count()

brew:subscribe("mouse.clicked", function()
  local show_popup = brew:query().popup.drawing == "off"
  refresh_popup(show_popup)
end)
