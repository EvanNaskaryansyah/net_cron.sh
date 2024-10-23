#!/bin/sh
# Created By : Riski Pradana Adam
# Created on : 2 July 2021
# Updated on : 13 July 2021
#-----------------------------

set_l2tp() { 
# Created By : Maulana Ibrahim
# 15-11-2019
#-----------------------------
echo "========================================="
echo "         Konfigurasi VPN L2TP            "
echo "========================================="
echo "Menginstal xl2tpd"
sudo apt-get install xl2tpd -y
echo "Membuat file xl2tpd.conf..."
cat << EOF > /etc/xl2tpd/xl2tpd.conf
[lac vpn-connection]
lns = vpn.dispenda.online
require chap = yes
refuse pap = yes
ppp debug = yes
pppoptfile = /etc/ppp/options.l2tpd.client
length bit = yes
EOF

# mv xl2tpd.conf /etc/xl2tpd/xl2tpd.conf
echo "Membuat file options.l2tpd.conf..."
echo "Masukan user VPN WP :"
read user
echo "Passwordnya ?"
read password

cat << EOF > /etc/ppp/options.l2tpd.client
name $user
password $password
require-mschap-v2
noccp
noauth
mtu 1280
mru 1280
noipdefault
usepeerdns
connect-delay 5000
EOF
#mv options.l2tpd.client /etc/ppp/options.l2tpd.client
echo "Mendownload file net_cron.sh..."
#wget -t 3 -T 30 -q -O /home/pinisi/net_cron.sh "https://csa-pinisielektra.000webhostapp.com/net_cron.sh"
wget -t 3 -T 30 -q -O /home/pinisi/net_cron.sh "https://raw.githubusercontent.com/EvanNaskaryansyah/net_cron.sh/refs/heads/main/net_cron.sh"
# mv net_cron.sh /home/pinisi/net_cron.sh
chmod +x /home/pinisi/net_cron.sh
echo "Setting crontab"
(crontab -l ; echo "* * * * * /home/pinisi/net_cron.sh")| crontab -
echo "Selesai seting. Ujicoba VPN L2TP.. Silahkan tunggu.."

/bin/bash /home/pinisi/net_cron.sh
echo "Jangan lupa cek kembali crontab..." 
echo "Selesai..." 

}

set_pptp() { 
# Created By : Maulana Ibrahim
# 15-11-2019
#-----------------------------
echo "========================================="
echo "         Konfigurasi VPN PPTP            "
echo "========================================="
echo "Menginstal pptp-linux & ntp"
sudo apt-get install pptp-linux
sudo apt-get install ntp -y

echo "Membuat file chap-secrets..."
echo "Masukan user VPN WP :"
read user
echo "Passwordnya ?"
read password
cat << EOF > /etc/ppp/chap-secrets
# Secrets for authentication using CHAP
# client        server  secret                  IP addresses
$user PPTP   $password        vpn.dispenda.online
EOF
#mv chap-secrets /etc/ppp/chap-secrets

echo "Membuat file loginvpn..."
cat << EOF > /etc/ppp/peers/loginvpn
pty "pptp vpn.dispenda.online --nolaunchpppd"
name $user #uservpn diganti dengan user yang dibuat untuk setiap wp
remotename PPTP
require-mppe-128
file /etc/ppp/options.pptp
ipparam loginvpn
EOF
# mv loginvpn /etc/ppp/peers/loginvpn

echo "Mendownload file pptp-cron.sh..."
wget -t 3 -T 30 -q -O /home/pinisi/pptp-cron.sh "https://csa-pinisielektra.000webhostapp.com/pptp-cron.sh"
# mv pptp-cron.sh /home/pinisi/pptp-cron.sh
chmod +x /home/pinisi/pptp-cron.sh
echo "Setting crontab"
(crontab -l ; echo "* * * * * /home/pinisi/pptp-cron.sh")| crontab -
echo "Selesai seting. Ujicoba VPN PPTP.. Silahkan tunggu.."

/bin/bash /home/pinisi/pptp-cron.sh
echo "Jangan lupa cek kembali crontab..." 
echo "Selesai..." 
}

