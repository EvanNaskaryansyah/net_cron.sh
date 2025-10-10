#!/bin/bash
# update_freetds.sh
# - Scan 192.168.1.* port 1433, ambil IP pertama yang open
# - Ganti host = ... pada section [mssql] di /etc/freetds/freetds.conf (tanpa backup)
# - Ditulis agar bisa dijalankan dari cron (jika dijalankan sebagai root, sudo tidak diperlukan)

set -euo pipefail

CONF='/etc/freetds/freetds.conf'

# cek nmap
if ! command -v nmap >/dev/null 2>&1; then
  echo "nmap tidak ditemukan. Pasang dulu: sudo apt update && sudo apt install -y nmap"
  exit 2
fi

# cari IP pertama dengan port 1433 open
NEWIP=$(nmap -p 1433 --open -oG - 192.168.1.* 2>/dev/null \
  | awk '/Ports:/{ if($0 ~ /1433\/open/) { match($0,/Host: ([0-9.]+)/,a); if(a[1]!="") print a[1] } }' \
  | head -n1 || true)

if [ -z "${NEWIP:-}" ]; then
  echo "$(date '+%F %T') - Tidak menemukan host dengan port 1433 terbuka di 192.168.1.* — tidak mengubah $CONF"
  exit 0
fi

echo "$(date '+%F %T') - Menemukan IP: $NEWIP  — akan mengganti host di $CONF (tanpa backup)"

# buat output via awk; kemudian tulis ke file (pakai sudo jika perlu)
awk -v newip="$NEWIP" '
  BEGIN { in_section=0; host_re="^[[:space:]]*host[[:space:]]*="; host_replaced=0 }
  /^\[mssql\]/ { print; in_section=1; next }
  /^\[.*\]/ {
      if(in_section && host_replaced==0) {
          # pindah ke section lain dan host belum ditemukan: tambahkan host sebelum section baru
          print "\thost = " newip
      }
      in_section=0
      print
      next
  }
  {
    if(in_section) {
      if ($0 ~ host_re) {
        sub(/=.*/,"= " newip)
        host_replaced=1
        print
        next
      }
      print
      next
    } else {
      print
    }
  }
  END {
    if(in_section && host_replaced==0) {
      # file berakhir di [mssql] tanpa host
      print "\thost = " newip
    }
  }
' "$CONF" > /tmp/update_freetds_conf_$$.tmp

# tulis ke file tujuan. jika file bisa ditulis langsung (root), pindahkan; jika tidak, gunakan sudo tee
if mv /tmp/update_freetds_conf_$$.tmp "$CONF" 2>/dev/null; then
  echo "$(date '+%F %T') - Ditulis langsung ke $CONF"
else
  # pakai sudo tee (memerlukan sudo privilege)
  sudo tee "$CONF" > /dev/null < /tmp/update_freetds_conf_$$.tmp
  echo "$(date '+%F %T') - Ditulis ke $CONF via sudo"
  rm -f /tmp/update_freetds_conf_$$.tmp
fi

# set permission (hanya jika kita adalah root or sudo succeeded)
if [ "$(id -u)" -eq 0 ]; then
  chown root:root "$CONF" || true
  chmod 644 "$CONF" || true
fi

echo "$(date '+%F %T') - Selesai. [mssql] host sekarang: $NEWIP"
