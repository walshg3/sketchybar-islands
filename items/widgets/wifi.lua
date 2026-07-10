local icons = require "icons"
local theme = require "colors"
local colors = theme.sections.widgets.wifi

local popup_width = 250

local wifi = sbar.add("item", "right.wifi", {
  position = "right",
  icon = { color = colors.icon },
  label = { drawing = false },
  background = { drawing = false },
  popup = {
    align = "center",
    height = 30,
    y_offset = 2,
  },
})

local ip = sbar.add("item", {
  position = "popup." .. wifi.name,
  icon = {
    align = "left",
    string = "IP:",
    width = popup_width / 2,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
  },
  background = { drawing = false },
})

local mask = sbar.add("item", {
  position = "popup." .. wifi.name,
  icon = {
    align = "left",
    string = "Subnet mask:",
    width = popup_width / 2,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
  },
  background = { drawing = false },
})

local router = sbar.add("item", {
  position = "popup." .. wifi.name,
  icon = {
    align = "left",
    string = "Router:",
    width = popup_width / 2,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
  },
  background = { drawing = false },
})

local function update_wifi()
  sbar.exec([[ipconfig getsummary en0 | awk -F ' SSID : ' '/ SSID : / {print $2}']], function(wifi_name)
    local connected = wifi_name:match "%S" ~= nil
    wifi:set {
      icon = {
        string = connected and icons.wifi.connected or icons.wifi.disconnected,
        color = colors.icon,
      },
    }
  end)
end

wifi:subscribe({ "wifi_change", "system_woke" }, update_wifi)
update_wifi()

wifi:subscribe("mouse.clicked", function()
  if wifi:query().popup.drawing ~= "off" then
    wifi:set { popup = { drawing = false } }
    return
  end

  wifi:set { popup = { drawing = true } }
  sbar.exec("ipconfig getifaddr en0", function(result)
    ip:set { label = result }
  end)
  sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Subnet mask: ' '/^Subnet mask: / {print $2}'", function(result)
    mask:set { label = result }
  end)
  sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Router: ' '/^Router: / {print $2}'", function(result)
    router:set { label = result }
  end)
end)

local function copy_label_to_clipboard(env)
  local label = sbar.query(env.NAME).label.value
  sbar.exec('echo "' .. label .. '" | pbcopy')
  sbar.set(env.NAME, { label = { string = icons.clipboard, align = "center" } })
  sbar.delay(1, function()
    sbar.set(env.NAME, { label = { string = label, align = "right" } })
  end)
end

ip:subscribe("mouse.clicked", copy_label_to_clipboard)
mask:subscribe("mouse.clicked", copy_label_to_clipboard)
router:subscribe("mouse.clicked", copy_label_to_clipboard)
