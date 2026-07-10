local settings = require "settings"
local colors = require "colors"
colors = colors.sections

sbar.default {
  updates = "when_shown",
  icon = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Semibold"],
      size = 14.0,
    },
    color = colors.text.primary,
    padding_left = 4,
    padding_right = 4,
    background = {
      drawing = false,
      image = { corner_radius = 10 },
    },
  },
  label = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Semibold"],
      size = 13.0,
    },
    color = colors.text.primary,
    padding_left = 4,
    padding_right = 4,
  },
  background = {
    drawing = false,
  },
  popup = {
    blur_radius = 30,
    background = {
      color = colors.popup.bg,
      border_color = colors.popup.border,
      border_width = 1,
      corner_radius = 10,
      shadow = {
        drawing = false,
      },
    },
  },
  padding_left = 4,
  padding_right = 4,
  scroll_texts = true,
}
