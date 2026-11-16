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
hosts/<máy>.md            mỗi máy một file: specs, cách vào, đang chạy gì
apps/<app>/               mỗi app một thư mục
  app.yaml                  footprint: service, env, máy, port, domain, DB
  README.md                 mô tả, tech, "## Local dev", "## Lịch sử"
  envs/example.yaml         bộ KEY env chuẩn (không có giá trị thật)
  envs/<env>/.env.enc.yaml  giá trị thật theo env, mã hoá
  deploy/deploy.sh          deploy 1 env
  <code>/
secrets/
  vps.enc.yaml              mỗi máy: ip, ssh_user, ssh_port, ssh_private_key, root_password
  operator.enc.yaml         credential vận hành của chủ repo: GitHub, Cloudflare, cloud… (chỉ dùng local)
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
- **Env đồng nhất**: mọi `.env.enc.yaml` của một app khớp đúng bộ key trong `envs/example.yaml`.
- **Lab**: chủ repo nói "adhoc / thử nhanh / experiment" → làm trong `lab/`, chỉ chạy local, không đụng `apps/` hay
  `fleet.md`. Xong thì hỏi: xoá · ghi bài học vào `docs/` · nâng thành app.
- **Việc khó hoàn tác trên prod** (deploy, xoá dữ liệu, restart, đổi DNS) → hỏi chủ repo trước.
- **Commit**: `<scope>: <mô tả>`, scope = `infra` hoặc tên app, mỗi commit một scope. Commit / push chỉ khi được bảo.
- **Lịch sử**: việc lớn trên một app → thêm một dòng có ngày vào `## Lịch sử` trong README của app.

## 6. Việc cần làm (bản tối thiểu)
1. Tạo cấu trúc ở mục 2 với: `CLAUDE.md`, `README.md`, `fleet.md` (bảng rỗng), `hosts/_template.md`,
   `apps/_template/{app.yaml,README.md}`, `secrets/{vps,operator}.example.yaml`, `lab/README.md`, `.sops.yaml`, `.gitignore`.
2. Viết `setup.sh` và các lệnh ở mục 4 (bash + python3/pyyaml là đủ).
3. Chạy `setup.sh`, kiểm tra: `tools/secret keys secrets/vps.enc.yaml` in ra tên key; `git status` không thấy master key;
   `tools/lab run github -- env` có `GITHUB_TOKEN`.
4. Hỏi chủ repo danh sách máy và token, hướng dẫn họ tự điền bằng `tools/secret edit` (agent không cần thấy giá trị).
5. Nhắc sao lưu master key.

## 7. Thêm sau khi cần (không làm ở bản đầu)
Hook kiểm tra format commit · service dùng chung nhiều app (auth, mail) · quản lý domain và cert (`domains.md`,
`secrets/certs.enc.yaml`) · góc riêng cho app làm cho khách · app giám sát các máy.
