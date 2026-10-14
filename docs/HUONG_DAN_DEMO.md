# Hướng dẫn tự thực hành và demo OpenVPN CS347

Thời lượng gợi ý: 8–10 phút. Chạy từng lệnh, quan sát kết quả rồi giải thích trước khi chuyển bài.

## Đọc trước: ba terminal dùng CHUNG một lab

Terminal chỉ là cửa sổ nhập lệnh, không phải một máy mạng. Mở ba terminal không tạo ra ba lab. Các thiết bị HQ/BR1/BR2/BR3 đã được tạo trong Ubuntu bằng namespace khi chạy `start`.

| Việc | Chạy bao nhiêu lần? | Chạy ở đâu? |
|---|---|---|
| `git clone` | Một lần trên mỗi máy | Một terminal bất kỳ; tải mã nguồn |
| `install` | Một lần khi chuẩn bị môi trường | Một terminal bất kỳ; cài gói Ubuntu |
| `cd` vào repo | Mỗi terminal một lần | Cả ba terminal; mỗi cửa sổ có thư mục hiện tại riêng |
| `start` | Một lần cho mỗi lượt dựng lab | Tab 3; tất cả terminal dùng chung lab đó |
| `erp`, `mgmt`, `branch`, `deny` | Mỗi lần muốn thử | Tab 3; tạo lưu lượng thật |
| `wan`, `tunnel`, `log` | Chạy khi muốn quan sát | Tab 1/2; giữ terminal đến khi Ctrl+C |
| `stop` | Một lần khi kết thúc | Tab 3; dừng lab chung |

Không chạy `clone`, `install` hoặc `start` lặp lại ở mỗi terminal. Nếu đã tải repo trên máy này thì chỉ vào thư mục đó.

## Lần đầu trên máy khác: nhập từng lệnh

Mở PowerShell, chạy:

```powershell
wsl -l -v
```

**Đọc kết quả:** phải có `Ubuntu-24.04`, cột VERSION là `2`. Nếu hiện Stopped thì distro chưa chạy, không phải lỗi; launcher sẽ khởi động nó. Nếu chưa có distro:

```powershell
wsl --install -d Ubuntu-24.04
```

Lệnh cài Ubuntu, không tải dự án. Làm theo yêu cầu của Windows; khởi động lại nếu cần và mở Ubuntu để hoàn tất tạo người dùng. Có thể cần PowerShell quản trị cho bước cài WSL.

Tiếp theo, chọn thư mục muốn lưu repo rồi chạy:

```powershell
git clone https://github.com/vutechtips/demo_cs347.git
```

**Giải thích:** Git tải mã nguồn vào thư mục `demo_cs347`; chưa có VPN nào chạy. Nếu PowerShell không tìm thấy `git`, cần cài Git trước hoặc tải ZIP repo từ GitHub và giải nén.

```powershell
cd demo_cs347
```

**Giải thích:** chuyển terminal hiện tại vào thư mục dự án. Chạy `pwd` để biết đường dẫn, ghi lại để các tab khác vào cùng nơi.

```powershell
dir lab.cmd
```

**Đọc kết quả:** thấy file `lab.cmd` là đã vào đúng thư mục. Nếu không thấy, chưa chạy các lệnh demo; tìm lại thư mục chứa file.

```powershell
.\lab.cmd install
```

**Giải thích:** launcher gọi Ubuntu WSL để cài OpenVPN, Easy-RSA, nftables, tcpdump và các công cụ cần thiết. Log cài gói có thể dài. Lệnh này cần Internet, chỉ chuẩn bị môi trường, không chạy testcase. Đợi lệnh kết thúc và quay lại dấu nhắc PowerShell.

## Lần này trên máy bạn: mở terminal đúng thứ tự

Máy hiện tại đã clone và cài gói, bỏ qua phần cài lần đầu.

**Tab 1:** mở PowerShell, nhập:

```powershell
cd E:\baitap\openvpn-netns-lab
```

**Tab 2:** mở PowerShell mới, nhập cùng lệnh:

```powershell
cd E:\baitap\openvpn-netns-lab
```

**Tab 3:** mở PowerShell mới, nhập cùng lệnh:

```powershell
cd E:\baitap\openvpn-netns-lab
```

`cd` không tạo hoặc khởi động mạng. Ba tab cùng đọc mã nguồn trong một thư mục; mỗi tab vẫn có thể chạy một tác vụ riêng. Trên máy khác hãy thay đường dẫn trên bằng vị trí repo của máy đó.

