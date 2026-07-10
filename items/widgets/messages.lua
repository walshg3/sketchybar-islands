local icons = require "icons"
local theme = require "colors"
local colors = theme.sections.widgets.messages

local messages = sbar.add("item", "right.messages", {
  position = "right",
  icon = {
    color = colors.icon,
    string = icons.message,
    padding_right = 4,
  },
  label = { drawing = false },
  background = { drawing = false },
  update_freq = 30,
})

messages:subscribe({ "routine", "system_woke" }, function()
  local unread_query = [[sqlite3 ~/Library/Messages/chat.db "SELECT COUNT(guid) FROM message ]]
    .. [[WHERE NOT(is_read) AND NOT(is_from_me) AND text !=''"]]
  sbar.exec(
    -- Requires Full Disk Access for the SketchyBar process.
    unread_query,
    function(new_messages)
      local count = tonumber(new_messages) or 0
      messages:set {
        icon = { drawing = count > 0 },
        padding_right = count > 0 and 4 or 0,
      }
    end
  )
end)

messages:subscribe("mouse.clicked", function()
  sbar.exec "open -a 'Messages'"
end)
