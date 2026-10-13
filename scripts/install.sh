#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
need_root
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y openvpn easy-rsa iproute2 nftables tcpdump curl openssl python3
echo 'Dependencies ready. Next: sudo bash scripts/start-lab.sh'