Khi thấy ví dụ `.\lab.cmd erp`: ` .\ ` chỉ file trong thư mục hiện tại; `lab.cmd` là launcher Windows; `erp` là bài demo được chọn. Bên dưới, launcher chạy script trong Ubuntu với quyền root để thao tác network namespace.

## Cách đọc lệnh và kết quả trước khi tiếp tục

- `start`, `status`, `erp`, `mgmt`, `branch`, `deny`, `revoke`, `restore`, `stop` kết thúc rồi trả lại dấu nhắc: đợi xong trước khi nhập lệnh tiếp.
- `wan`, `tunnel`, `log` chạy liên tục: dùng tab khác để gửi yêu cầu; Ctrl+C khi muốn dùng lại tab đang quan sát.
- `[PASS]` nghĩa là bài kiểm tra đạt kỳ vọng. Với `mgmt` và `deny`, truy cập thất bại mới là đúng.
- `[FAIL]` nghĩa là chưa có bằng chứng đạt yêu cầu. Đọc thông báo, kiểm tra trạng thái/log; không trình bày FAIL như kết quả thành công.
- Counter là số gói/byte rule đã xử lý. Chạy bài kiểm tra nhiều lần thì counter tăng; không cần giống số minh họa.

Sau phần chuẩn bị, thực hiện mục 2–9 bên dưới theo thứ tự. Mỗi mục có tab, lệnh, kết quả và lời giải thích để bạn đọc ngay sau khi chạy.

## 1. Chuẩn bị

Máy cần Windows có Ubuntu 24.04 trong WSL2 và Git. Lab không dùng VMware hay Docker; WSL2 vẫn sử dụng ảo hóa nhẹ. OpenVPN và firewall chạy thật. WAN là mạng giả lập cô lập trên máy, không phải Internet bên ngoài.

Trên máy đang làm dự án, mở **3 tab PowerShell**, mỗi tab chạy:

```powershell
cd E:\baitap\openvpn-netns-lab
```

Trên máy khác, tải dự án trước:

```powershell
git clone https://github.com/vutechtips/demo_cs347.git
cd demo_cs347
.\lab.cmd install
```

Sau đó mở 3 tab cùng vào thư mục vừa clone. `install` chỉ cần chạy lần đầu; cần Internet lúc cài gói. Các lệnh dưới đây chạy trong thư mục chứa `lab.cmd`.

| Tab | Vai trò |
|---|---|
| Tab 1 | Trạng thái, bắt gói WAN hoặc log HQ |
| Tab 2 | Bắt gói tunnel |
| Tab 3 | Chủ động thực hiện các bài kiểm tra |

## 2. Dựng lab — Tab 3

```powershell
.\lab.cmd start
```

Kết quả cần thấy:

```text
[OK] 3 VPN tunnels established. Tests have NOT run automatically.
```

Nếu báo namespace đã tồn tại, lab đang chạy. Muốn bắt đầu một lượt mới:

```powershell
.\lab.cmd stop
.\lab.cmd start
```

**Lời trình bày:**

> Nhóm dựng HQ và ba chi nhánh bằng Linux network namespace. Mỗi gateway có interface, bảng định tuyến, firewall và tiến trình OpenVPN riêng. Script chỉ dựng môi trường; nhóm sẽ chủ động thực hiện từng bài kiểm tra.

## 3. Giới thiệu topology và kết nối — Tab 1

```powershell
.\lab.cmd status
```

Trong các dòng `CLIENT_LIST`, tìm `br1`, `br2`, `br3`. Phía dưới là cấu hình nftables cùng counter.

| Thành phần | IP |
|---|---|
| WAN chung / Switch0 | 198.51.100.0/24 |
| HQ WAN | 198.51.100.10 |
| BR1 WAN / PC2 | 198.51.100.11 / 10.20.10.10 |
| BR2 WAN / PC3 | 198.51.100.12 / 10.30.10.10 |
| BR3 WAN / PC4 | 198.51.100.13 / 10.40.10.10 |
| HQ Users / PC0 | 10.10.10.10 |
| HQ ERP / Server0 | 10.10.20.10 |
| HQ Management / PC1 | 10.10.30.10 |
| Pool tunnel | 10.255.0.0/24 |

**Lời trình bày:**

> HQ đóng vai trò hub; các chi nhánh là spoke. OpenVPN chạy UDP cổng 1194. Switch LAN dùng Linux bridge; HQ phân tách Users, ERP và Management bằng VLAN.

