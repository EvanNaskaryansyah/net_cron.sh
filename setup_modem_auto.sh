#!/bin/bash
# setup_modem_auto.sh
# Setup otomatis restart & monitor modem Huawei untuk user "pajak"

INSTALL_DIR="/home/pajak/script"
RESTART_SCRIPT="$INSTALL_DIR/restart_modem_auto_detect.sh"
MONITOR_SCRIPT="$INSTALL_DIR/modem_monitor.sh"
LOG_FILE="/var/log/modem_monitor.log"

# Pastikan folder ada
echo "[INFO] Membuat folder script di $INSTALL_DIR ..."
sudo mkdir -p "$INSTALL_DIR"
sudo chmod 755 "$INSTALL_DIR"

echo "[INFO] Membuat script restart_modem_auto_detect.sh ..."
sudo bash -c "cat > $RESTART_SCRIPT" << 'EOF'
#!/bin/bash
# restart_modem_auto_detect.sh
# Restart modem Huawei via sysfs (otomatis deteksi)

echo "[INFO] Mendeteksi modem Huawei..."
DEVICE_DIR=$(grep -i -l "huawei" /sys/bus/usb/devices/*/manufacturer 2>/dev/null | sed 's|/manufacturer||' | head -n1)

if [ -z "$DEVICE_DIR" ]; then
  echo "[ERROR] Tidak ditemukan modem Huawei di /sys/bus/usb/devices/"
  exit 1
fi

echo "[INFO] Modem Huawei ditemukan di: $DEVICE_DIR"

if [ ! -f "$DEVICE_DIR/authorized" ]; then
  echo "[ERROR] File authorized tidak ditemukan di $DEVICE_DIR"
  exit 1
fi

echo "[INFO] Menonaktifkan modem (power off)..."
sudo sh -c "echo 0 > $DEVICE_DIR/authorized"
sleep 2

echo "[INFO] Mengaktifkan kembali modem (power on)..."
sudo sh -c "echo 1 > $DEVICE_DIR/authorized"
sleep 5

if lsusb | grep -qi huawei; then
  echo "[SUCCESS] Modem Huawei aktif kembali!"
else
  echo "[WARNING] Modem belum muncul kembali!"
fi
EOF

sudo chmod +x "$RESTART_SCRIPT"
echo "[OK] Script restart modem dibuat di: $RESTART_SCRIPT"


echo "[INFO] Membuat script modem_monitor.sh ..."
sudo bash -c "cat > $MONITOR_SCRIPT" << EOF
#!/bin/bash
# modem_monitor.sh
# Monitor koneksi internet dan restart modem jika offline

RESTART_SCRIPT="$RESTART_SCRIPT"
LOG_FILE="$LOG_FILE"
PING_TARGET="8.8.8.8"
FAIL_COUNT=0
MAX_FAIL=3

sudo touch "\$LOG_FILE"
sudo chmod 666 "\$LOG_FILE"

log() {
  echo "\$(date '+%Y-%m-%d %H:%M:%S') - \$1" | tee -a "\$LOG_FILE"
}

# Cek koneksi
if ping -c 2 "\$PING_TARGET" > /dev/null 2>&1; then
  log "[INFO] Koneksi internet OK."
else
  FAIL_COUNT=\$((FAIL_COUNT + 1))
  log "[WARNING] Tidak ada koneksi internet (percobaan \$FAIL_COUNT/\$MAX_FAIL)."
  if [ \$FAIL_COUNT -ge \$MAX_FAIL ]; then
    log "[ERROR] Internet mati. Restart modem Huawei..."
    sudo bash "\$RESTART_SCRIPT"
    log "[INFO] Menunggu modem kembali aktif..."
    sleep 20
  fi
fi
EOF

sudo chmod +x "$MONITOR_SCRIPT"
echo "[OK] Script monitor dibuat di: $MONITOR_SCRIPT"

echo "[INFO] Menambahkan crontab otomatis..."
# Hapus entri lama jika ada
sudo crontab -l 2>/dev/null | grep -v "$MONITOR_SCRIPT" | sudo crontab -
# Tambahkan cron job baru (jalan tiap menit)
( sudo crontab -l 2>/dev/null; echo "30 */2 * * * /usr/bin/sudo $MONITOR_SCRIPT >> $LOG_FILE 2>&1" ) | sudo crontab -

echo "[OK] Crontab sudah diset untuk menjalankan monitor setiap 1 menit."
echo "[DONE] Setup selesai."
echo ""
echo "📄 Log akan disimpan di: $LOG_FILE"
echo "🔁 Cron job aktif: jalankan 'sudo crontab -l' untuk melihat."
