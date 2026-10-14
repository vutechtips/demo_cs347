# demo_cs347 — Demo OpenVPN site-to-site bằng namespace

Lab OpenVPN thật: HQ làm hub, BR1–BR3 làm spoke. Chạy trên Ubuntu 24.04 hoặc Ubuntu trong WSL2, không cần VMware hay Docker. WSL2 vẫn dùng ảo hóa nhẹ. WAN là mạng cô lập giả lập ISP; không phải Internet bên ngoài.

**Cách demo mới:** `start` chỉ dựng mạng và chứng chỉ. Bạn tự bật HQ, kết nối từng chi nhánh để thấy log realtime, rồi thử routing/firewall/thu hồi chứng chỉ.

## 1. Chuẩn bị một lần trên mỗi máy

Trên Windows kiểm tra:

```cmd
wsl -l -v
```

Cần thấy `Ubuntu-24.04` và VERSION `2`. Nếu chưa có, dùng PowerShell quản trị để cài:

```powershell
wsl --install -d Ubuntu-24.04
```

Làm theo yêu cầu khởi động lại và tạo người dùng Ubuntu. Cần Git trên Windows để clone repo. Mở CMD tại thư mục muốn lưu dự án:

```cmd
git clone https://github.com/vutechtips/demo_cs347.git
cd demo_cs347
lab.cmd install
```

Giải thích: clone tải mã nguồn; install cài OpenVPN, Easy-RSA, nftables, tcpdump và các gói trong Ubuntu. Cần Internet lúc cài; chưa có VPN kết nối. Chỉ clone/install một lần trên mỗi máy.

Máy đã clone muốn lấy bản mới:

```cmd
git pull --ff-only
```

## 2. Mở cửa sổ điều khiển và dựng mạng

Trên máy đang làm dự án, mở CMD:

```cmd
cd /d E:\baitap\openvpn-netns-lab
title DIEU KHIEN DEMO
lab.cmd start
```

Máy khác thay đường dẫn bằng thư mục repo của máy đó. Trong CMD, `cd /d` chuyển cả ổ đĩa và thư mục. PowerShell dùng `cd` và gọi `.\lab.cmd`.

Nếu lab cũ đang chạy, dùng `lab.cmd stop` trước rồi chạy start lại.

Kết quả cần thấy:

```text
[OK] Network ready. HQ and all branches are OFFLINE; no VPN started.
```

**Giải thích:** các gateway, switch, máy LAN, PKI và dịch vụ HTTPS đã sẵn sàng. HQ/BR chưa chạy VPN; chưa có tunnel. Mọi terminal dùng chung lab này, không start riêng từng cửa sổ.

Giữ cửa sổ này để chạy các bài test. Mở thêm bốn cửa sổ CMD dưới đây: tổng cộng 5 cửa sổ, gồm điều khiển, HQ, BR1, BR2, BR3.

## 3. Bật HQ — cửa sổ CMD thứ hai

```cmd
cd /d E:\baitap\openvpn-netns-lab
title HQ - VPN SERVER
lab.cmd hq
```

**Kết quả:** `[OK] hq tunnel is UP` và log server chạy liên tục; có thể thấy `Initialization Sequence Completed`.

**Giải thích:** HQ bắt đầu lắng nghe OpenVPN UDP/1194 và có tunnel 10.255.0.1. HQ lên chưa có nghĩa các chi nhánh đã kết nối. Để cửa sổ mở và quan sát khi bật từng branch.

## 4. Kết nối BR1 — cửa sổ CMD thứ ba

```cmd
cd /d E:\baitap\openvpn-netns-lab
title BR1 - VPN CLIENT
lab.cmd br1
```

**Kết quả:** `[OK] br1 tunnel is UP`; log BR1 có `Initialization Sequence Completed`. Cửa sổ HQ xuất hiện log xác thực/kết nối liên quan `br1`.

**Giải thích khi demo:** “BR1 xác thực với HQ bằng chứng chỉ riêng. Sau khi được chấp nhận, BR1 có địa chỉ tunnel 10.255.0.2 và các route cần thiết.”

## 5. Kết nối BR2 — cửa sổ CMD thứ tư

```cmd
cd /d E:\baitap\openvpn-netns-lab
title BR2 - VPN CLIENT
lab.cmd br2
```

**Kết quả:** BR2 hoàn thành kết nối; HQ xuất hiện `br2`. Tunnel BR2 là 10.255.0.3.

**Giải thích:** BR2 dùng chứng chỉ riêng và sở hữu LAN 10.30.10.0/24. HQ biết phải chuyển lưu lượng đến LAN đó qua BR2.

## 6. Kết nối BR3 — cửa sổ CMD thứ năm

```cmd
cd /d E:\baitap\openvpn-netns-lab
title BR3 - VPN CLIENT
lab.cmd br3
```

