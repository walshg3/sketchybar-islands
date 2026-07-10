# SketchyBar Claude Notification Widget: Design

Date: 2026-05-04
Status: Draft (awaiting user review)
Working directory: `/Users/gregwalsh/.config/sketchybar/`

## Goal

Add a SketchyBar widget that surfaces a count of pending Claude notifications. "Pending" combines two sources:

1. macOS Notification Center entries posted by the Claude Desktop app (`com.anthropic.claudefordesktop`) since the user last clicked the widget.
2. Claude Code hook fires (`Notification`, `Stop`) since the user last clicked the widget.

Clicking the widget opens `Claude.app` and clears both counts.

## Non-goals

- Showing notification *content* (titles, bodies). Count only.
- Capturing notifications from other Anthropic surfaces (CLI without hooks, web chat in a browser, mobile).
- Surfacing per-session detail. The widget aggregates across all Claude Code sessions.

## Architecture overview

One new SketchyBar item, `widgets.claude`, modeled on the existing `items/widgets/messages.lua`. The widget owns two small state files under `~/.config/sketchybar/state/` and two input channels:

| Channel | Source | Refresh trigger |
| --- | --- | --- |
| Notification Center | SQLite query against `usernoted` DB filtered by Claude `app_id` and `delivered_date > last_seen` | `routine` (30s) and `system_woke` |
| Claude Code hooks | `wc -l` of append-only log written by hooks | Custom event `claude_notification` plus the routine poll |

Both counts are summed; the icon plus integer label is drawn when total > 0 and hidden when total = 0.

## File layout

New or modified files:

- `items/widgets/claude.lua` (new): widget definition, polling, click handler.
- `items/widgets/init.lua` (modified): `require "items.widgets.claude"`.
- `icons.lua` (modified): add a `claude` SF Symbol entry (placeholder: bell `􀋙` or sparkle `􀛹`, finalized at implementation time).
- `colors.lua` (modified): add a `widgets.claude` section mirroring `widgets.messages`.
- `~/.claude/settings.json` (modified, outside this repo): append `Notification` and `Stop` hooks; existing hooks preserved.
- `~/.config/sketchybar/state/` (new directory)
  - `claude_last_seen`: single line, Cocoa-epoch timestamp of last click. Seeded to current Cocoa time on first run so historical notifications do not flood the badge.
  - `claude_pending`: append-only log; one line per Claude Code hook fire. Truncated on click.

## Data flow

```
[Claude Desktop notification]
        |
        v
usernoted SQLite (record table) ----+
                                    |
[Claude Code Notification/Stop hook]|
        |                           |
        v                           |
~/.config/sketchybar/state/         |
  claude_pending (append) ----------+
        |                           |
        | sketchybar --trigger      |
        | claude_notification       |
        v                           v
                widgets.claude (Lua)
                        |
                        | poll: notif_count = SQL(record WHERE delivered_date > last_seen)
                        | poll: hook_count  = wc -l claude_pending
                        | total = notif_count + hook_count
                        v
                  bar: <icon> <total>   (hidden when total = 0)

mouse.clicked:
  open -a "Claude"
  echo $(($(date +%s) - 978307200)) > claude_last_seen
  : > claude_pending
  redraw
```

## Notification Center query

The macOS notification database lives at `~/Library/Group Containers/group.com.apple.usernoted/db2/db`. Reading it requires Full Disk Access. The existing `messages.lua` widget already relies on FDA for `chat.db`, so the assumption is that FDA is granted to the relevant process; if not, the count will silently be 0.

Schema in scope:

- `record(rec_id, app_id, uuid, data, request_date, request_last_date, delivered_date, presented, style, snooze_fire_date)`
- `app(app_id, identifier)`: `identifier='com.anthropic.claudefordesktop'` resolves to a stable `app_id` (currently `153` on this machine, but resolved by lookup, not hardcoded).

Query (run inside the polling handler):

```sh
last_seen=$(cat ~/.config/sketchybar/state/claude_last_seen 2>/dev/null || echo 0)
sqlite3 ~/Library/Group\ Containers/group.com.apple.usernoted/db2/db \
  "SELECT COUNT(*) FROM record
   WHERE app_id = (SELECT app_id FROM app WHERE identifier='com.anthropic.claudefordesktop')
   AND delivered_date > $last_seen;"
```

`delivered_date` uses the Cocoa epoch (seconds since 2001-01-01). All values stored on disk by this widget are also Cocoa-epoch, so the comparison is unit-correct without conversion. Conversion to Unix epoch is only needed at the click handler boundary (`unix - 978307200`).

