local colors = require "colors"
colors = colors.sections.bar

sbar.bar {
  topmost = "window",
  height = 44,
  color = colors.bg,
  padding_left = 14,
  padding_right = 14,
  y_offset = 0,
  margin = 0,
  corner_radius = 0,
  border_width = 0,
  blur_radius = 0,
  -- Widen the q/e dead zone past the default 200 so the media island's right
  -- edge is not clipped by the physical notch on the 16" MacBook. No effect
  -- on the ultrawide (center position is used there).
  notch_width = 230,
}
