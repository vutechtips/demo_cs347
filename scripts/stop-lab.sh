#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
need_root
for n in "${NS[@]}"; do
  if ip netns list | awk '{print $1}' | grep -qx "cs347-$n"; then
    pids=$(ip netns pids "cs347-$n")
    [[ -z "$pids" ]] || kill $pids 2>/dev/null || true
  fi
done
sleep 1
for n in "${NS[@]}"; do
  if ip netns list | awk '{print $1}' | grep -qx "cs347-$n"; then
    pids=$(ip netns pids "cs347-$n")
    [[ -z "$pids" ]] || kill -KILL $pids 2>/dev/null || true
    ip netns del "cs347-$n"
  fi
done
rm -f "$STATE/ready"
echo '[OK] Lab stopped; certificates retained.'
