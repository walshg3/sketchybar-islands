local icons = require "icons"
local colors = require "colors"
local display = require "helpers.display"

local media_colors = colors.sections.media
local spotify_command = "osascript -e 'tell application \"Spotify\" to "

local function trim(value)
  return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

display.mode(function(mode)
  local popup_open = false
  local current_track = nil
  local update_generation = 0

  local media_playback = sbar.add("item", "center.media", {
    position = mode == "wide" and "center" or "q",
    drawing = false,
    updates = true,
    update_freq = 3,
    icon = {
      string = icons.music,
      color = media_colors.icon,
      padding_left = 8,
      padding_right = 6,
    },
    label = {
      string = "",
      width = 0,
      max_chars = 45,
      color = media_colors.label,
      padding_right = 8,
    },
    popup = {
      horizontal = true,
      -- In notch mode the item hugs the notch's left edge; a centered popup
      -- bleeds under the notch, so open it leftward instead.
      align = mode == "wide" and "center" or "right",
      y_offset = 2,
    },
  })

  sbar.add("item", {
    position = "popup." .. media_playback.name,
    padding_left = 6,
    padding_right = 6,
    icon = { string = icons.media.back },
    label = { drawing = false },
    background = { drawing = false },
    click_script = "osascript -e 'tell application \"Spotify\" to previous track'",
  })

  sbar.add("item", {
    position = "popup." .. media_playback.name,
    padding_left = 6,
    padding_right = 6,
    icon = { string = icons.media.play_pause },
    label = { drawing = false },
    background = { drawing = false },
    click_script = "osascript -e 'tell application \"Spotify\" to playpause'",
  })

  sbar.add("item", {
    position = "popup." .. media_playback.name,
    padding_left = 6,
    padding_right = 6,
    icon = { string = icons.media.forward },
    label = { drawing = false },
    background = { drawing = false },
    click_script = "osascript -e 'tell application \"Spotify\" to next track'",
  })

  -- The center island is created here (not items/init.lua) because an empty
  -- regex bracket is dropped at creation, and center.media is async-created.
  require("helpers.islands").make "center"

  local function hide()
    media_playback:set {
      drawing = false,
      label = { string = "", width = 0 },
      popup = { drawing = false },
    }
    popup_open = false
  end

  local function update()
    update_generation = update_generation + 1
    local generation = update_generation

    sbar.exec("pgrep -x Spotify", function(process)
      if generation ~= update_generation then
        return
      end
      if trim(process) == "" then
        hide()
        return
      end

      local state_command = spotify_command .. "player state as string' 2>/dev/null"
      sbar.exec(state_command, function(state)
        if generation ~= update_generation then
          return
        end
        if trim(state) ~= "playing" then
          hide()
          return
        end

        local artist_command = spotify_command .. "artist of current track as string' 2>/dev/null"
        sbar.exec(artist_command, function(artist)
          if generation ~= update_generation then
            return
          end

          local track_command = spotify_command .. "name of current track as string' 2>/dev/null"
          sbar.exec(track_command, function(track)
            if generation ~= update_generation then
              return
            end

            artist = trim(artist)
            track = trim(track)
            if track == "" then
              hide()
              return
            end

            local text = artist ~= "" and (artist .. " - " .. track) or track
            local is_new_track = text ~= current_track
            current_track = text
            media_playback:set {
              drawing = true,
              icon = { string = icons.music },
              label = { string = text },
            }

            if is_new_track then
              sbar.animate("tanh", 30, function()
                media_playback:set { label = { width = "dynamic" } }
              end)
              sbar.delay(5, function()
                if not popup_open and current_track == text then
                  sbar.animate("tanh", 30, function()
                    media_playback:set { label = { width = 0 } }
                  end)
                end
              end)
            end
          end)
        end)
      end)
    end)
  end

  media_playback:subscribe("routine", update)

  media_playback:subscribe("mouse.entered", function()
    sbar.animate("tanh", 30, function()
      media_playback:set { label = { width = "dynamic" } }
    end)
  end)

  media_playback:subscribe("mouse.exited", function()
    sbar.animate("tanh", 30, function()
      media_playback:set { label = { width = 0 } }
    end)
  end)

  media_playback:subscribe("mouse.clicked", function()
    popup_open = not popup_open
    media_playback:set { popup = { drawing = popup_open } }
  end)

  update()
end)
