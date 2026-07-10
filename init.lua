sbar = require "sketchybar"

sbar.begin_config()
require "bar"
require "default"
require "helpers.display"
require "items"
sbar.end_config()

io.stderr:write "[islands] entering event_loop\n"
sbar.event_loop()
io.stderr:write "[islands] event_loop RETURNED\n"
