#!/usr/bin/env bash
# Chạy 1 lần: tạo master key, điền public key vào .sops.yaml, tạo file secret mã hoá từ khuôn, git init.
set -euo pipefail
cd "$(dirname "$0")"
for c in sops age-keygen git python3; do command -v "$c" >/dev/null || { echo "❌ thiếu '$c' — xem README"; exit 1; }; done
python3 -c "import yaml" 2>/dev/null || { echo "❌ thiếu pyyaml: pip install pyyaml"; exit 1; }

KEY=secrets/masterkey/keys.txt
if [ ! -f "$KEY" ]; then
  mkdir -p secrets/masterkey && chmod 700 secrets/masterkey
  age-keygen -o "$KEY" 2>/dev/null && chmod 600 "$KEY"
  echo "✅ tạo master key: $KEY"
fi
PUB=$(grep -o 'age1[a-z0-9]*' "$KEY" | head -1)
sed -i.bak "s/AGE_PUBLIC_KEY_PLACEHOLDER/$PUB/" .sops.yaml && rm -f .sops.yaml.bak

export SOPS_AGE_KEY_FILE="$PWD/$KEY"
for name in vps operator; do
  f=secrets/$name.enc.yaml
  [ -f "$f" ] && continue
  cp "secrets/$name.example.yaml" "$f" && sops -e -i "$f" && echo "✅ tạo $f (mã hoá, còn giá trị mẫu)"
done
[ -d .git ] || { git init -q -b main && echo "✅ git init"; }
echo
echo "⚠️  SAO LƯU NGAY $KEY (password manager). Mất file này = không giải mã được gì nữa."
echo "Tiếp: tools/secret edit secrets/vps.enc.yaml"
