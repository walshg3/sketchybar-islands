local settings = require "settings"

local menu_watcher = sbar.add("item", {
  drawing = false,
  updates = false,
})
local space_menu_swap = sbar.add("item", {
  drawing = false,
  updates = true,
})
sbar.add("event", "swap_menus_and_spaces")

local max_items = 15
local menu_items = {}
for i = 1, max_items, 1 do
  local menu = sbar.add("item", "left.menu." .. i, {
    position = "left",
    drawing = false,
    icon = { drawing = false },
    background = { drawing = false },
    label = {
      font = {
        style = settings.font.style_map[i == 1 and "Heavy" or "Semibold"],
      },
      padding_left = 6,
      padding_right = 6,
    },
    click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s " .. i,
  })

  menu_items[i] = menu
end

-- An empty config table serializes as a dangling --set that swallows the
-- next batched command, so give the bracket a real (no-op) property.
sbar.add("bracket", { "/left\\.menu\\..*/" }, {
  background = { drawing = false },
})

local menu_padding = sbar.add("item", "left.menu.padding", {
  position = "left",
  drawing = false,
  width = 5,
})

local function update_menus()
  sbar.exec("$CONFIG_DIR/helpers/menus/bin/menus -l", function(menus)
    sbar.set("/left\\.menu\\..*/", { drawing = false })
    menu_padding:set { drawing = true }
    local id = 1
    for menu in menus:gmatch "[^\r\n]+" do
      if id < max_items then
        menu_items[id]:set { label = menu, drawing = true }
      else
        break
      end
      id = id + 1
    end
  end)
end

menu_watcher:subscribe("front_app_switched", update_menus)

space_menu_swap:subscribe("swap_menus_and_spaces", function()
  local drawing = menu_items[1]:query().geometry.drawing == "on"
  if drawing then
    menu_watcher:set { updates = false }
    sbar.set("/left\\.menu\\..*/", { drawing = false })
    sbar.set("/left\\.space\\..*/", { drawing = true })
  else
    menu_watcher:set { updates = true }
    sbar.set("/left\\.space\\..*/", { drawing = false })
    update_menus()
  end
end)

return menu_watcher