set_masterconf(){
echo "========================================="
echo "      Konfigurasi FTP (master.conf)      "
echo "========================================="
echo "Masukan HOST FTP:"
read hostftp
echo "Masukan User FTP :"
read userftp
echo "Masukan Password FTP :"
read passftp
echo "Masukan Lokasi Folder :"
read pathftp

cat << EOF > /home/pajak/script/master.conf
#Tipe Perangkat
#1=MasterUSB;2=MasterSerial;3=MasterParalel
Tipe=2

#Jumlah Finger Serial
nFingerSerial=0

#Konfigurasi Master Serial
IDMaster=TMD-Master
PortMaster=/dev/ttyO1
BaudMaster=9600

#Konfigurasi Finger Serial
IDFinger1=KasirSerial1
PortFinger1=/dev/ttyO2
BaudFinger1=9600

IDFinger2=KasirSerial2
PortFinger2=/dev/ttyO4
BaudFinger2=9600

IDFinger3=KasirSerial3
PortFinger3=/dev/ttyO5
BaudFinger3=9600

#Konfigurasi Modem
ModemPort=/dev/ttyUSB0
ModemBaud=115200

#Konfigurasi FTP Server
ftphost= $hostftp
ftpuser= $userftp
ftppass= $passftp
ftphome= $pathftp

#Konfigurasi SMS
NomorTujuan=08
EOF
# mv master.conf /home/pajak/script/master.conf
echo "Selesai..." 
}

set_status(){
echo "========================================="
echo "         Konfigurasi File Status         "
echo "========================================="
echo "Masukan Nama file status (ex: maqnahotel_gorontalo)  :"
read filename

cat > /home/pinisi/checkstatus.sh << "EOF2"
#!/bin/sh
dd=`date "+%Y-%m-%d %H:%M:%S"`
d=`date "+%Y-%m-%d"`
EOF2
cat << EOF >> /home/pinisi/checkstatus.sh
wp="$filename"
EOF
cat >> /home/pinisi/checkstatus.sh << "EOF2"
namafile="/home/data/"$wp"_Status_"$d".txt"
echo $dd",ON,"$wp > $namafile
EOF2
# mv checkstatus.sh /home/pinisi/checkstatus.sh
echo "Selesai..." 

}

set_autoreboot(){
# Created By : Anggita, Arianto Bahar, Guntur
echo "========================================="
echo "       Konfigurasi Auto Reboot TMD       "
echo "========================================="
cat > /home/pinisi/autoreboot.sh << "EOF2"
#!/bin/sh
/sbin/reboot
EOF2

chmod +x /home/pinisi/autoreboot.sh
(crontab -l ; echo "45 15 * * 2,6 /home/pinisi/autoreboot.sh")| crontab -

echo "Berhasil dibuat.. default : 45 15 * * 2,6 (Silahkan ganti di crontab)"
sleep 3
crontab -e
echo "Selesai..." 
}

set_tanggal(){
# Created By : Guntur, Sadly, Dhean
echo "========================================="
echo "       Konfigurasi Tanggal TMD           "
echo "========================================="
echo "Print dev/rtc.. (Pastikan rtc1 ada)" 
ls -l /dev/rtc*
echo "Membuka Konfigurasi tzdata, Mohon tunggu.."
sleep 3
sudo dpkg-reconfigure tzdata
echo "Waktu saat ini :" 
date
echo "Selesai..." 
}

set_crontab_modem(){
chmod +x /home/pajak/modem.sh
(crontab -l ; echo "0 0 * * * /home/pajak/modem.sh")| crontab -

echo "Setingan Crontab Berhasil dibuat.. default : 0 0 * * * (Silahkan ganti sesuai keperluan di crontab)"
sleep 3
crontab -e
echo "Menjalankan fungsi reset..."
sleep 2
sudo /home/pajak/modem.sh
echo "Selesai..." 
}

