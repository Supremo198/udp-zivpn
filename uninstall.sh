#!/bin/bash

YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD_WHITE='\033[1;37m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
LIGHT_GREEN='\033[1;32m'
NC='\033[0m' # No Color
LICENSE_URL="https://raw.githubusercontent.com/Supremo198/izin/main/ip"
LICENSE_INFO_FILE="/etc/zivpn/.license_info"
if [ "$(id -u)" -ne 0 ]; then
echo "This script must be run as root. Please use sudo or run as root user." >&2
exit 1
fi
function verify_license() {
echo "Verifying installation license..."
local SERVER_IP
SERVER_IP=$(curl -4 -s ifconfig.me)
if [ -z "$SERVER_IP" ]; then
echo -e "${RED}Failed to retrieve server IP. Please check your internet connection.${NC}"
exit 1
fi
local license_data
license_data=$(curl -s "$LICENSE_URL")
if [ $? -ne 0 ] || [ -z "$license_data" ]; then
echo -e "${RED}Gagal terhubung ke server lisensi. Mohon periksa koneksi internet Anda.${NC}"
exit 1
fi
local license_entry
license_entry=$(echo "$license_data" | grep -w "$SERVER_IP")
if [ -z "$license_entry" ]; then
echo -e "${RED}Verifikasi Lisensi Gagal! IP Anda tidak terdaftar. IP: ${SERVER_IP}${NC}"
exit 1
fi
local client_name
local expiry_date_str
client_name=$(echo "$license_entry" | awk '{print $1}')
expiry_date_str=$(echo "$license_entry" | awk '{print $2}')
local expiry_timestamp
expiry_timestamp=$(date -d "$expiry_date_str" +%s)
local current_timestamp
current_timestamp=$(date +%s)
if [ "$expiry_timestamp" -le "$current_timestamp" ]; then
echo -e "${RED}Verifikasi Lisensi Gagal! Lisensi untuk IP ${SERVER_IP} telah kedaluwarsa. Tanggal Kedaluwarsa: ${expiry_date_str}${NC}"
exit 1
fi
echo -e "${LIGHT_GREEN}Verifikasi Lisensi Berhasil! Client: ${client_name}, IP: ${SERVER_IP}${NC}"
sleep 2 # Brief pause to show the message
mkdir -p /etc/zivpn
echo "CLIENT_NAME=${client_name}" > "$LICENSE_INFO_FILE"
echo "EXPIRY_DATE=${expiry_date_str}" >> "$LICENSE_INFO_FILE"
}
verify_license # <-- VERIFY LICENSE HERE
echo -e "Uninstalling ZiVPN Old..."
svc="zivpn.service"
systemctl stop $svc 1>/dev/null 2>/dev/null
systemctl disable $svc 1>/dev/null 2>/dev/null
rm -f /etc/systemd/system/$svc 1>/dev/null 2>/dev/null
echo "Removed service $svc"
if pgrep "zivpn" >/dev/null; then
killall zivpn 1>/dev/null 2>/dev/null
echo "Killed running zivpn processes"
fi
[ -d /etc/zivpn ] && rm -rf /etc/zivpn
[ -f /usr/local/bin/zivpn ] && rm -f /usr/local/bin/zivpn
if ! pgrep "zivpn" >/dev/null; then
echo "Server Stopped"
else
echo "Server Still Running"
fi
if [ ! -f /usr/local/bin/zivpn ]; then
echo "Files successfully removed"
else
echo "Some files remain, try again"
fi
echo "Cleaning Cache"
echo 3 > /proc/sys/vm/drop_caches
sysctl -w vm.drop_caches=3
echo -e "Done."
