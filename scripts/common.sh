#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE=/var/lib/cs347-lab
NS=(internet hq hqsw br1 br1sw br2 br2sw br3 br3sw pc1 pc2 pc3 users erp mgmt)
need_root() { [[ $EUID == 0 ]] || { echo 'Run with sudo.' >&2; exit 1; }; }
nx() { ip netns exec "cs347-$1" "${@:2}"; }
require_lab() { [[ -f "$STATE/ready" ]] || { echo 'Start the lab first.' >&2; exit 1; }; }
client_start() { nx "$1" openvpn --config "$STATE/config/$1.conf" --daemon; }
