local icons = require "icons"
local theme = require "colors"
local colors = theme.sections.widgets.battery

local battery = sbar.add("item", "right.battery", {
  position = "right",
  icon = {},
  label = { drawing = true },
  background = { drawing = false },
  update_freq = 180,
  popup = { align = "center", y_offset = 4 },
})

local remaining_time = sbar.add("item", {
  position = "popup." .. battery.name,
  icon = {
    string = "Time remaining:",
    width = 100,
    align = "left",
  },
  label = {
    string = "??:??h",
    width = 100,
    align = "right",
  },
  background = { drawing = false },
})

battery:subscribe({ "routine", "power_source_change", "system_woke" }, function()
  sbar.exec("pmset -g batt", function(battery_info)
    local charge = tonumber(battery_info:match "(%d+)%%") or 0
    local charging = battery_info:find("AC Power", 1, true) ~= nil
    local icon = icons.battery._0
    local color = colors.low

    if charging then
      icon = icons.battery.charging
      color = colors.high
    elseif charge > 80 then
      icon = icons.battery._100
      color = colors.high
    elseif charge > 60 then
      icon = icons.battery._75
      color = colors.high
    elseif charge > 40 then
      icon = icons.battery._50
      color = colors.high
    elseif charge > 30 then
      icon = icons.battery._50
      color = colors.mid
    elseif charge > 20 then
      icon = icons.battery._25
      color = colors.mid
    end

    battery:set {
      icon = {
        string = icon,
        color = color,
      },
      label = {
        string = charge .. "%",
        color = color,
      },
    }
  end)
end)

battery:subscribe("mouse.clicked", function()
  local opening = battery:query().popup.drawing == "off"
  battery:set { popup = { drawing = "toggle" } }

  if opening then
    sbar.exec("pmset -g batt", function(battery_info)
      local remaining = battery_info:match " (%d+:%d+) remaining"
      remaining_time:set { label = remaining and remaining .. "h" or "No estimate" }
    end)
  end
end)
