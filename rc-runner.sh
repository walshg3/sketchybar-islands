#!/bin/bash
# Detached runner for the SbarLua config. Lives in its own session (spawned
# with setsid by sketchybarrc) so sketchybar v2.24's config-script watchdog,
# which SIGKILLs the config process group ~60s after launch, cannot reap the
# event-loop process. Retries segfaults (module mach-port race at boot).
cd "$(dirname "$0")"
T=/tmp/rc_trace.log
echo "[rc] runner start pid=$$ pgid=$(ps -o pgid= -p $$ | tr -d ' ') t=$(date +%T)" >> "$T"
for attempt in 1 2 3 4 5; do
  /opt/homebrew/bin/lua "$PWD/rc.lua"
  code=$?
  echo "[rc] lua exited code=$code attempt=$attempt t=$(date +%T)" >> "$T"
  [ "$code" -eq 139 ] || break
  sleep 0.6
done
