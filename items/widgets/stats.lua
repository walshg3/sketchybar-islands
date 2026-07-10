local icons = require "icons"
local theme = require "colors"
local colors = theme.sections.stats

-- Register the event before any subscription; the provider's own
-- registration happens too late for subscriptions made at config load.
sbar.add("event", "system_stats")

-- The leading sleep delays the provider boot: spawning it while the bar is
-- still processing config makes its initial mach registration fail and it
-- exits. Shell-side sleep, NOT sbar.delay — a top-level sbar.delay (before
-- the event loop exists) segfaults the module at config load.
local provider_command = "sleep 3; killall stats_provider >/dev/null; /opt/homebrew/bin/stats_provider"
  .. " --cpu usage --memory ram_usage --disk free usage --network en0 --interval 2"
sbar.exec(provider_command)

local latest_disk_free = "--"
local latest_disk_usage = "--"

-- Compact arrows inline; the actual speeds live in a click-down popup
-- (inline numbers didn't fit on the MacBook screen).
local net = sbar.add("item", "right.stats.net", {
  position = "right",
  icon = {
    string = icons.wifi.download,
    color = colors.net_down,
    padding_left = 4,
    padding_right = 1,
  },
  label = {
    string = icons.wifi.upload,
    color = colors.net_up,
    padding_left = 1,
    padding_right = 4,
  },
  background = { drawing = false },
  popup = { align = "center", y_offset = 2 },
})

local net_down_row = sbar.add("item", {
  position = "popup." .. net.name,
  icon = {
    string = "Download:",
    color = colors.net_down,
    width = 95,
    align = "left",
  },
  label = {
    string = "--",
    width = 85,
    align = "right",
  },
  background = { drawing = false },
})

local net_up_row = sbar.add("item", {
  position = "popup." .. net.name,
  icon = {
    string = "Upload:",
    color = colors.net_up,
    width = 95,
    align = "left",
  },
  label = {
    string = "--",
    width = 85,
    align = "right",
  },
  background = { drawing = false },
})

net:subscribe("mouse.clicked", function()
  net:set { popup = { drawing = "toggle" } }
end)

local ram = sbar.add("item", "right.stats.ram", {
  position = "right",
  icon = {
    string = icons.ramicons.ram,
    color = colors.ram,
  },
  label = { string = "--", color = colors.ram },
  background = { drawing = false },
  popup = { align = "center" },
})

local disk_free = sbar.add("item", {
  position = "popup." .. ram.name,
  icon = {
    string = "Free:",
    color = colors.disk,
    width = 70,
    align = "left",
  },
  label = {
    string = latest_disk_free,
    width = 90,
    align = "right",
  },
  background = { drawing = false },
})

local disk_usage = sbar.add("item", {
  position = "popup." .. ram.name,
  icon = {
    string = "Used:",
    color = colors.disk,
    width = 70,
    align = "left",
  },
  label = {
    string = latest_disk_usage,
    width = 90,
    align = "right",
  },
  background = { drawing = false },
})

-- NOT sbar.add("graph", ...): the module's graph-add serialization segfaults
-- against sketchybar v2.24, so this is a plain item and the graph history
-- lives in a CLI-created companion graph pushed via the CLI as well.
local cpu = sbar.add("item", "right.stats.cpu", {
  position = "right",
  icon = {
    string = icons.cpu,
    color = colors.cpu,
  },
  label = {
    string = "--",
    color = colors.cpu,
  },
  background = { drawing = false },
  click_script = "open -a 'Activity Monitor'",
})

cpu:subscribe("system_stats", function(env)
  latest_disk_free = env.DISK_FREE or latest_disk_free
  latest_disk_usage = env.DISK_USAGE or latest_disk_usage

  cpu:set { label = env.CPU_USAGE or "--" }
  ram:set { label = env.RAM_USAGE or "--" }
  net_down_row:set { label = env.NETWORK_RX_en0 or "--" }
  net_up_row:set { label = env.NETWORK_TX_en0 or "--" }
end)

ram:subscribe("mouse.clicked", function()
  local opening = ram:query().popup.drawing == "off"
  disk_free:set { label = latest_disk_free }
  disk_usage:set { label = latest_disk_usage }
  ram:set { popup = { drawing = opening } }
end)
