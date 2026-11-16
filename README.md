# Core Infra Concept

Một repo duy nhất để quản lý mọi máy chủ, app và credential — viết để **đưa cho AI agent đọc rồi tự dựng**.

- **Cách 1 — đưa ý tưởng cho agent:** copy file `README.md` này vào một thư mục trống, mở agent (vd Claude Code) và bảo "đọc file này rồi làm".
- **Cách 2 — dùng bộ dựng sẵn:** copy thư mục [`starter/`](starter/) thành repo của bạn rồi chạy `./setup.sh` (xem [`starter/README.md`](starter/README.md)).

---

# Ý tưởng để agent dựng

> **Gửi agent đọc file này:** hãy dựng một repo theo đúng mô tả dưới đây, trong thư mục hiện tại. Làm bản tối thiểu
> ở mục "Việc cần làm", không thêm thứ ngoài danh sách. Chỗ nào cần thông tin của chủ repo (IP, token, tên máy) thì
> để giá trị mẫu và hỏi, không tự bịa.

## 1. Mục đích
Một repo git duy nhất quản lý **mọi máy chủ, mọi app, mọi credential** của một người. Chủ repo mở agent trong repo này
và giao việc bằng lời ("onboard VPS mới", "deploy app X", "thử nhanh API Y"); agent tự biết đọc gì, lấy secret ở đâu,
vào máy nào.

Ba nguyên tắc:
1. **Mỗi thông tin chỉ nằm ở MỘT chỗ.** Không đoán, không hardcode, không ghi lặp.
2. **Mọi credential nằm trong repo, ở dạng mã hoá.** Một master key mở tất cả; master key không bao giờ vào git.
3. **Agent đọc mục lục trước khi làm.** `CLAUDE.md` nói cần gì thì đọc file nào.

## 2. Cấu trúc
```
CLAUDE.md                 mục lục + luật cho agent (đọc đầu tiên)
README.md                 giải thích cho người: ý tưởng, cách bắt đầu, lệnh
fleet.md                  bảng tổng: app nào chạy ở máy nào, port nào đã dùng
domains.md                danh bạ domain: mỗi subdomain trỏ máy nào, thuộc app nào
hosts/<máy>.md            mỗi máy một file: specs, cách vào, đang chạy gì
apps/<app>/               mỗi app một thư mục
  app.yaml                  footprint: service, env, máy, port, domain, DB
  README.md                 mô tả, tech, "## Local dev", "## Lịch sử"
  envs/example.yaml         bộ KEY env chuẩn (không có giá trị thật)
  envs/<env>/.env.enc.yaml  giá trị thật theo env, mã hoá
  deploy/deploy.sh          deploy 1 env (mục 6)
  deploy/render-env.sh      giải mã .env.enc.yaml → file .env cho server
  deploy/nginx/<domain>.conf  vhost bản gốc của app
  <code>/
secrets/
  vps.enc.yaml              mỗi máy: ip, ssh_user, ssh_port, ssh_private_key, root_password
  operator.enc.yaml         credential vận hành của chủ repo: GitHub, Cloudflare, cloud… (chỉ dùng local)
  certs.enc.yaml            cert + key HTTPS của từng domain (được chép lên máy cho nginx)
  *.example.yaml            khuôn, không có giá trị thật
  masterkey/keys.txt        MASTER KEY — gitignored
lab/                      thử nghiệm nhanh; gitignored trừ README.md
tools/                    lệnh tiện ích (mục 4)
docs/                     tài liệu agent tạo: YYYY-MM-DD-<audit|plan|note|design>-<slug>.md
.sops.yaml                luật mã hoá: file *.enc.yaml → public key của master key
.gitignore
```

## 3. Secret: SOPS + age
- Công cụ: [sops](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age).
  `age-keygen` tạo master key; public key của nó ghi vào `.sops.yaml` với
  `path_regex: (secrets/.*|apps/.*)\.enc\.yaml$`.
