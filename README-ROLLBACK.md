# SketchyBar "Islands" config — rollback & operations notes

The pre-revamp config is preserved verbatim at `~/.config/sketchybar-classic/`
(byte-identical backup taken 2026-07-09, before the Islands rebuild).

## Reload the bar (IMPORTANT: not --reload)

```bash
launchctl kickstart -k gui/$(id -u)/homebrew.mxcl.sketchybar
```

`sketchybar --reload` is unreliable on this setup: re-executing the SbarLua
config after a reload segfaults the module (sketchybar v2.24 + SbarLua), while
a fresh daemon boot is consistently clean. The theme cycler, the display-mode
watcher, and the aerospace `alt-shift-r` (service mode) binding all use
kickstart for this reason.

## Roll back to the classic bar

```bash
mv ~/.config/sketchybar ~/.config/sketchybar-islands
cp -Rp ~/.config/sketchybar-classic ~/.config/sketchybar
launchctl kickstart -k gui/$(id -u)/homebrew.mxcl.sketchybar
```

Note: classic's event handling (workspace highlight, Spotify title, volume
icon) is subject to the same v2.24 module quirks; if it comes back dead, the
kickstart-instead-of-reload rule applies there too.

## Return to Islands later

```bash
mv ~/.config/sketchybar ~/.config/sketchybar-classic-active
mv ~/.config/sketchybar-islands ~/.config/sketchybar
launchctl kickstart -k gui/$(id -u)/homebrew.mxcl.sketchybar
```

## Architecture crib sheet

- **The root cause of the night-long event breakage:** sketchybar v2.24 runs a
  config-script watchdog that SIGKILLs the config script's process group
  ~60 seconds after launch (it expects shell configs that exit). SbarLua's
  resident event-loop process was being reaped every boot, silently killing
  all event handling (this also broke the classic config from the June 22
  daemon restart onward). The fix: `sketchybarrc` only pkills the previous
  generation and spawns `rc-runner.sh` in a NEW SESSION (python
  `start_new_session`), then exits immediately. The runner (retry + lifecycle
  log at `/tmp/rc_trace.log`) runs `rc.lua`, which is the real config.
- Theme flavor persists in `~/.config/sketchybar/flavor`
  (`mocha` | `macchiato` | `frappe`); click the dot at the far right of the
  bar to cycle. Missing file = mocha.
- Display mode (`wide` vs `notch`) is detected from
  `aerospace list-monitors` (only Built-in monitors present = notch); the
  watcher kickstarts the bar when it changes (dock/undock). Media island sits
  at `center` on the ultrawide, `q` (left of the notch) on the MacBook.
- `stats_provider` (brew: `joncrangle/tap/sketchybar-system-stats`) pushes the
  `system_stats` event (CPU/RAM/disk/net) every 2s; it boots from stats.lua
  with a 3s delay (booting it while the bar processes config kills it).
- AeroSpace mode indicator relies on `aerospace_mode_change` triggers added to
  every mode-switch binding in `~/.config/aerospace/aerospace.toml`
  (backup: `aerospace.toml.pre-islands.bak`).

## Hard-won gotchas (2026-07-09 debugging session)

1. NEVER `sbar.add("graph", ...)` — segfaults the module against sketchybar
   v2.24. The CPU widget is a plain percent label for this reason. If a graph
   is wanted, create it via the CLI (`sketchybar --add graph ...`) and push
   values via CLI from the event handler.
2. NEVER call `sbar.delay()` at config top level (before the event loop) —
   segfault. Inside event handlers it is fine.
3. Any item that sets `drawing = false` on itself MUST also set
   `updates = true`, or the default `when_shown` means its event handlers
   never fire while hidden and it can never wake up (mode, vpn, brew).
4. `sbar.exec` JSON-parses command output: callbacks receive a Lua TABLE when
   the output is valid JSON, a string otherwise. Handle both.
5. Do not pass an empty `{}` config table to `sbar.add` — it serializes as a
   dangling `--set` that swallows the next batched command.
6. Custom events must be `sbar.add("event", ...)`-registered before items
   subscribe; a provider registering the event later is too late.
7. Bracket regex membership is evaluated at creation time only; islands
   containing async-created items (spaces, media) are rebuilt afterwards
   (see spaces.lua / media.lua).

## Module state

- Active: `~/.local/share/sketchybar_lua/sketchybar.so` = the 2026-03-11
  build (verified working tonight).
- `sketchybar.so.head-2026-07-09` = SbarLua HEAD build (vendored Lua 5.5),
  behaved identically in testing; kept as an alternative.
- `sketchybar.so.mar11-backup` = spare copy of the active module.
- If SbarLua is ever rebuilt, the interpreter in `sketchybarrc` must match
  the Lua the module expects (HEAD vendors 5.5; `/opt/homebrew/bin/lua` is
  5.5). `lua@5.4` is installed if an older SbarLua is ever needed.
