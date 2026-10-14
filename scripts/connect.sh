#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
need_root
require_lab
site=${1:-}
case "$site" in hq|br1|br2|br3) ;; *) echo 'Usage: connect.sh {hq|br1|br2|br3} [--no-watch]'; exit 1;; esac
if [[ $site != hq ]]; then
  nx hq ip addr show tun0 >/dev/null 2>&1 || { echo 'HQ is offline. Run lab.cmd hq in the HQ window first.'; exit 1; }
fi
if [[ -f "$STATE/pids/$site.pid" ]] && kill -0 "$(cat "$STATE/pids/$site.pid")" 2>/dev/null; then
  echo "[INFO] $site VPN is already running. Showing its log."
else
  echo "Starting $site VPN now..."
  nx "$site" openvpn --config "$STATE/config/$site.conf" --daemon
fi
for attempt in {1..30}; do
  if nx "$site" ip -4 addr show tun0 2>/dev/null | grep -q 'inet 10.255'; then
    echo "[OK] $site tunnel is UP."
    [[ ${2:-} == --no-watch ]] && exit 0
    echo 'Live log below. Ctrl+C stops viewing; VPN keeps running.'
    exec tail -n 20 -F "$STATE/logs/$site.log"
  fi
  sleep 1
done
tail -n 20 "$STATE/logs/$site.log"
echo "[FAIL] $site tunnel did not come up; inspect the log."; exit 1