- File `.enc.yaml` vẫn đọc được **tên** key, chỉ **giá trị** bị mã hoá → commit lên git được, diff vẫn có nghĩa.
- Mọi lệnh giải mã đặt `SOPS_AGE_KEY_FILE=secrets/masterkey/keys.txt`.
- `.gitignore` chặn: `secrets/masterkey/`, `keys.txt`, `.env`, `.env.local`, `.env.*.local`, `*.dec.yaml`.
- Chủ repo phải **sao lưu master key offline** (password manager). Mất = mất hết; lộ = lộ hết.
- Hai loại credential, tách file:
  - `operator.enc.yaml` — token của người vận hành, **chỉ dùng trên máy local, không bao giờ lên VPS**.
  - `apps/<app>/envs/<env>/.env.enc.yaml` — secret app dùng khi chạy, được render lên VPS lúc deploy.

## 4. Lệnh trong `tools/`
| Lệnh | Việc |
|---|---|
| `tools/secret edit <file>` | mở editor qua sops, lưu là tự mã hoá lại |
| `tools/secret show <file>` | in giá trị đã giải mã |
| `tools/secret keys <file>` | chỉ in tên key (đường dẫn dạng `a.b.c`), **không** in giá trị — agent dùng lệnh này mặc định |
| `tools/ssh <máy> [lệnh…]` | đọc `vps.enc.yaml`, chép private key ra `~/.ssh/infra_<máy>` (quyền 600) nếu chưa có, rồi `ssh` |
| `tools/lab new <slug>` | tạo `lab/YYYY-MM-DD-<slug>/` + `NOTES.md` (mục tiêu · đã thử · kết quả · kết luận) |
| `tools/lab run <nhóm>[,<nhóm>] -- <lệnh…>` | giải mã `operator.enc.yaml` trong bộ nhớ, bơm các nhóm đó vào biến môi trường của lệnh. Tên biến = đường dẫn key viết hoa nối `_` (`github.token` → `GITHUB_TOKEN`, thêm `GH_TOKEN`). Không ghi plaintext ra đĩa |
| `tools/lab secrets` · `ls` | liệt kê nhóm + tên biến (không giá trị) · liệt kê thử nghiệm kèm tuổi |
| `setup.sh` | chạy 1 lần: kiểm tra công cụ, tạo master key, điền public key vào `.sops.yaml`, tạo 2 file `.enc.yaml` từ khuôn, `git init`, nhắc sao lưu key |

## 5. Luật ghi vào `CLAUDE.md`
- **Đọc trước khi làm**: đụng app → đọc `app.yaml` + README của app; đụng máy → đọc `hosts/<máy>.md` + `fleet.md`.
- **Đồng bộ bảng tổng**: sửa nơi chạy của app → sửa ngay `fleet.md` và bảng trong `hosts/<máy>.md`.
- **Secret**: không plaintext trong repo, log, chat. Không copy master key hay `operator.enc.yaml` lên VPS.
  `deploy.sh` phải `--exclude .env.local --exclude '.env.*.local'` khi rsync.
- **Máy chủ**: vào bằng `tools/ssh`, không gõ IP/pass tay. Service chỉ nghe `127.0.0.1:<port>`, nginx đứng trước.
  Mỗi port một chủ, ghi trong `fleet.md`.
- **Onboard máy mới**: tạo SSH key riêng → đẩy public key → tắt đăng nhập password → cất private key vào
  `vps.enc.yaml` → viết `hosts/<máy>.md` + dòng trong `fleet.md` → nhắc chủ repo đổi pass gốc.
- **Domain**: thêm / đổi / gỡ subdomain → sửa `domains.md` cùng lúc. Bản ghi DNS tạo bằng API, không bấm tay.
- **Env đồng nhất**: mọi `.env.enc.yaml` của một app khớp đúng bộ key trong `envs/example.yaml`.
- **Lab**: chủ repo nói "adhoc / thử nhanh / experiment" → làm trong `lab/`, chỉ chạy local, không đụng `apps/` hay
  `fleet.md`. Xong thì hỏi: xoá · ghi bài học vào `docs/` · nâng thành app.
- **Việc khó hoàn tác trên prod** (deploy, xoá dữ liệu, restart, đổi DNS) → hỏi chủ repo trước.
- **Commit**: `<scope>: <mô tả>`, scope = `infra` hoặc tên app, mỗi commit một scope. Commit / push chỉ khi được bảo.
- **Lịch sử**: việc lớn trên một app → thêm một dòng có ngày vào `## Lịch sử` trong README của app.

