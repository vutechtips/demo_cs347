#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
need_root
require_lab
export EASYRSA_PKI="$STATE/pki" EASYRSA_BATCH=1 EASYRSA_ALGO=ec EASYRSA_CURVE=prime256v1
if [[ -f "$STATE/pids/br2.pid" ]]; then
  pid=$(cat "$STATE/pids/br2.pid")
  kill "$pid" 2>/dev/null || true
  for i in {1..20}; do kill -0 "$pid" 2>/dev/null || break; sleep 0.2; done
fi
# Keep the old certificate revoked; issue a new certificate with the same CN.
/usr/share/easy-rsa/easyrsa gen-req br2 nopass
/usr/share/easy-rsa/easyrsa sign-req client br2
client_start br2
for i in {1..30}; do
  if nx pc1 curl --noproxy '*' --cacert "$STATE/web/cert.pem" --max-time 2 -fsS https://10.30.10.10/; then
    echo '[PASS] BR2 recovered using a NEW certificate; old serial remains revoked.'; exit 0
  fi
  sleep 1
done
echo '[FAIL] BR2 did not reconnect. Inspect logs.'; exit 1
