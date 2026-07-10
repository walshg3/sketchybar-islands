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
local provider_args = " --cpu usage --memory ram_usage --disk free usage --network en0 --interval 2"
local provider_command = "sleep 3; killall stats_provider >/dev/null; /opt/homebrew/bin/stats_provider"
  .. provider_args
sbar.exec(provider_command)

-- The provider dies across sleep/wake and nothing else restarts it, so the
-- stats freeze at their last values. Guarded respawn: only spawns when the
-- provider is actually gone (checked on wake and once a minute).
local ensure_provider_command = "pgrep -x stats_provider >/dev/null || { sleep 1; /opt/homebrew/bin/stats_provider"
  .. provider_args
  .. "; }"

local latest_disk_free = "--"
local latest_disk_usage = "--"

-- Inline speeds. Widths are measured, not guessed: the widest provider
-- output ("10.5MB/s") renders at ~84px per side at this font, so 85 fixed
-- keeps the island from jittering and the 6px gap keeps down/up apart.
local net = sbar.add("item", "right.stats.net", {
  position = "right",
  icon = {
    string = icons.wifi.download .. " --",
    color = colors.net_down,
    width = 85,
    padding_right = 6,
  },
  label = {
    string = icons.wifi.upload .. " --",
    color = colors.net_up,
    width = 85,
  },
  background = { drawing = false },
})

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
  update_freq = 60,
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

cpu:subscribe({ "routine", "system_woke" }, function()
  sbar.exec(ensure_provider_command)
end)

cpu:subscribe("system_stats", function(env)
  latest_disk_free = env.DISK_FREE or latest_disk_free
  latest_disk_usage = env.DISK_USAGE or latest_disk_usage

  cpu:set { label = env.CPU_USAGE or "--" }
  ram:set { label = env.RAM_USAGE or "--" }
  net:set {
    icon = { string = icons.wifi.download .. " " .. (env.NETWORK_RX_en0 or "--") },
    label = { string = icons.wifi.upload .. " " .. (env.NETWORK_TX_en0 or "--") },
  }
end)

ram:subscribe("mouse.clicked", function()
  local opening = ram:query().popup.drawing == "off"
  disk_free:set { label = latest_disk_free }
  disk_usage:set { label = latest_disk_usage }
  ram:set { popup = { drawing = opening } }
end)
