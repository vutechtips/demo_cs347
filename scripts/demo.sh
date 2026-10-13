#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
need_root
require_lab
fetch() { nx "$1" curl --noproxy '*' --cacert "$STATE/web/cert.pem" --connect-timeout 3 --max-time 5 -fsS "https://$2/"; }
case "${1:-help}" in
  erp)
    echo 'BR1 PC -> gateway -> VPN -> HQ firewall -> ERP HTTPS'
    fetch pc1 10.10.20.10
    echo '[PASS] ERP reachable over VPN';;
  mgmt)
    echo 'BR1 PC -> HQ Management: expected firewall drop'
    before=$(nx hq nft list counter inet lab mgmt_denied | awk '/packets/ {print $2}')
    if fetch pc1 10.10.30.10; then echo '[FAIL] Management unexpectedly accessible'; exit 1; fi
    after=$(nx hq nft list counter inet lab mgmt_denied | awk '/packets/ {print $2}')
    [[ $after -gt $before ]] || { echo '[FAIL] Timeout without management firewall evidence'; exit 1; }
    echo "[PASS] HQ management drop counter increased: $before -> $after";;
  branch)
    echo 'BR1 PC -> VPN -> HQ nftables -> VPN -> BR2 HTTPS'
    fetch pc1 10.30.10.10
    echo '[PASS] BR1 -> BR2 TCP/443 allowed';;
  deny)
    echo 'BR1 PC -> BR2 ICMP: expected default deny'
    before=$(nx hq nft list counter inet lab default_denied | awk '/packets/ {print $2}')
    if nx pc1 ping -c 1 -W 2 10.30.10.10; then echo '[FAIL] ICMP unexpectedly allowed'; exit 1; fi
    after=$(nx hq nft list counter inet lab default_denied | awk '/packets/ {print $2}')
    [[ $after -gt $before ]] || { echo '[FAIL] No HQ default-deny evidence'; exit 1; }
    echo '[PASS] HQ default-deny counter increased';;
  status)
    cat "$STATE/logs/status.txt"
    nx hq nft list table inet lab;;
  wan) nx hq tcpdump -ni wan0 udp port 1194;;
  tunnel) nx hq tcpdump -ni tun0;;
  log) tail -n 40 -f "$STATE/logs/hq.log";;
  *) echo 'Usage: demo.sh {erp|mgmt|branch|deny|status|wan|tunnel|log}';;
esac
