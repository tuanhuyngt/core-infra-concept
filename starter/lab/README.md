# lab/ — thử nghiệm nhanh (adhoc)

Nơi mở lên là làm: thử một API, một SDK, một ý tưởng. **Không phải app**, không có trong `fleet.md`.
Mọi thứ trong thư mục này **gitignored** (trừ file README này) → chỉ nằm trên máy đang làm, không đồng bộ, không backup.

## Luật
- **Mỗi thử nghiệm một thư mục**: `lab/YYYY-MM-DD-<slug>/`, tạo bằng `tools/lab new <slug>`. Tự chứa venv / `node_modules` riêng.
- **`NOTES.md` bắt buộc**: mục tiêu · đã thử gì · kết quả · kết luận. Ghi ngay khi làm, không để cuối.
- **Chỉ chạy local.** Không deploy, không sửa `apps/`, `services/`, `clients/`, `fleet.md`, `domains.md`, `hosts/`.
  Cần server / domain / chạy lâu dài → không còn là thử nghiệm, nâng thành app (xem dưới).
- **Secret**: lấy từ `secrets/operator.enc.yaml` qua `tools/lab run <nhóm> -- <lệnh>` (bơm vào biến môi trường của
  tiến trình). **Không** ghi token ra file (`.env`, config, notebook, `NOTES.md`), không in ra log.
  Chỉ gọi đúng nhóm cần dùng — code thử nghiệm không nên thấy token không liên quan.

## Lệnh
```bash
tools/lab new databricks-connect              # tạo thư mục + NOTES.md
tools/lab secrets                             # nhóm nào có, sinh biến môi trường tên gì (không in giá trị)
tools/lab run databricks -- python main.py    # DATABRICKS_HOST, DATABRICKS_TOKEN có trong env
tools/lab run github,databricks -- bash       # nhiều nhóm; mở shell có sẵn token
tools/lab ls                                  # liệt kê + tuổi; > 30 ngày thì nhắc dọn
tools/lab repo 2026-11-15-databricks-connect  # đẩy lên GitHub private infra-lab-databricks-connect
```
Tên biến = đường dẫn key viết hoa nối `_`: `databricks.token` → `DATABRICKS_TOKEN`, `github.token` → `GITHUB_TOKEN`
(kèm `GH_TOKEN` cho `gh` CLI). Thêm token mới: `SOPS_AGE_KEY_FILE=secrets/masterkey/keys.txt sops secrets/operator.enc.yaml`.

## Khi thử nghiệm cần repo GitHub
Chỉ khi cần source nằm trên GitHub (Databricks Git folder / notebook, app deploy từ repo, CI, chia sẻ, làm tiếp ở máy khác).
- `tools/lab repo <thư-mục-lab>` → repo **private** `<tài khoản>/infra-lab-<slug>` (slug = tên thư mục bỏ ngày). Thư mục lab
  tự nó là một repo git riêng (core đã ignore `lab/`); chạy lại lệnh = commit snapshot + push.
- **Trước khi chạy**: thêm vào `.gitignore` của thư mục lab mọi file nhạy cảm (tài liệu mật của người khác, dữ liệu, output).
  Token không bao giờ nằm trong file nên không lo lộ token, nhưng nội dung khác thì phải tự loại.
- Commit trong repo lab không theo luật scope của core (không có hook). Xoá thử nghiệm → xoá luôn repo trên GitHub (hỏi user trước).

## Kết thúc một thử nghiệm — chọn 1 trong 3
| Kết quả | Làm gì |
|---|---|
| Bỏ | Xoá thư mục |
| Có bài học đáng giữ | Viết `docs/YYYY-MM-DD-note-<slug>.md` (header 5 field như mọi doc), rồi xoá thư mục |
| Thành sản phẩm thật | Copy `apps/_template/` → `apps/<app>/`, chuyển code sang, làm đủ `app.yaml` / envs / README |
