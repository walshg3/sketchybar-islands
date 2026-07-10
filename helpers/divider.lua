local colors = require "colors"
colors = colors.sections

return function(name, position)
  return sbar.add("item", name, {
    position = position,
    icon = { drawing = false },
    label = {
      string = "│",
      color = colors.isle.divider,
      padding_left = 2,
      padding_right = 2,
    },
    background = { drawing = false },
    click_script = "",
  })
end
