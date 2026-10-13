# Kết quả kiểm thử — 14/10/2026 (Asia/Saigon)

Môi trường thực tế: Windows + Ubuntu 24.04 WSL2; kernel `6.18.54.1-microsoft-standard-WSL2`; OpenVPN `2.6.19`; Easy-RSA `3.1.7`; nftables `1.0.9`.

Đã chạy trực tiếp cấu hình WAN/Branch bám ảnh Packet Tracer người dùng cung cấp.

| Kiểm tra | Kết quả và bằng chứng |
|---|---|
| Dựng HQ + 3 branch | 3 interface tun0 có địa chỉ trong pool 10.255.0.0/24 |
| BR1 -> ERP/443 | HTTPS trả về `ERP-HQ`; kiểm tra chứng chỉ bằng CA demo |
| BR1 -> Management/443 | Curl timeout; counter `mgmt_denied` tăng từ 0 lên 3 |
| BR1 -> BR2/443 | HTTPS trả về `BR2-HTTPS` |
| BR1 -> BR2 ICMP | Ping thất bại; counter `default_denied` tăng |
| BR2, BR3 -> ERP/443 | Cả hai trả về `ERP-HQ` |
| WAN packet capture | Có 198.51.100.11 và 198.51.100.10:1194; không có IP LAN trong header WAN |
| Tunnel packet capture | Có 10.20.10.10 và 10.10.20.10:443 |
| Thu hồi chứng chỉ BR2 | Log HQ mới có `VERIFY ERROR ... certificate revoked: CN=br2` |
| Cấp lại BR2 | Khóa/chứng chỉ mới; HTTPS tới BR2 thành công; serial cũ vẫn bị thu hồi |

Không coi đây là kết quả chạy file `.pka`: chưa có file `.pka`, cấu hình HQ là giả định đã ghi trong README. Chưa kiểm thử trên máy tính thứ hai hoặc Linux distro khác. Git clone máy khác được thiết kế để sinh runtime/CA mới, không mang khóa từ máy này.

PCAP và private key được lưu ở `/var/lib/cs347-lab`, không đưa vào Git. Khi làm báo cáo cần mô tả HTTPS còn mã hóa ở lớp ứng dụng trên tun0; capture chứng minh header và lớp đóng gói VPN, không đọc plaintext HTTPS.
