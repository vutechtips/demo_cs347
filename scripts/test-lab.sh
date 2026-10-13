#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
need_root
require_lab
for test in erp mgmt branch deny; do bash "$ROOT/scripts/demo.sh" "$test"; done
for host in pc2 pc3; do
  nx "$host" curl --noproxy '*' --cacert "$STATE/web/cert.pem" --max-time 5 -fsS https://10.10.20.10/
done
echo '[PASS] Both other branches reach ERP.'
echo 'Revocation is a separate explicit demo: revoke-br2.sh then restore-br2.sh.'