WAN và LAN chi nhánh bám ảnh Packet Tracer. IP HQ và VLAN là giả định theo đoạn chat gốc, chưa đối chiếu file `.pka`. Namespace `pc1`, `pc2`, `pc3` là PC chi nhánh 1, 2, 3, tương ứng PC2, PC3, PC4 trong ảnh.

## 4. BR1 truy cập ERP được phép — Tab 3

```powershell
.\lab.cmd erp
```

Kết quả cần thấy:

```text
ERP-HQ
[PASS] ERP reachable over VPN
```

**Lời trình bày:**

> Máy trạm BR1 gửi yêu cầu HTTPS tới ERP. Gói đi qua gateway BR1, tunnel OpenVPN, firewall HQ rồi tới ERP. Rule cho phép TCP/443 nên dịch vụ trả lời thành công.

Luồng: `PC2 → Switch2 → BR1-RTR → VPN → HQ-RTR → Switch1/VLAN20 → Server0`.

`ERP-HQ` là phản hồi của endpoint HTTPS dùng để kiểm thử, không phải phần mềm ERP đầy đủ. Script xác minh chứng chỉ HTTPS bằng chứng chỉ demo.

## 5. BR1 truy cập Management bị chặn — Tab 3

```powershell
.\lab.cmd mgmt
```

Chờ khoảng 3 giây. Curl báo timeout, nhưng bài kiểm tra phải kết thúc bằng:

```text
[PASS] HQ management drop counter increased: ... -> ...
```

**Lời trình bày:**

> Truy cập thất bại là kết quả mong muốn. Counter của rule chặn Management tăng, chứng minh lưu lượng đã đến firewall HQ và bị chặn; nhóm không chỉ dựa vào timeout để kết luận.

Ở Tab 1 chạy lại:

```powershell
.\lab.cmd status
```

Tìm counter `mgmt_denied`. Số gói cụ thể có thể khác giữa các lượt demo.

## 6. Kiểm tra giữa hai chi nhánh — Tab 3

Cho phép BR1 đến dịch vụ HTTPS tại BR2:

```powershell
.\lab.cmd branch
```

Kết quả:

```text
BR2-HTTPS
[PASS] BR1 -> BR2 TCP/443 allowed
```

Kiểm tra ICMP bị chặn:

```powershell
.\lab.cmd deny
```

Ping báo mất gói và bài kiểm tra kết thúc bằng:

```text
[PASS] HQ default-deny counter increased
```

**Lời trình bày:**

> Luồng BR1 đến BR2 phải qua hub HQ và được kiểm soát bởi nftables. HTTPS được cho phép, còn ICMP bị default deny. Nhóm không bật client-to-client để tránh luồng liên chi nhánh đi tắt bên trong OpenVPN và bỏ qua firewall kernel HQ.

## 7. Bắt gói WAN và tunnel — Cả 3 tab

**Tab 1:**

```powershell
.\lab.cmd wan
```

**Tab 2:**

```powershell
.\lab.cmd tunnel
```

**Tab 3:**

```powershell
.\lab.cmd erp
```

Nếu cần thêm lưu lượng, chạy lại `erp`.

| Vị trí | Dấu hiệu cần chỉ cho giám khảo |
|---|---|
| Tab 1 — WAN | IP 198.51.100.11 và 198.51.100.10; UDP/1194 |
| Tab 2 — tun0 | IP 10.20.10.10 và 10.10.20.10; TCP/443 |

Cổng nguồn phía client có thể thay đổi. tcpdump có thể hiển thị tên dịch vụ như `https` thay vì số 443.

**Lời trình bày:**

> Trên WAN, ta thấy gói OpenVPN giữa hai địa chỉ WAN. Trên tunnel, ta thấy gói với địa chỉ LAN gốc. Điều này minh họa lớp đóng gói và giải đóng gói VPN.

**HTTPS vẫn mã hóa nội dung ứng dụng trên tun0.** Không nói rằng bắt gói tunnel trong bài này đọc được HTTP plaintext.

Nhấn **Ctrl+C riêng ở Tab 1 và Tab 2** để dừng bắt gói. Các VPN vẫn chạy.

## 8. Thu hồi chứng chỉ BR2 và khôi phục

**Tab 1 — theo dõi HQ:**

```powershell
.\lab.cmd log
```

**Tab 3 — thu hồi:**

```powershell
.\lab.cmd revoke
```

Script thực hiện: lưu chứng chỉ cũ để thử lại → thu hồi bằng Easy-RSA → sinh CRL → ngắt BR2 → kết nối lại bằng chứng chỉ cũ.

Kết quả cần thấy:

