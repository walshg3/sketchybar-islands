local colors = require "colors"
colors = colors.sections.calendar
local settings = require "settings"

local calendar = sbar.add("item", "right.calendar", {
  position = "right",
  icon = {
    color = colors.time,
    padding_left = 8,
    padding_right = 4,
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
      size = 13.0,
    },
  },
  label = {
    color = colors.date,
    align = "left",
    padding_left = 0,
    padding_right = 8,
  },
  padding_left = 0,
  padding_right = 0,
  update_freq = 10,
  click_script = "open -a 'Calendar'",
})

calendar:subscribe({ "forced", "routine", "system_woke" }, function()
  local time = (os.date "%I:%M %p"):gsub("^0", "")
  local date = os.date "%a %m/%d"
  calendar:set {
    icon = time,
    label = "· " .. date,
  }
end)