**Kết quả:** BR3 hoàn thành kết nối; HQ xuất hiện `br3`. Tunnel BR3 là 10.255.0.4.

**Giải thích:** ba chi nhánh kết nối độc lập vào cùng hub HQ. Đây là site-to-site vì VPN phục vụ các LAN phía sau gateway.

Các cửa sổ log có thể im lặng khi không có sự kiện mới. Ctrl+C chỉ dừng xem log, VPN vẫn chạy. Chạy lại `lab.cmd hq`/`br1`/`br2`/`br3` sẽ tiếp tục xem log, không tạo thêm VPN nếu site đã chạy. Muốn dừng toàn bộ lab dùng `lab.cmd stop`.

## 7. Xác nhận kết nối — quay lại cửa sổ điều khiển

```cmd
lab.cmd status
```

**Kết quả:** có 3 dòng `CLIENT_LIST` chứa br1, br2, br3; mã hóa `AES-256-GCM`. File trạng thái cập nhật mỗi giây; nếu chưa đủ client, chạy status lại sau một giây.

`ROUTING_TABLE` thể hiện LAN nào thuộc branch nào. Counter firewall đang là 0 nếu chưa test. `status` chỉ đọc thông tin, không gửi bài kiểm tra.

## 8. BR1 truy cập ERP — được phép

```cmd
lab.cmd erp
```

**Kết quả:** `ERP-HQ` và `[PASS] ERP reachable over VPN`.

**Giải thích:** PC BR1 đi qua switch, gateway BR1, tunnel, firewall HQ rồi đến ERP 10.10.20.10 bằng HTTPS/TCP443. Policy cho phép nên nhận được phản hồi thật. ERP ở đây là endpoint HTTPS kiểm thử, không phải ứng dụng ERP đầy đủ.

Chạy `lab.cmd status` để xem counter `erp_allowed` tăng.

## 9. BR1 truy cập Management — bị chặn

```cmd
lab.cmd mgmt
```

**Kết quả:** chờ khoảng 3 giây; curl timeout và `[PASS] HQ management drop counter increased: ... -> ...`.

**Giải thích:** thất bại truy cập là kết quả mong muốn. Counter `mgmt_denied` tăng chứng minh gói đã đến firewall HQ và bị chặn, không chỉ suy đoán từ timeout. Số counter có thể khác mỗi lần chạy.

## 10. Policy giữa hai chi nhánh

```cmd
lab.cmd branch
```

**Kết quả:** `BR2-HTTPS` và PASS. BR1 truy cập dịch vụ HTTPS tại PC BR2 được phép.

```cmd
lab.cmd deny
```

**Kết quả:** ping thất bại, counter default deny tăng và PASS.

**Giải thích:** cùng nguồn/đích nhưng HTTPS được phép, ICMP bị chặn. Luồng giữa hai branch qua kernel HQ và nftables; không bật `client-to-client` hoặc DCO trong lab để bảo đảm luồng không đi tắt khỏi firewall HQ.

## 11. Bắt gói realtime

Giữ bốn cửa sổ HQ/BR nếu muốn. Mở thêm hai CMD, cùng vào thư mục repo.

**CMD bắt gói WAN:**

```cmd
lab.cmd wan
```

**CMD bắt gói tunnel:**

```cmd
lab.cmd tunnel
```

**Cửa sổ điều khiển:**

```cmd
lab.cmd erp
```

| Quan sát | Kết quả mong muốn |
|---|---|
| WAN | 198.51.100.11 ↔ 198.51.100.10, UDP/1194 |
| Tunnel | 10.20.10.10 ↔ 10.10.20.10, TCP/443 |

**Giải thích:** WAN thấy gói OpenVPN giữa các IP WAN; tunnel thấy header IP LAN gốc. HTTPS vẫn mã hóa nội dung ứng dụng trên tun0, không đọc được plaintext HTTPS từ bài này. tcpdump có thể hiện tên `https` thay số 443.

Ctrl+C ở hai cửa sổ bắt gói để kết thúc quan sát. Nếu ít màn hình, dùng Ctrl+C ở hai cửa sổ log BR rồi chạy wan/tunnel trong chính các cửa sổ đó; VPN vẫn hoạt động.

## 12. Thu hồi chứng chỉ BR2 — xem đồng thời HQ và BR2

Tại cửa sổ điều khiển:

```cmd
lab.cmd revoke
```

**Kết quả:** HQ có `VERIFY ERROR ... certificate revoked: CN=br2`, bài thử báo PASS; BR2 có lỗi xác thực/kết nối.