```text
VERIFY ERROR: ... certificate revoked: CN=br2 ...
[PASS] HQ rejected the revoked BR2 certificate.
```

Easy-RSA có thể in cảnh báo về việc di chuyển/xóa các file chứng chỉ khi revoke. Đây là thao tác thu hồi trên PKI của lab. Không chạy `revoke` lần thứ hai trước khi restore.

**Lời trình bày:**

> Sau khi thu hồi và cập nhật CRL, BR2 dùng chứng chỉ cũ sẽ bị từ chối khi kết nối lại. Thu hồi chứng chỉ không được coi là tự động ngắt ngay phiên đang chạy, nên nhóm chủ động ngắt rồi thử xác thực lại.

**Tab 3 — khôi phục:**

```powershell
.\lab.cmd restore
```

Kết quả cần thấy:

```text
BR2-HTTPS
[PASS] BR2 recovered using a NEW certificate; old serial remains revoked.
```

**Lời trình bày:**

> Nhóm cấp khóa và chứng chỉ mới cho BR2. Chứng chỉ cũ vẫn nằm trong CRL; đây là cấp lại chứng chỉ, không phải làm chứng chỉ cũ hợp lệ trở lại.

Nhấn Ctrl+C ở Tab 1 để thoát xem log.

## 9. Kết thúc

```powershell
.\lab.cmd stop
```

Kết quả:

```text
[OK] Lab stopped; certificates retained.
```

Namespace và tiến trình lab được dọn; chứng chỉ/log vẫn giữ ở `/var/lib/cs347-lab`. Mỗi máy clone repo sẽ tạo PKI riêng. Clone không tự nối VPN giữa hai laptop.

## 10. Bảng lệnh để đặt cạnh màn hình

| Thứ tự | Lệnh | Kết quả mong muốn |
|---|---|---|
| 1 | `.\lab.cmd start` | 3 tunnel lên |
| 2 | `.\lab.cmd status` | Có br1, br2, br3 |
| 3 | `.\lab.cmd erp` | ERP-HQ, PASS |
| 4 | `.\lab.cmd mgmt` | Timeout + counter chặn tăng, PASS |
| 5 | `.\lab.cmd branch` | BR2-HTTPS, PASS |
| 6 | `.\lab.cmd deny` | Ping thất bại + counter tăng, PASS |
| 7 | `wan` ở Tab 1, `tunnel` ở Tab 2, `erp` ở Tab 3 | So sánh header WAN/LAN |
| 8 | Ctrl+C hai tab bắt gói; `log` ở Tab 1 | Xem log HQ |
| 9 | `.\lab.cmd revoke` | certificate revoked, PASS |
| 10 | `.\lab.cmd restore` | BR2 hoạt động bằng chứng chỉ mới |
| 11 | Ctrl+C tab log; `.\lab.cmd stop` | Dọn lab |

## 11. Tự kiểm tra trước buổi bảo vệ

Chạy sau khi start, trước khi revoke:

```powershell
.\lab.cmd test
.\lab.cmd capture
```

`test` kiểm tra policy và ERP từ các chi nhánh. `capture` kiểm tra header WAN/tunnel bằng PCAP thật. Khi thuyết trình nên dùng từng lệnh riêng để giải thích từng bài.

| Lỗi | Cách xử lý |
|---|---|
| Không tìm thấy lab.cmd | Vào đúng thư mục repo; dùng `dir lab.cmd` kiểm tra |
| Không có Ubuntu-24.04 | Kiểm tra `wsl -l -v`; cài distro nếu thiếu |
| Thiếu openvpn/nft/... | Chạy `.\lab.cmd install` |
| Start the lab first | Chạy `.\lab.cmd start` |
| Namespace already exists | Lab đã chạy; dùng status, hoặc stop rồi start |
| Tunnel timeout | Xem log HQ/client trong `/var/lib/cs347-lab/logs` |
| Management timeout kèm PASS | Đây là kết quả đúng của bài chặn |
| ERP báo FAIL | Dừng demo, kiểm tra status/log; không kết luận là firewall đúng |
| Tab tcpdump/log không nhận lệnh mới | Nhấn Ctrl+C để quay lại dấu nhắc |
| Revoke thất bại do chứng chỉ active không còn | Kiểm tra xem đã revoke chưa; restore nếu lab đang chạy |

Đọc cấu hình thực tế tại `scripts/start-lab.sh`, `config/hq.nft`, `config/branch.nft`. Kết quả kiểm thử đã ghi ở [VALIDATION.md](VALIDATION.md).
