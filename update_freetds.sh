#!/bin/bash
set -euo pipefail

CONF='/etc/freetds/freetds.conf'

# pastikan nmap ada
if ! command -v nmap >/dev/null 2>&1; then
  echo "nmap tidak ditemukan. Install dulu: sudo apt install -y nmap"
  exit 2
fi

# cari IP MSSQL pertama dengan port 1433 terbuka
NEWIP=$(nmap -p 1433 --open -oG - 192.168.1.* 2>/dev/null \
  | awk '/Ports:/{ if($0 ~ /1433\/open/) { sub(/.*Host: /,""); sub(/ .*/,""); print } }' \
  | head -n1 || true)

if [ -z "${NEWIP:-}" ]; then
  echo "$(date '+%F %T') - Tidak menemukan host dengan port 1433 terbuka di 192.168.1.* — tidak mengubah $CONF"
  exit 0
fi

echo "$(date '+%F %T') - Menemukan IP: $NEWIP — mengganti host lama di $CONF"

awk -v newip="$NEWIP" '
  BEGIN { in_mssql=0; done=0 }
  /^\[mssql\]/ { print; in_mssql=1; next }
  /^\[.*\]/ {
    if (in_mssql && done==0) {
      print "\thost = " newip
    }
    in_mssql=0
    print
    next
  }
  {
    if (in_mssql) {
      if ($0 ~ /^[[:space:]]*host[[:space:]]*=/) {
        if (done==0) {
          sub(/=.*/,"= " newip)
          print
          done=1
        }
        next  # skip host lama lain
      } else {
        print
      }
      next
    }
    print
  }
  END {
    if (in_mssql && done==0) {
      print "\thost = " newip
    }
  }
' "$CONF" > /tmp/update_freetds_conf_$$.tmp

# tulis ke file
if mv /tmp/update_freetds_conf_$$.tmp "$CONF" 2>/dev/null; then
  echo "$(date '+%F %T') - Ditulis langsung ke $CONF"
else
  sudo tee "$CONF" > /dev/null < /tmp/update_freetds_conf_$$.tmp
  echo "$(date '+%F %T') - Ditulis ke $CONF via sudo"
  rm -f /tmp/update_freetds_conf_$$.tmp
fi

# set permission
if [ "$(id -u)" -eq 0 ]; then
  chown root:root "$CONF" || true
  chmod 644 "$CONF" || true
fi

echo "$(date '+%F %T') - Selesai. [mssql] host sekarang: $NEWIP"
