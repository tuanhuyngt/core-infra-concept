# core-infra starter

Một repo duy nhất để quản lý **mọi máy chủ, mọi app, mọi credential** của bạn — và để AI agent (Claude Code) làm việc
trong đó mà không phải đoán. Ý tưởng gốc: **mỗi thông tin chỉ nằm ở MỘT chỗ**.

## Ý tưởng trong 1 phút
| Thứ | Nằm ở | Ghi chú |
|---|---|---|
| Luật + mục lục cho agent | `CLAUDE.md` | agent đọc file này đầu tiên |
| App nào chạy ở máy nào | `fleet.md` | bảng tổng |
| Từng máy chủ | `hosts/<vps>.md` | specs, cách vào, đang chạy gì |
| Domain / subdomain | `domains.md` | host nào trỏ máy nào, thuộc app nào |
| Từng app | `apps/<app>/` | `app.yaml` (chạy ở đâu, port, domain) + `README.md` + code + secret riêng |
| **Mọi credential** | `secrets/*.enc.yaml` | **đã mã hoá** bằng 1 master key → commit lên git được |
| Master key | `secrets/masterkey/keys.txt` | **không bao giờ commit**; mất = mất hết, lộ = lộ hết → sao lưu offline |
| Thử nghiệm nhanh | `lab/` | gitignored, làm xong xoá |

Mã hoá dùng [SOPS](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age): file `.enc.yaml` vẫn đọc được
tên key, chỉ giá trị bị mã hoá. Ai có master key thì giải mã được tất cả.

## Bắt đầu (5 phút)
```bash
# 0. Cần: git, python3 + pyyaml, sops, age  (macOS: brew install sops age · Linux: tải binary từ 2 link trên)
# 1. Copy thư mục này thành repo của bạn
cp -r starter my-infra && cd my-infra
# 2. Tạo master key + các file secret mã hoá + git init
./setup.sh
# 3. Điền credential thật (mở editor, lưu là tự mã hoá lại)
tools/secret edit secrets/vps.enc.yaml        # IP, SSH key, pass của VPS
tools/secret edit secrets/operator.enc.yaml   # token GitHub, Cloudflare, ...
# 4. Vào VPS bằng tên
tools/ssh vps-1
# 5. Mở Claude Code trong repo này và nói việc cần làm, vd: "onboard vps-1", "tạo app X deploy lên vps-1"
```
**Ngay sau bước 2: sao lưu `secrets/masterkey/keys.txt`** vào password manager.

## Lệnh
| Lệnh | Làm gì |
|---|---|
| `tools/secret edit <file>` / `show <file>` / `keys <file>` | sửa · xem · chỉ liệt kê tên key (không in giá trị) |
| `tools/ssh <vps> [lệnh…]` | SSH vào máy khai trong `secrets/vps.enc.yaml` |
| `tools/lab new <slug>` · `run <nhóm> -- <lệnh>` · `ls` · `repo <dir>` | thử nghiệm nhanh, bơm token vào env của lệnh |

## Thêm thứ mới
- **VPS mới**: thêm khối vào `secrets/vps.enc.yaml` → copy `hosts/_template.md` → thêm dòng vào `fleet.md`.
- **App mới**: copy `apps/_template/` → `apps/<app>/` → điền `app.yaml` → thêm dòng vào `fleet.md` và `hosts/<vps>.md`.
- **Đưa app lên mạng** (deploy, nginx, subdomain, HTTPS): 6 bước trong `CLAUDE.md` → "Đưa app lên mạng".
- **Token mới**: thêm nhóm vào `secrets/operator.enc.yaml` (`<tên>: { <key>: "..." }`) — `tools/lab run <tên> -- …` dùng được ngay.