set_reset_modem(){
#----------------
#create.nando
#27-05-2021
#pinisi-elektra
#----------------
echo "========================================="
echo "       Konfigurasi Reset All Modem       "
echo "========================================="

echo "Pilih tipe Modem yang akan direset/restart :"
echo "1. Modem Huawei E3372 (hitam) atau Modem Airtel 4G (putih) "
echo "2. Modem Telkomsel dt-100"
echo "3. Modem Arab E3276"
echo "4. Modem Vodafone"
echo "Pilihan Anda :" 
read pilihan 

if [ $pilihan = 1 ]; then
cat > /home/pajak/modem.sh << "EOF2"
#!/bin/sh
sudo usb_modeswitch huawei-new-mode -v 0x12d1 -p 0x14dc --reset-usb
EOF2
fi
if [ $pilihan = 2 ]; then
cat > /home/pajak/modem.sh << "EOF2"
#!/bin/sh
sudo usb_modeswitch -W -c /home/pinisi/usb-modeswitch-data-20170806/usb_modeswitch.d/05c6\:f000 -v 05c6 -p f000 -reset-usb
EOF2
fi
if [ $pilihan = 3 ]; then
cat > /home/pajak/modem.sh << "EOF2"
#!/bin/sh
sudo usb_modeswitch huawei-new-mode -v 0x12d1 -p 0x14db --reset-usb
EOF2
fi
if [ $pilihan = 4 ]; then
cat > /home/pajak/modem.sh << "EOF2"
#!/bin/sh
sudo usb_modeswitch huawei-new-mode -v 0x19d2 -p 0x1405 --reset-usb
EOF2
fi
set_crontab_modem
}

set_auto_cleanup(){
# Created By : Khalif
echo "========================================="
echo "   Konfigurasi Auto Cleanup Temporary    "
echo "========================================="
cat > /home/pinisi/autocleanup.sh << "EOF2"
#!/bin/sh
rm /home/pajak/log/*.log
EOF2

chmod +x /home/pinisi/autocleanup.sh
(crontab -l ; echo "0 * */30 * * /home/pinisi/autocleanup.sh")| crontab -
echo "Menjalankan penghapusan file log (dir : /home/pajak/log)....."
/home/pinisi/autocleanup.sh
sleep 2
echo "Setingan Crontab Berhasil dibuat.. default : 0 * */30 * * (Silahkan ganti di crontab)"
sleep 3
crontab -e
echo "Selesai..." 
}

echo "========================================================="
echo "           .::SCT (Simple Configuration TMD)::.          " 
echo "           Silahkan pilih menu yang dibutuhkan           " 
echo "========================================================="
echo "1. Setup VPN L2TP"
echo "2. Setup VPN PPTP"
echo "3. Seting File Status"
echo "4. Seting master.conf"
echo "5. Menu 1-3-4 "
echo "6. Menu 2-3-4"
echo "7. Seting autoreboot TMD"
echo "8. Konfigurasi Tanggal TMD"
echo "9. Reset All Modem"
echo "10. Auto Cleanup Temporary TMD (File Log)"
echo "11. Exit"
echo "========================================================="
echo "Pilihan Anda :" 
read perintah 

if [ $perintah = 1 ]; then
	set_l2tp
fi
if [ $perintah = 2 ]; then
	set_pptp
fi
if [ $perintah = 3 ]; then
	set_status
fi
if [ $perintah = 4 ]; then
	set_masterconf
fi
if [ $perintah = 5 ]; then
	set_l2tp
	set_status
	set_masterconf
fi
if [ $perintah = 6 ]; then
	set_pptp
	set_status
	set_masterconf
fi
if [ $perintah = 7 ]; then
	set_autoreboot
fi
if [ $perintah = 8 ]; then
	set_tanggal
fi
if [ $perintah = 9 ]; then
	set_reset_modem
fi
if [ $perintah = 10 ]; then
	set_auto_cleanup
fi
if [ $perintah = 11 ]; then
	exit 0
fi
