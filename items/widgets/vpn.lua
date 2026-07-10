local icons = require "icons"
local theme = require "colors"
local color = theme.sections.widgets.wifi.vpn

local vpn = sbar.add("item", "right.vpn", {
  position = "right",
  drawing = false,
  updates = true, -- default when_shown never wakes a hidden item
  icon = {
    string = icons.wifi.vpn,
    color = color,
  },
  label = { color = color },
  background = { drawing = false },
})

local function update_vpn()
  sbar.exec([[scutil --nwi | grep -m1 'utun' | awk '{ print $1 }']], function(interface)
    local name = interface:match "(%S+)"
    vpn:set {
      drawing = name ~= nil,
      label = name or "",
    }
  end)
end

vpn:subscribe({ "wifi_change", "system_woke" }, update_vpn)
update_vpn()
