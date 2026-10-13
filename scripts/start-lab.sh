#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
need_root
for cmd in ip openvpn nft openssl python3 curl; do command -v "$cmd" >/dev/null || { echo "Missing $cmd; run install.sh"; exit 1; }; done
[[ -c /dev/net/tun ]] || { echo 'Missing /dev/net/tun'; exit 1; }
[[ -x /usr/share/easy-rsa/easyrsa ]] || { echo 'Install easy-rsa'; exit 1; }
if ip netns list | awk '{print $1}' | grep -q '^cs347-'; then echo 'Lab namespaces already exist. Run stop-lab.sh first.'; exit 1; fi
umask 077
mkdir -p "$STATE"/{config,ccd,logs,pids,web,captures}
chmod 700 "$STATE"
export EASYRSA_PKI="$STATE/pki" EASYRSA_BATCH=1 EASYRSA_ALGO=ec EASYRSA_CURVE=prime256v1
if [[ ! -f "$STATE/pki/ca.crt" ]]; then
  /usr/share/easy-rsa/easyrsa init-pki
  EASYRSA_REQ_CN=CS347-Lab-CA /usr/share/easy-rsa/easyrsa build-ca nopass
fi
[[ -f "$STATE/pki/issued/hq.crt" ]] || /usr/share/easy-rsa/easyrsa build-server-full hq nopass
for n in br1 br2 br3; do
  [[ -f "$STATE/pki/issued/$n.crt" ]] || /usr/share/easy-rsa/easyrsa build-client-full "$n" nopass
done
[[ -f "$STATE/pki/crl.pem" ]] || /usr/share/easy-rsa/easyrsa gen-crl
[[ -f "$STATE/tls-crypt.key" ]] || openvpn --genkey secret "$STATE/tls-crypt.key"
echo '[OK] PKI: local CA, HQ certificate, 3 branch certificates, CRL'
trap 'echo "Startup failed; cleaning lab namespaces." >&2; bash "$ROOT/scripts/stop-lab.sh"' ERR
for n in "${NS[@]}"; do ip netns add "cs347-$n"; nx "$n" ip link set lo up; done
nx internet ip link add wanbr type bridge
nx internet ip link set wanbr up
for sw in hqsw br1sw br2sw br3sw; do
  nx "$sw" ip link add br0 type bridge vlan_filtering 1
  nx "$sw" ip link set br0 up
done
# HQ Switch1: one trunk uplink; PC0/Server0/PC1 use VLANs 10/20/30.
ip link add clhq type veth peer name clswhq
ip link set clhq netns cs347-hq
ip link set clswhq netns cs347-hqsw
nx hq ip link set clhq name trunk0
nx hq ip link set trunk0 up
nx hqsw ip link set clswhq master br0
nx hqsw ip link set clswhq up
nx hqsw bridge vlan del dev clswhq vid 1
for vlan in 10 20 30; do nx hqsw bridge vlan add dev clswhq vid "$vlan"; done
idx=0
for n in hq br1 br2 br3; do
  idx=$((idx+1))
  ip link add "clw$idx" type veth peer name "cli$idx"
  ip link set "clw$idx" netns "cs347-$n"
  ip link set "cli$idx" netns cs347-internet
  nx "$n" ip link set "clw$idx" name wan0
  nx "$n" ip addr add "198.51.100.$((idx+9))/24" dev wan0
  nx "$n" ip link set wan0 up
  nx internet ip link set "cli$idx" master wanbr
  nx internet ip link set "cli$idx" up
  nx "$n" sysctl -q -w net.ipv4.ip_forward=1
  nx "$n" sysctl -q -w net.ipv4.conf.all.rp_filter=0 net.ipv4.conf.default.rp_filter=0
