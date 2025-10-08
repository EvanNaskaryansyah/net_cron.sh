#!/bin/bash

# Membuat folder script jika belum ada
#mkdir -p /home/pajak/script

# Membuat script cleanup_logs.sh
cat << 'EOF' > /home/pajak/script/cleanup_logs.sh
#!/bin/bash
# batched-clean-pajak-logs.sh
# Hapus file dalam batch (xargs) dari dua folder sekaligus untuk mencegah kerja rm yang sangat besar sekaligus.
# Usage: sudo ./batched-clean-pajak-logs.sh [pattern] [batch_size]
set -euo pipefail

# Default directories
DIRS=("/home/pajak/log" "/home/pajak/sent")
PATTERN="${1:-*}"   # pattern file yang mau dihapus
BATCH="${2:-1000}"       # jumlah file per batch
SLEEPSEC=0.2             # jeda antar batch (opsional, bisa dihapus)

echo "Akan menghapus file matching '$PATTERN' di folder: ${DIRS[*]} dengan batch size $BATCH"

# Dry-run check: tampilkan file dulu
if [[ "${DRY_RUN:-0}" == "1" ]]; then
  echo "DRY RUN: file matching:"
  for d in "${DIRS[@]}"; do
    [ -d "$d" ] || continue
    find "$d" -type f -name "$PATTERN" -print | head -n 200
    echo "Total files in $d: $(find "$d" -type f -name "$PATTERN" | wc -l)"
  done
  exit 0
fi

# Loop through directories
for d in "${DIRS[@]}"; do
  if [ ! -d "$d" ]; then
    echo "Direktori tidak ada: $d, lewati..."
    continue
  fi

  echo "Menghapus file di $d ..."
  # Delete in chunks
  find "$d" -type f -name "$PATTERN" -print0 | \
    xargs -0 -n "$BATCH" bash -c 'for f; do rm -f -- "$f"; done' _

  # Hapus subdirectory kosong setelah batch delete
  find "$d" -type d -empty -delete || true
done

echo "Selesai menghapus file di semua direktori."
EOF

# Memberikan izin eksekusi
chmod +x /home/pajak/script/cleanup_logs.sh

# Menambahkan ke crontab jika belum ada
CRON_JOB="0 0 1 1,4,7,10 * /home/pajak/script/cleanup_logs.sh"
(crontab -l 2>/dev/null | grep -v -F "$CRON_JOB" ; echo "$CRON_JOB") | crontab -

echo "Script cleanup_logs.sh berhasil dibuat di /home/pajak/script/"
echo "Izin eksekusi diberikan dengan chmod +x"
echo "Crontab berhasil ditambahkan:"
crontab -l | grep cleanup_logs.sh
