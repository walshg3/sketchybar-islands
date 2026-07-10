local colors = require "colors"
colors = colors.sections.mode

sbar.add("event", "aerospace_mode_change")

local mode_item = sbar.add("item", "left.mode", {
  position = "left",
  drawing = false,
  updates = true, -- default when_shown never wakes a hidden item
  icon = { drawing = false },
  label = {
    color = colors.other,
    padding_left = 6,
    padding_right = 10,
  },
})

local function set_mode(mode)
  mode = mode and mode:match("^%s*(.-)%s*$") or "main"
  mode_item:set {
    drawing = mode ~= "main" and mode ~= "",
    label = {
      string = "[" .. mode .. "]",
      color = mode == "main" and colors.main or colors.other,
    },
  }
end

mode_item:subscribe("aerospace_mode_change", function(env)
  set_mode(env.MODE)
end)

sbar.exec("aerospace list-modes --current", set_mode)