done
link_lan() {
  local gw=$1 host=$2 iface=$3 subnet=$4 mask=$5 tag=$6
  local sw="${gw}sw"
  if [[ $gw == hq ]]; then
    local vlan=$((tag*10))
    nx hq ip link add link trunk0 name "$iface" type vlan id "$vlan"
    ip link add "cls$tag" type veth peer name "clh$tag"
    ip link set "cls$tag" netns cs347-hqsw
    nx hqsw ip link set "cls$tag" master br0
    nx hqsw ip link set "cls$tag" up
    nx hqsw bridge vlan del dev "cls$tag" vid 1
    nx hqsw bridge vlan add dev "cls$tag" vid "$vlan" pvid untagged
  else
  ip link add "clg$tag" type veth peer name "clh$tag"
  ip link add "clu$tag" type veth peer name "cls$tag"
  ip link set "clg$tag" netns "cs347-$gw"
  ip link set "clh$tag" netns "cs347-$sw"
  ip link set "clu$tag" netns "cs347-$sw"
  nx "$sw" ip link set "clh$tag" master br0
  nx "$sw" ip link set "clh$tag" up
  nx "$sw" ip link set "clu$tag" master br0
  nx "$sw" ip link set "clu$tag" up
  ip link set "cls$tag" netns "cs347-$host"
  nx "$host" ip link set "cls$tag" name eth0
  nx "$gw" ip link set "clg$tag" name "$iface"
  fi
  if [[ $gw == hq ]]; then
  ip link set "clh$tag" netns "cs347-$host"
  nx "$host" ip link set "clh$tag" name eth0
  fi
  nx "$gw" ip addr add "$subnet.1/$mask" dev "$iface"
  nx "$host" ip addr add "$subnet.10/$mask" dev eth0
  nx "$gw" ip link set "$iface" up
  nx "$host" ip link set eth0 up
  nx "$host" ip route add default via "$subnet.1"
}
link_lan hq users users0 10.10.10 24 1
link_lan hq erp erp0 10.10.20 24 2
link_lan hq mgmt mgmt0 10.10.30 24 3
link_lan br1 pc1 lan0 10.20.10 24 4
link_lan br2 pc2 lan0 10.30.10 24 5
link_lan br3 pc3 lan0 10.40.10 24 6
echo '[OK] Isolated WAN + HQ/3 branches + 6 LAN hosts; host routing unchanged'
cat > "$STATE/config/hq.conf" <<EOF
local 198.51.100.10
port 1194
proto udp
dev tun0
topology subnet
server 10.255.0.0 255.255.255.0
disable-dco
ca $STATE/pki/ca.crt
cert $STATE/pki/issued/hq.crt
key $STATE/pki/private/hq.key
dh none
tls-crypt $STATE/tls-crypt.key
tls-version-min 1.2
data-ciphers AES-256-GCM:AES-128-GCM
remote-cert-tls client
crl-verify $STATE/pki/crl.pem
client-config-dir $STATE/ccd
ccd-exclusive
route 10.20.10.0 255.255.255.0
route 10.30.10.0 255.255.255.0
route 10.40.10.0 255.255.255.0
push "route 10.10.10.0 255.255.255.0"
push "route 10.10.20.0 255.255.255.0"
push "route 10.10.30.0 255.255.255.0"
push "route 10.20.10.0 255.255.255.0"
push "route 10.30.10.0 255.255.255.0"
push "route 10.40.10.0 255.255.255.0"
keepalive 5 30
status $STATE/logs/status.txt 1
status-version 2
log-append $STATE/logs/hq.log
writepid $STATE/pids/hq.pid
verb 3
EOF
for i in 1 2 3; do
  n="br$i"; net=$((10+i*10))
  printf 'ifconfig-push 10.255.0.%s 255.255.255.0\niroute 10.%s.10.0 255.255.255.0\n' "$((i+1))" "$net" > "$STATE/ccd/$n"
  cat > "$STATE/config/$n.conf" <<EOF
client
dev tun0
proto udp
remote 198.51.100.10 1194
nobind
disable-dco
ca $STATE/pki/ca.crt
cert $STATE/pki/issued/$n.crt
key $STATE/pki/private/$n.key
tls-crypt $STATE/tls-crypt.key
remote-cert-tls server
verify-x509-name hq name
tls-version-min 1.2
data-ciphers AES-256-GCM:AES-128-GCM
connect-retry 2 5
log-append $STATE/logs/$n.log
writepid $STATE/pids/$n.pid
verb 3
EOF
done
# No client-to-client: branch traffic must traverse the kernel nftables forward hook.
nx hq nft -f "$ROOT/config/hq.nft"
for n in br1 br2 br3; do nx "$n" nft -f "$ROOT/config/branch.nft"; done
nx hq openvpn --config "$STATE/config/hq.conf" --daemon
for n in br1 br2 br3; do client_start "$n"; done
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -days 30 -keyout "$STATE/web/key.pem" -out "$STATE/web/cert.pem" -subj /CN=CS347-Demo -addext 'subjectAltName=IP:10.10.20.10,IP:10.10.30.10,IP:10.30.10.10' >/dev/null 2>&1
for spec in 'erp 10.10.20.10 ERP-HQ' 'mgmt 10.10.30.10 MANAGEMENT-HQ' 'pc2 10.30.10.10 BR2-HTTPS'; do
  read -r n addr label <<< "$spec"
  nohup ip netns exec "cs347-$n" python3 "$ROOT/services/https.py" "$addr" "$STATE/web/cert.pem" "$STATE/web/key.pem" "$label" > "$STATE/logs/$n-service.log" 2>&1 < /dev/null &
done
for attempt in {1..30}; do
  count=0
  for n in br1 br2 br3; do nx "$n" ip -4 addr show tun0 2>/dev/null | grep -q 'inet 10.255' && count=$((count+1)) || true; done
  [[ $count == 3 ]] && break
  sleep 1
done
[[ $count == 3 ]] || { echo 'Tunnel timeout; inspect logs. A revoked certificate needs reissue.'; false; }
touch "$STATE/ready"
trap - ERR
echo '[OK] 3 VPN tunnels established. Tests have NOT run automatically.'
echo 'Next: sudo bash scripts/demo.sh erp'
