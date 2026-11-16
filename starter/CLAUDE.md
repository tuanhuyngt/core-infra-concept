# Core Infra — MỤC LỤC (đọc file này đầu tiên)

Repo = **danh bạ hạ tầng + monorepo app**. Mọi thứ có đúng MỘT nguồn. Đừng đoán, đừng hardcode.

## Cần gì → đọc đâu
| Cần biết | Đọc ở |
|---|---|
| App / service nào chạy ở máy nào | `fleet.md` |
| 1 máy: specs, access, đang chạy gì | `hosts/<vps>.md` |
| Domain / subdomain trỏ đâu | `domains.md` |
| IP / SSH key / pass của máy | `secrets/vps.enc.yaml` (`tools/secret show …`, vào máy: `tools/ssh <vps>`) |
| Credential **vận hành** (GitHub, Cloudflare, cloud…) — chỉ dùng local, KHÔNG lên VPS | `secrets/operator.enc.yaml` |
| 1 app: chạy ở đâu, port, domain, DB | `apps/<app>/app.yaml` |
| 1 app: mô tả, tech, cách chạy local, lịch sử | `apps/<app>/README.md` |
| Secret riêng của app theo env | `apps/<app>/envs/<env>/.env.enc.yaml` (bộ key chuẩn: `envs/example.yaml`) |
| Thử nghiệm nhanh / adhoc | `lab/` — luật `lab/README.md`, lệnh `tools/lab` |
| Tài liệu agent tạo (audit/plan/note/design) | `apps/<app>/docs/` hoặc `docs/` — tên `YYYY-MM-DD-<kind>-<slug>.md` |

## Rule đọc (BẮT BUỘC trước khi làm)
- Đụng 1 **app** → đọc `apps/<app>/app.yaml` + `README.md` trước khi sửa/deploy.
- Đụng 1 **máy** → đọc `hosts/<vps>.md` + `fleet.md`.
- Sửa nơi chạy của app (`app.yaml`) → cập nhật ngay `fleet.md` + bảng trong `hosts/<vps>.md`.
- Việc lớn trên 1 app (deploy env mới, đổi kiến trúc, migrate) → thêm 1 dòng có ngày vào `## Lịch sử` của README app.

## Secret
- **KHÔNG** viết plaintext vào repo, log, hay chat. Giá trị thật chỉ ở `*.enc.yaml`.
- Master key `secrets/masterkey/keys.txt` đã gitignore — không commit, không copy lên VPS.
- Muốn biết file có key gì: `tools/secret keys <file>` (không in giá trị). Chỉ `show` khi thật sự cần giá trị.
- `.env.local` / `.env.*.local` không bao giờ lên server: `deploy.sh` phải `--exclude` chúng khi rsync.

## Máy chủ
- Vào máy: `tools/ssh <vps> [lệnh]`. Không gõ IP/pass tay.
- Onboard máy mới: tạo SSH key riêng → đẩy public key lên → tắt đăng nhập bằng password → cất private key vào
  `secrets/vps.enc.yaml` → viết `hosts/<vps>.md` + dòng trong `fleet.md`.
- Service chỉ nghe `127.0.0.1:<port>`, nginx đứng trước. Mỗi port chỉ một chủ — ghi trong `fleet.md`.
- **Hành động khó hoàn tác trên prod** (deploy, xoá dữ liệu, restart, đổi DNS) → hỏi user trước.

## Đưa app lên mạng
1. Khai `apps/<app>/app.yaml` (máy, port chưa dùng, domain, tên tiến trình) → thêm dòng vào `fleet.md`, `hosts/<vps>.md`, `domains.md`.
2. Secret: key ở `envs/example.yaml`, giá trị ở `envs/<env>/.env.enc.yaml`.
3. `deploy/deploy.sh <env>`: render env → rsync lên `/srv/<app>/` (loại `node_modules`, `.git`, dữ liệu, `.env.local`) →
   cài + build trên máy → `pm2 start`/`reload` → `pm2 save`. Dữ liệu nằm ngoài thư mục code.
4. nginx: vhost ở `deploy/nginx/<domain>.conf`, `proxy_pass http://127.0.0.1:<port>`, `nginx -t` rồi reload.
5. DNS: tạo bản ghi bằng API (token trong `secrets/operator.enc.yaml`), ghi vào `domains.md`.
6. Kiểm tra `curl -I https://<domain>` + `pm2 status`; ghi `## Lịch sử`. **Hỏi user trước khi deploy.**

## Thử nghiệm: `lab/`
User nói "adhoc" / "thử nhanh" / "experiment" → `tools/lab new <slug>`, làm trong thư mục đó, secret qua
`tools/lab run <nhóm> -- <lệnh>`. Không deploy, không đụng `apps/`, `fleet.md`. Xong: ghi `NOTES.md`, rồi hỏi user
xoá · giữ bài học vào `docs/` · nâng thành app. Cần repo GitHub → `tools/lab repo <thư-mục>` (private).

## Commit
- Format `<scope>: <mô tả>` — scope = `infra` (file chung) hoặc tên app. Mỗi commit một scope.
- Commit / push / deploy chỉ khi user bảo.
