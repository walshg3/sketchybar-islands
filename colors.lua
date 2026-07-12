local M = {}

local with_alpha = function(color, alpha)
  if alpha > 1.0 or alpha < 0.0 then
    return color
  end
  return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
end

local palettes = {
  mocha = {
    rosewater = 0xfff5e0dc,
    flamingo = 0xfff2cdcd,
    pink = 0xfff5c2e7,
    mauve = 0xffcba6f7,
    red = 0xfff38ba8,
    maroon = 0xffeba0ac,
    peach = 0xfffab387,
    yellow = 0xfff9e2af,
    green = 0xffa6e3a1,
    teal = 0xff94e2d5,
    sky = 0xff89dceb,
    sapphire = 0xff74c7ec,
    blue = 0xff89b4fa,
    lavender = 0xffb4befe,
    text = 0xffcdd6f4,
    subtext1 = 0xffbac2de,
    subtext0 = 0xffa6adc8,
    overlay2 = 0xff9399b2,
    overlay1 = 0xff7f849c,
    overlay0 = 0xff6c7086,
    surface2 = 0xff585b70,
    surface1 = 0xff45475a,
    surface0 = 0xff313244,
    base = 0xff1e1e2e,
    mantle = 0xff181825,
    crust = 0xff11111b,
  },
  macchiato = {
    rosewater = 0xfff4dbd6,
    flamingo = 0xfff0c6c6,
    pink = 0xfff5bde6,
    mauve = 0xffc6a0f6,
    red = 0xffed8796,
    maroon = 0xffee99a0,
    peach = 0xfff5a97f,
    yellow = 0xffeed49f,
    green = 0xffa6da95,
    teal = 0xff8bd5ca,
    sky = 0xff91d7e3,
    sapphire = 0xff7dc4e4,
    blue = 0xff8aadf4,
    lavender = 0xffb7bdf8,
    text = 0xffcad3f5,
    subtext1 = 0xffb8c0e0,
    subtext0 = 0xffa5adcb,
    overlay2 = 0xff939ab7,
    overlay1 = 0xff8087a2,
    overlay0 = 0xff6e738d,
    surface2 = 0xff5b6078,
    surface1 = 0xff494d64,
    surface0 = 0xff363a4f,
    base = 0xff24273a,
    mantle = 0xff1e2030,
    crust = 0xff181926,
  },
  frappe = {
    rosewater = 0xfff2d5cf,
    flamingo = 0xffeebebe,
    pink = 0xfff4b8e4,
    mauve = 0xffca9ee6,
    red = 0xffe78284,
    maroon = 0xffea999c,
    peach = 0xffef9f76,
    yellow = 0xffe5c890,
    green = 0xffa6d189,
    teal = 0xff81c8be,
    sky = 0xff99d1db,
    sapphire = 0xff85c1dc,
    blue = 0xff8caaee,
    lavender = 0xffbabbf1,
    text = 0xffc6d0f5,
    subtext1 = 0xffb5bfe2,
    subtext0 = 0xffa5adce,
    overlay2 = 0xff949cbb,
    overlay1 = 0xff838ba7,
    overlay0 = 0xff737994,
    surface2 = 0xff626880,
    surface1 = 0xff51576d,
    surface0 = 0xff414559,
    base = 0xff303446,
    mantle = 0xff292c3c,
    crust = 0xff232634,
  },
}

local flavor = "mocha"
local config_dir = os.getenv "CONFIG_DIR" or (os.getenv "HOME" .. "/.config/sketchybar")
local flavor_file = io.open(config_dir .. "/flavor", "r")
if flavor_file then
  local saved_flavor = flavor_file:read("*a"):match("^%s*(.-)%s*$")
  flavor_file:close()
  if palettes[saved_flavor] then
    flavor = saved_flavor
  end
end

local palette = palettes[flavor]
local transparent = 0x00000000

M.flavor = flavor
M.palette = palette
M.with_alpha = with_alpha
M.transparent = transparent
M.sections = {
  bar = {
    bg = transparent,
  },
  isle = {
    bg = with_alpha(palette.base, 0.82),
    border = with_alpha(palette.surface1, 0.5),
    divider = with_alpha(palette.surface2, 0.7),
  },
  text = {
    primary = palette.text,
    secondary = palette.subtext0,
    muted = palette.overlay0,
  },
  accent = palette.mauve,
  apple = palette.mauve,
  spaces = {
    idle = palette.overlay1,
    focused = palette.text,
    underline = palette.mauve,
    glyph = palette.subtext0,
  },
  mode = {
    main = palette.overlay0,
    other = palette.peach,
  },
  media = {
    icon = palette.green,
    label = palette.subtext0,
  },
  stats = {
    cpu = palette.yellow,
    ram = palette.sapphire,
    net_up = palette.peach,
    net_down = palette.green,
    disk = palette.teal,
  },
  widgets = {
    battery = {
      low = palette.red,
      mid = palette.yellow,
      high = palette.green,
    },
    wifi = {
      icon = palette.pink,
      vpn = palette.green,
    },
    volume = {
      icon = palette.sky,
      slider = {
        highlight = palette.sky,
        bg = palette.surface1,
        border = palette.crust,
      },
    },
    messages = {
      icon = palette.red,
    },
  },
  weather = {
    label = palette.subtext0,
  },
  brew = {
    icon = palette.peach,
    alert = palette.red,
  },
  calendar = {
    time = palette.text,
    date = palette.subtext0,
  },
  popup = {
    bg = with_alpha(palette.crust, 0.92),
    border = with_alpha(palette.surface1, 0.6),
  },
}

return M