**Giải thích:** Easy-RSA thu hồi chứng chỉ BR2 và sinh CRL. Script chủ động ngắt BR2 rồi kết nối lại bằng chứng chỉ cũ để chứng minh HQ từ chối. Thu hồi không được coi là tự động ngắt ngay phiên TLS đang tồn tại. Không chạy revoke lần hai trước khi restore.

```cmd
lab.cmd restore
```

**Kết quả:** BR2 kết nối lại, HTTPS trả `BR2-HTTPS` và PASS.

**Giải thích:** BR2 được cấp khóa/chứng chỉ MỚI; serial cũ vẫn nằm trong CRL. Bốn cửa sổ log đang theo dõi file sẽ tiếp tục hiển thị sự kiện mới.

## 13. Kết thúc và tự luyện lại

```cmd
lab.cmd stop
```

Kết quả `Lab stopped; certificates retained`. Namespace/tiến trình lab được dọn; PKI và log giữ ở `/var/lib/cs347-lab`. Ctrl+C để thoát các cửa sổ xem log. Khi tập lại: start → hq → br1 → br2 → br3 → testcase.

Sau khi đủ ba branch kết nối, có thể tự kiểm tra nhanh:

```cmd
lab.cmd test
lab.cmd capture
```

Hai lệnh kiểm tra policy và capture thật; khi bảo vệ nên chạy từng testcase để giải thích.

## Topology và phạm vi

| Thiết bị trong ảnh Packet Tracer | Namespace | Địa chỉ |
|---|---|---|
| Switch0 / WAN | cs347-internet / wanbr | 198.51.100.0/24 |
| HQ-RTR | cs347-hq | WAN 198.51.100.10 (giả định) |
| Switch1 | cs347-hqsw | Trunk VLAN10/20/30 (giả định) |
| PC0 / Users | cs347-users | 10.10.10.10/24 |
| Server0 / ERP | cs347-erp | 10.10.20.10/24 |
| PC1 / Management | cs347-mgmt | 10.10.30.10/24 |
| BR1-RTR / Switch2 / PC2 | cs347-br1 / br1sw / pc1 | WAN .11; LAN 10.20.10.0/24 |
| BR2-RTR / Switch3 / PC3 | cs347-br2 / br2sw / pc2 | WAN .12; LAN 10.30.10.0/24 |
| BR3-RTR / Switch4 / PC4 | cs347-br3 / br3sw / pc3 | WAN .13; LAN 10.40.10.0/24 |

Gateway LAN là .1, PC là .10. Switch dùng Linux bridge; gateway Linux không chạy Cisco IOS. Namespace cô lập interface, route và firewall nhưng dùng chung kernel. CCD `iroute` xác định LAN thuộc branch; `route` đưa gói từ kernel HQ vào tunnel.

Ảnh chưa có IP/VLAN/ACL HQ và chưa có file `.pka`; phần HQ là giả định theo đoạn chat. Mỗi máy clone tạo một lab và CA riêng; không tự nối hai laptop với nhau. Private key và PCAP nằm ngoài repo, không đẩy lên GitHub. Đây là lab học tập, không phải cấu hình production.

## Lỗi thường gặp

| Hiện tượng | Cách xử lý |
|---|---|
| CMD vẫn ở C: | Dùng `cd /d` khi vào ổ E: |
| Không tìm thấy lab.cmd | Dùng `dir lab.cmd` để kiểm tra đúng thư mục |
| HQ is offline | Chạy `lab.cmd hq` trước branch |
| Namespace already exists | Dùng lab đang chạy hoặc stop rồi start |
| Start the lab first | Chạy start rồi bật từng site |
| Tunnel timeout | Xem log HQ/client trong /var/lib/cs347-lab/logs |
| Management timeout kèm PASS | Kết quả đúng của bài chặn |
| Log không trả lại dấu nhắc | Dùng Ctrl+C; VPN vẫn chạy |
| Test báo FAIL | Kiểm tra status/log, không coi đó là demo đạt |

## Chạy trên Ubuntu trực tiếp

```bash
sudo bash scripts/install.sh
sudo bash scripts/start-lab.sh
# Mỗi lệnh dưới chạy trong một terminal riêng, bật HQ trước.
sudo bash scripts/connect.sh hq
sudo bash scripts/connect.sh br1
sudo bash scripts/connect.sh br2
sudo bash scripts/connect.sh br3
# Terminal điều khiển:
sudo bash scripts/demo.sh erp
sudo bash scripts/stop-lab.sh
```

Tài liệu thêm: [hướng dẫn chi tiết](docs/HUONG_DAN_DEMO.md), [kết quả kiểm thử](docs/VALIDATION.md). Cấu hình chính: `scripts/start-lab.sh`, `scripts/connect.sh`, `config/hq.nft`, `config/branch.nft`. Tham khảo [OpenVPN 2.6 manual](https://openvpn.net/community-docs/community-articles/openvpn-2-6-manual.html).