## 6. Đưa một app lên mạng (deploy + subdomain)
**Chuẩn bị máy, làm 1 lần mỗi VPS** (ghi version vào `hosts/<máy>.md`): cài runtime (vd Node LTS), `pm2` (+ `pm2 startup`
để tự chạy lại sau reboot), `nginx`; firewall chỉ mở 22, 80, 443; chép cert của domain từ `secrets/certs.enc.yaml` vào
`/etc/ssl/<tên>/` (quyền 600).

**Mỗi app, 6 bước:**
1. **Khai báo** — `apps/<app>/app.yaml`: máy, port (chọn số chưa có trong `fleet.md`), domain, tên tiến trình, DB.
   Thêm dòng vào `fleet.md`, `hosts/<máy>.md`, `domains.md`.
2. **Secret** — liệt kê key ở `envs/example.yaml`, giá trị thật ở `envs/prod/.env.enc.yaml`.
3. **`deploy/deploy.sh <env>`** — đọc máy/port từ `app.yaml`, IP + key từ `secrets/vps.enc.yaml`, rồi:
   render env → `rsync` code lên `/srv/<app>/` (loại `node_modules`, `.git`, thư mục dữ liệu, `.env.local`,
   `.env.*.local`) → trên máy: sao lưu DB, cài thư viện, build → `pm2 start` lần đầu / `pm2 reload` các lần sau → `pm2 save`.
   Dữ liệu (DB, file upload) nằm ngoài thư mục code để `rsync --delete` không xoá.
4. **nginx** — vhost lưu ở `deploy/nginx/<domain>.conf`, deploy chép vào `/etc/nginx/sites-enabled/`, `nginx -t`, reload:
   ```nginx
   server {
     listen 443 ssl; server_name app.example.com;
     ssl_certificate /etc/ssl/<tên>/origin.pem; ssl_certificate_key /etc/ssl/<tên>/origin.key;
     location / { proxy_pass http://127.0.0.1:<port>; proxy_set_header Host $host;
                  proxy_set_header X-Forwarded-For $remote_addr; proxy_set_header X-Forwarded-Proto https; }
   }
   ```
5. **DNS** — tạo bản ghi `A <subdomain> → IP máy` bằng API của nhà cung cấp DNS, dùng token trong
   `secrets/operator.enc.yaml` (vd Cloudflare: `POST /zones/<zone_id>/dns_records`, bật proxy). Ghi vào `domains.md`.
6. **Kiểm tra** — `curl -I https://<subdomain>` trả 200; `pm2 status` thấy tiến trình online; ghi một dòng vào `## Lịch sử`.

**HTTPS, chọn một:** (a) DNS qua Cloudflare bật proxy + *origin certificate* dạng wildcard `*.domain` (một cert dùng cho mọi
subdomain, hạn nhiều năm, SSL mode "Full (strict)"); khi đó firewall chỉ cho 80/443 từ dải IP Cloudflare. (b) Let's Encrypt
bằng `certbot --nginx`, tự gia hạn — không cần `certs.enc.yaml`.

**Deploy là việc trên prod → agent hỏi chủ repo trước khi chạy.**

## 7. Việc cần làm (bản tối thiểu)
1. Tạo cấu trúc ở mục 2 với: `CLAUDE.md`, `README.md`, `fleet.md` (bảng rỗng), `hosts/_template.md`,
   `domains.md` (rỗng),
   `apps/_template/{app.yaml,README.md,deploy/deploy.sh}`, `secrets/{vps,operator}.example.yaml`, `lab/README.md`, `.sops.yaml`, `.gitignore`.
2. Viết `setup.sh` và các lệnh ở mục 4 (bash + python3/pyyaml là đủ).
3. Chạy `setup.sh`, kiểm tra: `tools/secret keys secrets/vps.enc.yaml` in ra tên key; `git status` không thấy master key;
   `tools/lab run github -- env` có `GITHUB_TOKEN`.
4. Hỏi chủ repo danh sách máy và token, hướng dẫn họ tự điền bằng `tools/secret edit` (agent không cần thấy giá trị).
5. Nhắc sao lưu master key.

## 8. Thêm sau khi cần (không làm ở bản đầu)
Hook kiểm tra format commit · service dùng chung nhiều app (auth, mail) · góc riêng cho app làm cho khách ·
app giám sát các máy.
