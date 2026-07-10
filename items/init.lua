local colors = require "colors"
colors = colors.sections

-- left
require "items.apple"
require "items.spaces"
require "items.menus"
require "items.mode"

-- right (reverse visual order)
require "items.theme"
require "items.calendar"
require "items.widgets"

-- center
require "items.media"

-- islands.left is refreshed by items/spaces.lua once the async workspace
-- items exist; islands.center is created by items/media.lua for the same
-- reason (an empty regex bracket is dropped, not deferred).
local islands = require "helpers.islands"
islands.make "left"
islands.make "right"
