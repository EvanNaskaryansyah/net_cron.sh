#!/bin/bash
# update_freetds.sh (versi mawk-compatible)
set -euo pipefail

CONF='/etc/freetds/freetds.conf'

# Pastikan nmap tersedia
if ! command -v nmap >/dev/null 2>&1; then
  echo "nmap tidak ditemukan. Pasang dulu: sudo apt update && sudo apt install -y nmap"
  exit 2
fi

# Cari IP pertama dengan port 1433 open (tanpa match(), supaya kompatibel mawk)
NEWIP=$(nmap -p 1433 --open -oG - 192.168.1.* 2>/dev/null \
  | awk '/Ports:/{ if($0 ~ /1433\/open/) { sub(/.*Host: /,""); sub(/ .*/,""); print } }' \
  | head -n1 || true)

if [ -z "${NEWIP:-}" ]; then
  echo "$(date '+%F %T') - Tidak menemukan host dengan port 1433 terbuka di 192.168.1.* — tidak mengubah $CONF"
  exit 0
fi

echo "$(date '+%F %T') - Menemukan IP: $NEWIP — akan mengganti host di $CONF (tanpa backup)"

# Update bagian [mssql] di freetds.conf
awk -v newip="$NEWIP" '
  BEGIN { in_section=0; host_re="^[[:space:]]*host[[:space:]]*="; host_replaced=0 }
  /^\[mssql\]/ { print; in_section=1; next }
  /^\[.*\]/ {
      if(in_section && host_replaced==0) {
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
      print "\thost = " newip
    }
  }
' "$CONF" > /tmp/update_freetds_conf_$$.tmp

# Tulis hasilnya ke file (langsung atau pakai sudo)
if mv /tmp/update_freetds_conf_$$.tmp "$CONF" 2>/dev/null; then
  echo "$(date '+%F %T') - Ditulis langsung ke $CONF"
else
  sudo tee "$CONF" > /dev/null < /tmp/update_freetds_conf_$$.tmp
  echo "$(date '+%F %T') - Ditulis ke $CONF via sudo"
  rm -f /tmp/update_freetds_conf_$$.tmp
fi

# Set permission
if [ "$(id -u)" -eq 0 ]; then
  chown root:root "$CONF" || true
  chmod 644 "$CONF" || true
fi

echo "$(date '+%F %T') - Selesai. [mssql] host sekarang: $NEWIP"
