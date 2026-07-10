local colors = require("colors").sections

local M = {}

M.style = {
  background = {
    color = colors.isle.bg,
    border_color = colors.isle.border,
    border_width = 1,
    corner_radius = 10,
    height = 36,
  },
}

-- Bracket regex membership is evaluated at creation time only, so islands
-- containing async-created items (spaces, media) must be (re)built after
-- those items exist.
function M.make(side)
  return sbar.add("bracket", "islands." .. side, { "/" .. side .. "\\..*/" }, M.style)
end

function M.refresh(side)
  sbar.remove("islands." .. side)
  return M.make(side)
end

-- CLI fragment for rebuilding an island inside a single `sketchybar ...`
-- shell invocation (deterministic ordering, no exec-callback dependency).
function M.refresh_command(side)
  local bg = M.style.background
  return " --remove islands." .. side
    .. " --add bracket islands." .. side .. " '/" .. side .. "\\..*/'"
    .. string.format(
      " --set islands.%s background.color=0x%08x background.border_color=0x%08x background.border_width=%d background.corner_radius=%d background.height=%d",
      side, bg.color, bg.border_color, bg.border_width, bg.corner_radius, bg.height
    )
end

return M