If the inner subquery returns NULL (Claude bundle not present in the `app` table yet, e.g. before the first ever notification), the outer query yields 0. That is the intended behavior.

## Hook count

No SQL. The hook count is the line count of `claude_pending`:

```sh
[ -f ~/.config/sketchybar/state/claude_pending ] && wc -l < ~/.config/sketchybar/state/claude_pending || echo 0
```

Appends of short lines on a local filesystem are atomic enough for this use case; `wc -l` tolerates a missing trailing newline. No file lock required.

## Claude Code hook configuration

Added to `~/.claude/settings.json` (merged with any existing `hooks` block, not overwritten):

```json
"hooks": {
  "Notification": [{
    "hooks": [{
      "type": "command",
      "command": "mkdir -p ~/.config/sketchybar/state && echo $(date +%s) >> ~/.config/sketchybar/state/claude_pending && sketchybar --trigger claude_notification 2>/dev/null || true"
    }]
  }],
  "Stop": [{
    "hooks": [{
      "type": "command",
      "command": "mkdir -p ~/.config/sketchybar/state && echo $(date +%s) >> ~/.config/sketchybar/state/claude_pending && sketchybar --trigger claude_notification 2>/dev/null || true"
    }]
  }]
}
```

Notes:

- The trailing `2>/dev/null || true` ensures hook chains succeed even when SketchyBar is not running. The line is still appended to `claude_pending`, so the next polling tick picks it up.
- The Unix timestamp written to `claude_pending` is informational only (the file is line-counted, not parsed); it makes manual inspection easier.

## Widget event subscriptions and display

The Lua widget subscribes to:

- `routine` and `system_woke`: re-poll both channels (matches `messages.lua`).
- `claude_notification` (custom): re-poll immediately.
- `mouse.clicked`: open Claude, write current Cocoa timestamp to `claude_last_seen`, truncate `claude_pending`, force redraw.

Display logic:

```
total = notif_center_count + hook_count
drawing = total > 0
label.string = drawing and tostring(total) or ""
icon.drawing = drawing
```

`update_freq = 30` mirrors the existing messages widget.

## Click handler

On `mouse.clicked`:

```sh
open -a "Claude"
echo $(($(date +%s) - 978307200)) > ~/.config/sketchybar/state/claude_last_seen
: > ~/.config/sketchybar/state/claude_pending
```

Then a synchronous re-poll so the badge clears immediately rather than waiting for the next 30s tick.

If `Claude.app` is not installed, `open -a "Claude"` errors and the click is effectively a clear-only operation. That is acceptable; the widget is still useful as a passive indicator.

## Error handling

The bar must never crash; degrading to 0 is preferred over surfacing errors.

- Missing state files: handled by `cat ... 2>/dev/null || echo 0` and `[ -f ... ]` guards.
- First run: seed `claude_last_seen` with current Cocoa time inside the widget on load if the file is absent, so a fresh install does not show every historical notification.
- DB locked or corrupt: `sqlite3` returns non-zero or empty; the Lua handler coerces with `tonumber(out) or 0`. No retry; the next routine tick re-polls.
- Bundle identifier changes upstream: subquery returns NULL, outer count is 0. The Lua file carries one comment pointing at the identifier so a future fix is obvious.
- Hook fires while SketchyBar is down: `--trigger` failure is swallowed; the append still happens; next poll catches up.
- Concurrent hook writes: short-line appends are atomic on local FS; `wc -l` is tolerant.

## Testing approach

Manual, since the repo has no test harness.

1. Notification Center channel:
   - Trigger a real notification from Claude Desktop (send a long message and switch away).
   - Confirm the badge appears with count 1; trigger another, confirm count 2.
   - Click; confirm Claude opens, badge clears, `claude_last_seen` updates.

2. Hook channel:
   - Manually: `echo test >> ~/.config/sketchybar/state/claude_pending && sketchybar --trigger claude_notification`. Count increments.
   - Start a Claude Code session and let a `Notification` or `Stop` hook fire naturally. Count increments.
   - Click; `claude_pending` is empty; count is 0.

3. Combined:
   - Generate one of each, confirm count is 2, single click clears both.

4. Edge cases:
   - Delete state files; no crash, count stays 0.
   - `system_woke` after sleep; routine poll fires.
   - Claude.app not running; click still opens it.

## Open questions / follow-ups

- Final icon choice (placeholder will be bell or sparkle; can be revisited once visible in the bar).
- Whether to add a `right_click` "clear without opening" affordance later. Not in scope for v1.
- Whether to extend hooks to additional events (e.g. `SubagentStop`, `SessionEnd`). Not in scope for v1; current pair (`Notification`, `Stop`) covers the "needs attention" cases.
