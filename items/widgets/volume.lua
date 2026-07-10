local theme = require "colors"
local colors = theme.sections.widgets.volume
local icons = require "icons"

local popup_width = 250
local device_color = theme.sections.text.secondary
local selected_device_color = theme.sections.accent

local volume = sbar.add("item", "right.volume", {
  position = "right",
  icon = { color = colors.icon },
  label = { drawing = false },
  background = { drawing = false },
  popup = {
    align = "center",
    y_offset = 2,
  },
})

local volume_slider = sbar.add("slider", popup_width, {
  position = "popup." .. volume.name,
  slider = {
    highlight_color = colors.slider.highlight,
    background = {
      height = 12,
      corner_radius = 6,
      color = colors.slider.bg,
      border_color = colors.slider.border,
      border_width = 2,
    },
    knob = { drawing = false },
  },
  background = { drawing = false },
  click_script = 'osascript -e "set volume output volume $PERCENTAGE"',
})

volume:subscribe("volume_change", function(env)
  local icon = icons.volume._0
  local level = tonumber(env.INFO) or 0

  if level > 60 then
    icon = icons.volume._100
  elseif level > 30 then
    icon = icons.volume._66
  elseif level > 10 then
    icon = icons.volume._33
  elseif level > 0 then
    icon = icons.volume._10
  end

  volume:set { icon = icon }
  volume_slider:set { slider = { percentage = level } }
end)

local function collapse_details()
  if volume:query().popup.drawing ~= "on" then
    return
  end

  volume:set { popup = { drawing = false } }
  sbar.remove "/volume.device\\.*/"
end

local function toggle_details(env)
  if env.BUTTON == "right" then
    sbar.exec "open /System/Library/PreferencePanes/Sound.prefpane"
    return
  end

  if volume:query().popup.drawing ~= "off" then
    collapse_details()
    return
  end

  volume:set { popup = { drawing = true } }
  sbar.exec("SwitchAudioSource -t output -c", function(result)
    local current_device = result:match "([^\r\n]+)" or ""
    sbar.exec("SwitchAudioSource -a -t output", function(available)
      local counter = 0

      for device in available:gmatch "[^\r\n]+" do
        local color = device == current_device and selected_device_color or device_color
        sbar.add("item", "volume.device." .. counter, {
          position = "popup." .. volume.name,
          width = popup_width,
          align = "center",
          label = { string = device, color = color },
          background = { drawing = false },
          click_script = 'SwitchAudioSource -s "'
            .. device
            .. '" && sketchybar --set /volume.device\\.*/ label.color='
            .. device_color
            .. " --set $NAME label.color="
            .. selected_device_color,
        })
        counter = counter + 1
      end
    end)
  end)
end

volume:subscribe("mouse.clicked", toggle_details)

volume:subscribe("mouse.scrolled", function(env)
  local delta = tonumber(env.SCROLL_DELTA) or 0
  sbar.exec('osascript -e "set volume output volume (output volume of (get volume settings) + ' .. delta .. ')"')
end)
