local colors = require "colors"
colors = colors.sections
local icons = require "icons"

sbar.add("item", "left.apple", {
  position = "left",
  icon = {
    font = { size = 16 },
    string = icons.apple,
    color = colors.apple,
    padding_left = 10,
    padding_right = 6,
  },
  label = { drawing = false },
  padding_left = 0,
  padding_right = 0,
  click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0",
})
