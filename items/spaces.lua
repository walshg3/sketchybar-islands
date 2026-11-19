local colors = require "colors"
colors = colors.sections
local icons = require "icons"
local icon_map = require "helpers.icon_map"

sbar.add("event", "aerospace_workspace_change")
sbar.add("event", "aerospace_focus_change")

-- SketchyBar can start before AeroSpace at login. Retry asynchronously so
-- the other items load while we wait for the workspace list. Give up after
-- MAX_WORKSPACE_ATTEMPTS (about a minute) so a missing AeroSpace doesn't
-- spawn a process every second forever; `sketchybar --reload` tries again.
local MAX_WORKSPACE_ATTEMPTS = 60

local function with_workspaces(callback, attempt)
  attempt = attempt or 1
  sbar.exec("aerospace list-workspaces --all 2>/dev/null", function(spaces)
    if type(spaces) ~= "string" or spaces:match "^%s*$" then
      if attempt >= MAX_WORKSPACE_ATTEMPTS then
        io.stderr:write("spaces: no AeroSpace workspaces after " .. attempt .. " attempts; giving up\n")
        return
      end
      -- A shell delay is safe before the event loop starts; sbar.delay is not.
      sbar.exec("sleep 1", function()
        with_workspaces(callback, attempt + 1)
      end)
      return
    end
    callback(spaces)
  end)
end

with_workspaces(function(spaces)
  local space_items = {}

  for space_name in spaces:gmatch "[^\r\n]+" do
    local space = sbar.add("item", "left.space." .. space_name, {
      position = "left",
      icon = {
        string = space_name,
        color = colors.spaces.idle,
        padding_left = 6,
        padding_right = 4,
      },
      label = {
        font = "sketchybar-app-font-bg:Regular:14.0",
        string = " —",
        color = colors.spaces.glyph,
        y_offset = -1,
        padding_left = 0,
        padding_right = 8,
      },
      background = {
        drawing = false,
        color = colors.spaces.underline,
        height = 2,
        corner_radius = 1,
        y_offset = -14,
      },
      click_script = "aerospace workspace " .. space_name,
      padding_left = space_name == "1" and 0 or 2,
      padding_right = 0,
    })

    local function set_selected(selected)
      space:set {
        icon = { color = selected and colors.spaces.focused or colors.spaces.idle },
        background = { drawing = selected },
      }
    end

    local function update_windows()
      sbar.exec("aerospace list-windows --format %{app-name} --workspace " .. space_name, function(windows)
        local no_app = true
        local icon_line = ""
        for app in windows:gmatch "[^\r\n]+" do
          no_app = false
          local lookup = icon_map[app]
          local icon = lookup == nil and icon_map["default"] or lookup
          icon_line = icon_line .. " " .. icon
        end
        sbar.animate("tanh", 10, function()
          space:set { label = no_app and " —" or icon_line }
        end)
      end)
    end

    space:subscribe("aerospace_workspace_change", function(env)
      set_selected(env.FOCUSED_WORKSPACE == space_name)
      update_windows()
    end)

    space:subscribe("aerospace_focus_change", update_windows)
    space:subscribe("space_windows_change", update_windows)

    space_items[space_name] = {
      set_selected = set_selected,
      update_windows = update_windows,
    }
    update_windows()
  end

  -- Restore visual order (async-created spaces land after mode/menus) and
  -- rebuild the left island so the bracket picks up the new members. One
  -- shell invocation so the moves and the bracket rebuild stay ordered.
  local move_command = "sketchybar"
  for space_name in spaces:gmatch "[^\r\n]+" do
    move_command = move_command .. " --move left.space." .. space_name .. " before left.menus_toggle"
  end
  sbar.exec(move_command .. require("helpers.islands").refresh_command "left")

  sbar.exec("aerospace list-workspaces --focused", function(focused)
    focused = focused:match("^%s*(.-)%s*$")
    for name, item in pairs(space_items) do
      item.set_selected(name == focused)
    end
  end)
end)

local spaces_indicator = sbar.add("item", "left.menus_toggle", {
  position = "left",
  icon = {
    padding_left = 6,
    padding_right = 8,
    string = icons.switch.on,
    color = colors.accent,
  },
  label = {
    drawing = false,
  },
  padding_left = 0,
  padding_right = 4,
})

spaces_indicator:subscribe("swap_menus_and_spaces", function()
  local currently_on = spaces_indicator:query().icon.value == icons.switch.on
  spaces_indicator:set {
    icon = currently_on and icons.switch.off or icons.switch.on,
  }
end)

spaces_indicator:subscribe("mouse.clicked", function()
  sbar.trigger "swap_menus_and_spaces"
end)
