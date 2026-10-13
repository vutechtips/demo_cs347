#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
need_root
require_lab
export EASYRSA_PKI="$STATE/pki" EASYRSA_BATCH=1
mkdir -p "$STATE/rejected"
cp "$STATE/pki/issued/br2.crt" "$STATE/rejected/br2.crt"
cp "$STATE/pki/private/br2.key" "$STATE/rejected/br2.key"
/usr/share/easy-rsa/easyrsa revoke br2
/usr/share/easy-rsa/easyrsa gen-crl
echo '[OK] BR2 revoked, CRL updated. Disconnect/reconnect BR2 to demonstrate rejection.'
pid=$(cat "$STATE/pids/br2.pid")
kill "$pid"
for i in {1..20}; do kill -0 "$pid" 2>/dev/null || break; sleep 0.2; done
sed -e "s|$STATE/pki/issued/br2.crt|$STATE/rejected/br2.crt|" -e "s|$STATE/pki/private/br2.key|$STATE/rejected/br2.key|" "$STATE/config/br2.conf" > "$STATE/config/br2-rejected.conf"
offset=$(wc -l < "$STATE/logs/hq.log")
nx br2 openvpn --config "$STATE/config/br2-rejected.conf" --daemon
for i in {1..20}; do
  if tail -n +"$((offset+1))" "$STATE/logs/hq.log" | grep -q 'certificate revoked'; then
    tail -n +"$((offset+1))" "$STATE/logs/hq.log" | grep 'certificate revoked'
    echo '[PASS] HQ rejected the revoked BR2 certificate.'; exit 0
  fi
  sleep 1
done
echo '[FAIL] No new certificate-revoked evidence; inspect HQ log.'; exit 1
