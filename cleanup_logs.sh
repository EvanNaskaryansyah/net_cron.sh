#!/bin/bash

# Membuat script cleanup_logs.sh
cat << 'EOC' > /home/pajak/script/cleanup_logs.sh
#!/bin/bash
set -euo pipefail

DIRS=("/home/pajak/log" "/home/pajak/sent")
PATTERN="${1:-*}"
BATCH="${2:-1000}"
SLEEPSEC=0.2

echo "Akan menghapus file matching '$PATTERN' di folder: ${DIRS[*]} dengan batch size $BATCH"

if [[ "${DRY_RUN:-0}" == "1" ]]; then
  for d in "${DIRS[@]}"; do
    [ -d "$d" ] || continue
    find "$d" -type f -name "$PATTERN" -print | head -n 200
  done
  exit 0
fi

for d in "${DIRS[@]}"; do
  [ -d "$d" ] || { echo "Direktori tidak ada: $d, lewati..."; continue; }
  find "$d" -type f -name "$PATTERN" -print0 | xargs -0 -n "$BATCH" bash -c 'for f; do rm -f -- "$f"; done' _
  find "$d" -mindepth 1 -type d -empty -delete || true
done

echo "Selesai menghapus file di semua direktori."
EOC

# Izin eksekusi
chmod +x /home/pajak/script/cleanup_logs.sh

# Tambah ke crontab (1 Jan, 1 Apr, 1 Jul, 1 Okt jam 00:00)
CRON_JOB="0 0 1 1,4,7,10 * /home/pajak/script/cleanup_logs.sh"
(crontab -l 2>/dev/null | grep -v -F "$CRON_JOB" ; echo "$CRON_JOB") | crontab -

echo "✅ Script cleanup_logs.sh berhasil dibuat dan crontab ditambahkan."
crontab -l | grep cleanup_logs.sh

# Jalankan sekali sekarang (opsional)
bash /home/pajak/script/cleanup_logs.sh
