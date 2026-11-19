local colors = require "colors"

local weather = sbar.add("item", "right.weather", {
  position = "right",
  drawing = false,
  updates = true,
  update_freq = 3600,
  icon = { drawing = false },
  label = {
    color = colors.sections.weather.label,
  },
})

local function condition_for(code)
  if not code then
    return nil
  end

  if code == 0 then
    return "Clear"
  elseif code >= 1 and code <= 3 then
    return "Cloudy"
  elseif code == 45 or code == 48 then
    return "Fog"
  elseif code >= 51 and code <= 67 then
    return "Rain"
  elseif code >= 71 and code <= 77 then
    return "Snow"
  elseif code >= 80 and code <= 82 then
    return "Showers"
  elseif code >= 95 then
    return "Storm"
  end
end

local function hide()
  weather:set { drawing = false, label = { string = "" } }
end

-- Optional pinned location: a gitignored `location` file in the config dir
-- holding "latitude,longitude". Without it, fall back to IP geolocation.
local function pinned_location()
  local dir = os.getenv "CONFIG_DIR" or ((os.getenv "HOME" or "") .. "/.config/sketchybar")
  local file = io.open(dir .. "/location", "r")
  if not file then
    return nil
  end
  local location = file:read "*l"
  file:close()
  return location
end

local function update()
  local location_command = "sh -c 'if [ -n \"$(find /tmp/sketchybar_loc -mmin -60 2>/dev/null)\" ] "
    .. "&& [ -s /tmp/sketchybar_loc ]; then "
    .. "cat /tmp/sketchybar_loc; else loc=$(curl -sf --max-time 5 ipinfo.io/loc); "
    .. "if [ -n \"$loc\" ]; then printf \"%s\" \"$loc\" > /tmp/sketchybar_loc; "
    .. "printf \"%s\" \"$loc\"; fi; fi'"

  local function fetch_weather(location)
    local latitude, longitude = (location or ""):match("^%s*([%-]?%d+%.?%d*),([%-]?%d+%.?%d*)%s*$")
    if not latitude or not longitude then
      hide()
      return
    end

    local url = "https://api.open-meteo.com/v1/forecast?latitude="
      .. latitude
      .. "&longitude="
      .. longitude
      .. "&current=temperature_2m,weather_code&temperature_unit=fahrenheit"

    sbar.exec("curl -sf --max-time 8 '" .. url .. "'", function(response)
      -- sbar.exec parses JSON output into a Lua table; handle both shapes.
      local temperature, code
      if type(response) == "table" then
        local current = response.current or {}
        temperature = tonumber(current.temperature_2m)
        code = tonumber(current.weather_code)
      else
        temperature = tonumber((response or ""):match('"temperature_2m"%s*:%s*([%-]?%d+%.?%d*)'))
        code = tonumber((response or ""):match('"weather_code"%s*:%s*(%d+)'))
      end
      local condition = condition_for(code)

      if not temperature or not condition then
        hide()
        return
      end

      weather:set {
        drawing = true,
        label = { string = string.format("%.0f°F %s", temperature, condition) },
      }
    end)
  end

  local pinned = pinned_location()
  if pinned then
    fetch_weather(pinned)
  else
    sbar.exec(location_command, fetch_weather)
  end
end

weather:subscribe({ "routine", "system_woke" }, update)
update()
