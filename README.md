# SketchyBar Islands

A SketchyBar configuration built around three floating "islands" on a fully
transparent bar, themed with Catppuccin and driven by AeroSpace. Runs on the
2026 rebuild of the personal-Mac setup (5120x1440 ultrawide plus a notched
16" MacBook Pro).

## Showcase

Mocha, macchiato, and frappe on the notched MacBook display (workspaces with
per-app glyphs left, media at the notch, stats/widgets/clock right):

![mocha](screenshots/bar-mocha-notch.png)
![macchiato](screenshots/bar-macchiato-notch.png)
![frappe](screenshots/bar-frappe-notch.png)

The media island expanded (hover or track change):

<p>
  <img src="screenshots/media-nowplaying-notch.png" width="290" alt="now playing">
</p>

## Layout

- **Left island:** Apple menu trigger, AeroSpace workspaces with per-space app
  glyphs and a mauve underline on focus, in-bar menu items (toggle with the
  switch dot), and an `[service]`/`[resize]` binding-mode indicator.
- **Center island:** Spotify now-playing with hover-expand and popup controls.
  Sits at `center` on wide displays and at `q` (left of the notch) when only
  the built-in display is active.
- **Right island:** CPU, RAM, network up/down (pushed by `stats_provider`
  every 2s), disk popup, brew outdated count, Messages unread, VPN badge,
  volume with slider popup, Wi-Fi with IP popup, battery with percent,
  weather (Open-Meteo), clock, and the Catppuccin flavor cycler.

## Theme

Click the dot at the far right of the bar to cycle mocha, macchiato, and
frappe. The choice persists in the untracked `flavor` file; missing file
means mocha. Palettes live in `colors.lua` with real Catppuccin names.

## Requirements

- sketchybar (v2.24+) and the SbarLua module at
  `~/.local/share/sketchybar_lua/sketchybar.so`
- AeroSpace, with the workspace/mode triggers from this setup's
  `aerospace.toml` additions (see README-ROLLBACK.md)
- `stats_provider` from `joncrangle/tap/sketchybar-system-stats`
- SF Pro, SF Symbols, and `sketchybar-app-font`
- `SwitchAudioSource` (volume device popup), `jq` not required

## Reload

Never use `sketchybar --reload`:

```bash
launchctl kickstart -k gui/$(id -u)/homebrew.mxcl.sketchybar
```

## Process architecture (the load-bearing part)

sketchybar v2.24 SIGKILLs the config script's process group about 60 seconds
after launch. A resident SbarLua event loop looks like a hung script to that
watchdog, so it was reaped every boot, silently killing all event handling.
The entrypoint chain defeats it:

```
sketchybarrc          kills the previous generation, spawns detached, exits
  -> rc-runner.sh     new session (setsid), segfault retry, lifecycle log
     -> lua rc.lua    the actual SbarLua config
```

Lifecycle log: `/tmp/rc_trace.log`. The other hard-won SbarLua-on-v2.24
gotchas (graph add segfault, exec JSON table results, `updates = true` on
self-hiding items, and more) are listed in `README-ROLLBACK.md`.

## Rollback

The pre-Islands config and full operational notes live in
`README-ROLLBACK.md`.
