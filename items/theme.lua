local colors = require "colors"
local icons = require "icons"

local cycle = {
  mocha = "macchiato",
  macchiato = "frappe",
  frappe = "mocha",
}

local theme = sbar.add("item", "right.theme", {
  position = "right",
  icon = {
    string = icons.space_indicator.on,
    color = colors.sections.accent,
    padding_left = 6,
    padding_right = 10,
  },
  label = { drawing = false },
  padding_left = 0,
  padding_right = 0,
})

theme:subscribe("mouse.clicked", function()
  local next_flavor = cycle[colors.flavor]
  -- Full daemon kickstart instead of --reload: config re-execution after a
  -- reload segfaults the SbarLua module on this sketchybar version; a fresh
  -- daemon boot is reliable.
  sbar.exec(
    "printf '%s' "
      .. next_flavor
      .. " > \"$CONFIG_DIR/flavor\"; launchctl kickstart -k gui/$(id -u)/homebrew.mxcl.sketchybar"
  )
end)
