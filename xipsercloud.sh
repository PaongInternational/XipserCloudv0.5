#!/bin/bash
# XIPSERCLOUD - SKRIP ALL-IN-ONE (SETUP, MONITOR, START)
# VERSI FINAL - Mendukung Java & Bedrock, RAM Dinamis, Tampilan Estetik, dan 2 IP Publik.

# --- WARNA ANSI ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BG_GREEN='\033[42m\033[1;37m'
BG_RED='\033[41m\033[1;37m'
BOLD='\033[1m'

# --- KONFIGURASI UMUM & DEFAULT ---
SERVER_JAR="paper.jar"
MINECRAFT_PORT=25565
MINECRAFT_VERSION="1.20.4"
NGROK_TOKEN="33RKXoLi8mLMccvpJbo1LoN3fCg_4AEGykdpBZeXx2TFHaCQj"
RAM_CONFIG_FILE="config_ram.txt"
DEFAULT_RAM="4096M" # 4 GB Default

# ARRAY NAMA ACAK XIPSER
NAMA_ACAK=("Phoenix" "Dragon" "Nova" "Aether" "Comet" "Titan" "Galaksi" "Komet" "Bintang" "Emas" "Inti")
RANDOM_NAME="${NAMA_ACAK[$RANDOM % ${#NAMA_ACAK[@]}]}"
SERVER_NAME="Xipser-$RANDOM_NAME"

# SCREEN SESSIONS
SCREEN_SESSION_MC="mc"
SCREEN_SESSION_NGROK="ngrok"
SCREEN_SESSION_MONITOR="monitor"

# --- FUNGSI PENGATURAN RAM ---
function set_ram() {
    local ram_value=$1
    if [[ -z "$ram_value" ]]; then
        echo -e "${RED}❌ ERROR:${NC} Harap masukkan nilai RAM yang valid (contoh: 4G atau 8192M)."
        echo -e "Penggunaan: ${YELLOW}./xipsercloud.sh set_ram <nilai_ram>${NC}"
        return 1
    fi

    local clean_ram=$(echo "$ram_value" | tr '[:lower:]' '[:upper:]')
    if [[ "$clean_ram" =~ ^[0-9]+[G]$ ]]; then
        clean_ram=$(echo "$clean_ram" | sed 's/G$//')
        clean_ram=$((clean_ram * 1024))M
    fi
    
    if [[ "$clean_ram" =~ ^[0-9]+[M]$ ]]; then
        echo "$clean_ram" > "$RAM_CONFIG_FILE"
        echo -e "${BG_GREEN}✅ BERHASIL:${NC} RAM server berhasil diatur ke: ${BOLD}$clean_ram${NC}"
        echo "RAM baru akan digunakan pada peluncuran server berikutnya."
    else
        echo -e "${RED}❌ ERROR:${NC} Format RAM tidak valid. Gunakan format seperti ${YELLOW}4G, 6G, atau 8192M${NC}."
        return 1
    fi
}

# --- FUNGSI PEMBACA RAM ---
function get_ram() {
    if [ -f "$RAM_CONFIG_FILE" ]; then
        local configured_ram=$(cat "$RAM_CONFIG_FILE" | tr -d '\n')
        if [[ "$configured_ram" =~ ^[0-9]+[M]$ ]]; then
            echo "$configured_ram"
            return 0
        fi
    fi
    
    echo "$DEFAULT_RAM"
    return 0
}

# --- FUNGSI 1: SHUTDOWN AMAN (Jaminan Dunia Tersimpan) ---
function safe_shutdown() {
    local reason=$1
    
    echo -e "${PURPLE}[MONITOR]${NC} Memicu shutdown aman: $reason"
    
    # Perintah simpan dunia dan matikan server
    screen -S $SCREEN_SESSION_MC -X stuff "say §c[SERVER] §4Otomatis mati dalam 60 detik! Dunia sedang disimpan...\n"
    sleep 30
    screen -S $SCREEN_SESSION_MC -X stuff "say §c[SERVER] §4Shutdown final dalam 30 detik! Menyimpan dunia...\n"
    sleep 30

    screen -S $SCREEN_SESSION_MC -X stuff "save-all\n" # Jaminan Simpan Dunia
    sleep 5
    screen -S $SCREEN_SESSION_MC -X stuff "stop\n"
    
    echo -e "${PURPLE}[MONITOR]${NC} Server Minecraft telah diperintahkan untuk mati. Dunia tersimpan aman."
    exit 0
}

# --- FUNGSI 2: MONITOR OTOMATIS ---
function monitor_server() {
    MAX_RUNTIME_SECONDS=$((12 * 60 * 60)) 
    LOW_BATTERY_THRESHOLD=5              
    CHECK_INTERVAL_SECONDS=60            
    RUNTIME_START=$(date +%s)
    
    echo -e "${PURPLE}Monitor Otomatis Aktif (Shutdown: 12 jam / Baterai $LOW_BATTERY_THRESHOLD%).${NC}"
    
    while true; do
        if ! screen -list | grep -q ".$SCREEN_SESSION_MC"; then
            echo -e "${PURPLE}[MONITOR]${NC} Sesi server 'mc' tidak aktif. Mengakhiri monitor."
            exit 0
        fi
        
        CURRENT_TIME=$(date +%s)
        RUNTIME=$((CURRENT_TIME - RUNTIME_START))
        
        if [ $RUNTIME -ge $MAX_RUNTIME_SECONDS ]; then
            safe_shutdown "Waktu maksimal berjalan (12 jam) telah tercapai"
        fi
        
        if command -v termux-battery-status &> /dev/null; then
            BATTERY_INFO=$(termux-battery-status 2>/dev/null)
            BATTERY_PERCENTAGE=$(echo "$BATTERY_INFO" | jq -r '.percentage' 2>/dev/null)
            PLUGGED_STATUS=$(echo "$BATTERY_INFO" | jq -r '.plugged' 2>/dev/null)

            if [ -n "$BATTERY_PERCENTAGE" ] && [ "$BATTERY_PERCENTAGE" -le "$LOW_BATTERY_THRESHOLD" ]; then
                 if [ "$PLUGGED_STATUS" == "UNPLUGGED" ] || [ "$PLUGGED_STATUS" == "UNKNOWN" ]; then
                     safe_shutdown "Baterai perangkat hanya tersisa ${LOW_BATTERY_THRESHOLD}%"
                 fi
            fi
        fi

        sleep $CHECK_INTERVAL_SECONDS
    done
}

# --- FUNGSI 3: PROSES ADMIN DATABASE ---
function process_admins() {
    echo -e "${CYAN}MEMPROSES DATABASE ADMIN...${NC}"
    
    if [ -f "admin_database.txt" ]; then
        while IFS= read -r player_name; do
            if [[ -n "$player_name" && ! "$player_name" =~ ^# ]]; then
                echo -e "${CYAN} -> ${NC}Mengirim perintah OP untuk: ${BOLD}$player_name${NC}"
                screen -S $SCREEN_SESSION_MC -X stuff "op $player_name\n"
                sleep 0.5 
            fi
        done < admin_database.txt
        echo -e "${BG_GREEN}✅ BERHASIL:${NC} SEMUA ADMIN DARI DATABASE TELAH DIPROSES."
    else
        echo -e "${YELLOW}PERINGATAN:${NC} admin_database.txt tidak ditemukan. Tidak ada admin yang didaftarkan."
    fi
}

# --- FUNGSI 4: MENGAMBIL IP PUBLIC DARI INTERNET ---
function get_external_ip() {
    if command -v curl &> /dev/null; then
        curl -s icanhazip.com
    else
        echo "N/A (CURL tidak terinstal)"
    fi
}

# --- FUNGSI UTAMA: SETUP & START ---

function main_setup_and_start() {
    local MAX_RAM_CURRENT=$(get_ram)
    local AIKAR_FLAGS_CURRENT="-Xms512M -Xmx$MAX_RAM_CURRENT -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+AggressiveOpts -XX:G1HeapRegionSize=16M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedSiteCount=4 -XX:G1MixedSiteRatio=3 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://aikar.co/mcflags.html"

    echo -e "${BLUE}==========================================================${NC}"
    echo -e "${BOLD}${CYAN}          [XIPSERCLOUD] Setup & Launch Script             ${NC}"
    echo -e "${BLUE}==========================================================${NC}"
    echo -e "  ${YELLOW}NAMA SERVER:${NC} ${BOLD}${SERVER_NAME}${NC}"
    echo -e "  ${YELLOW}RAM DIGUNAKAN:${NC} ${BOLD}$MAX_RAM_CURRENT${NC}"
    echo -e "  ${YELLOW}SUPPORT:${NC} ${GREEN}JAVA (PC)${NC} & ${CYAN}BEDROCK (Play Store)${NC}"
    echo -e "${BLUE}==========================================================${NC}"

    # --- SETUP TAHAP 1: INSTALASI DEPENDENSI ---
    echo -e "${GREEN}[SETUP]${NC} Memperbarui paket Termux dan menginstal Java 17, Ngrok, jq, termux-api, curl..."
    pkg update -y
    pkg install openjdk-17 wget screen ngrok jq termux-api curl -y
    
    # Konfigurasi Ngrok
    echo -e "${GREEN}[SETUP]${NC} Mengkonfigurasi Ngrok dengan token Anda..."
    ngrok authtoken $NGROK_TOKEN

    # --- SETUP TAHAP 2: DOWNLOAD CORE SERVER & KONFIGURASI ---
    echo -e "${GREEN}[SETUP]${NC} Mengambil URL download PaperMC ${MINECRAFT_VERSION} yang valid..."
    API_URL="https://api.papermc.io/v2/projects/paper/versions/$MINECRAFT_VERSION/builds"
    BUILD_INFO=$(wget -qO- "$API_URL" | jq -r '.builds | last')
    BUILD_NUMBER=$(echo "$BUILD_INFO" | jq -r '.build')
    DOWNLOAD_PATH=$(echo "$BUILD_INFO" | jq -r '.downloads.application.name')
    
    if [ -z "$BUILD_NUMBER" ]; then
        echo -e "${BG_RED}❌ ERROR:${NC} Gagal mengambil data build PaperMC. Cek koneksi internet."
        exit 1
    fi
    PAPER_URL="https://api.papermc.io/v2/projects/paper/versions/$MINECRAFT_VERSION/builds/$BUILD_NUMBER/downloads/$DOWNLOAD_PATH"
    
    if [ -f "$SERVER_JAR" ]; then
        echo -e "${GREEN}[SETUP]${NC} Menghapus file paper.jar lama..."
        rm -f "$SERVER_JAR"
    fi
    
    echo -e "${GREEN}[SETUP]${NC} Mengunduh server PaperMC ${MINECRAFT_VERSION} (Build ${BUILD_NUMBER})..."
    wget -O $SERVER_JAR "$PAPER_URL"
    
    if [ ! -f "$SERVER_JAR" ] || [ "$(du -b "$SERVER_JAR" | cut -f 1)" -lt 1000 ]; then
        echo -e "${BG_RED}❌ ERROR:${NC} File JAR gagal diunduh atau ukurannya korup."
        exit 1
    fi

    # EULA dan Konfigurasi Awal
    echo -e "${GREEN}[SETUP]${NC} Menerima EULA dan menjalankan sebentar untuk konfigurasi awal..."
    echo "eula=true" > eula.txt

    if [ ! -f "server.properties" ]; then
        java -Xms128M -Xmx256M -jar $SERVER_JAR --nogui &
        SERVER_PID=$!
        sleep 20
        kill $SERVER_PID
        wait $SERVER_PID 2>/dev/null
    fi

    # Modifikasi server.properties
    echo -e "${GREEN}[SETUP]${NC} Mengatur server.properties..."
    SERVER_MOTD="§l§6${SERVER_NAME} §r§f- §aMulti-Version Server§r"
    sed -i 's/max-players=20/max-players=30/' server.properties
    sed -i 's/view-distance=10/view-distance=10/' server.properties
    sed -i "s/motd=A Minecraft Server/motd=${SERVER_MOTD}/g" server.properties
    sed -i 's/online-mode=true/online-mode=false/' server.properties 

    # --- TAHAP 3: INSTALASI PLUGIN MULTI-VERSION ---
    echo -e "${YELLOW}--- INSTALASI PLUGIN WAJIB (GriefPrevention, Geyser, Floodgate) ---${NC}"
    mkdir -p plugins
    
    # Plugin URLs
    GP_URL="https://dev.bukkit.org/projects/grief-prevention/files/4908920/download"
    GEYSER_URL="https://ci.opencdn.xyz/job/GeyserMC/Geyser/master/latest/artifact/bootstrap/build/libs/Geyser-Spigot.jar"
    FLOODGATE_URL="https://ci.opencdn.xyz/job/GeyserMC/Floodgate/master/latest/artifact/spigot/build/libs/floodgate-spigot.jar"

    for plugin_url in "$GP_URL" "$GEYSER_URL" "$FLOODGATE_URL"; do
        PLUGIN_NAME=$(basename "$plugin_url")
        PLUGIN_FILE="plugins/$PLUGIN_NAME"
        if [ ! -f "$PLUGIN_FILE" ]; then
            echo -e "${GREEN}[SETUP]${NC} Mengunduh $PLUGIN_NAME..."
            wget -O "$PLUGIN_FILE" "$plugin_url"
        fi
    done

    # Konfigurasi GriefPrevention
    GP_CONFIG="plugins/GriefPrevention/config.yml"
    if [ ! -d "plugins/GriefPrevention" ]; then
        echo -e "${GREEN}[SETUP]${NC} Menjalankan sebentar untuk generate config GriefPrevention..."
        java -Xms128M -Xmx256M -jar $SERVER_JAR --nogui &
        SERVER_PID=$!
        sleep 25
        kill $SERVER_PID
        wait $SERVER_PID 2>/dev/null
    fi

    if [ -f "$GP_CONFIG" ]; then
        sed -i 's/GiveManualClaimToolOnFirstLogin: false/GiveManualClaimToolOnFirstLogin: true/' "$GP_CONFIG"
        echo -e "${GREEN}[SETUP]${NC} Konfigurasi GriefPrevention: Golden Shovel otomatis aktif."
    fi
    echo -e "${BG_GREEN}✅ SETUP SELESAI.${NC} Memulai peluncuran."

    # --- START TAHAP 4: PELUNCURAN SERVER ---
    echo -e "\n${BLUE}==========================================================${NC}"
    echo -e "${BOLD}${YELLOW}           PELUNCURAN SERVER ${SERVER_NAME}           ${NC}"
    echo -e "${BLUE}==========================================================${NC}"

    screen -wipe > /dev/null

    # 1. Memulai Ngrok 
    screen -dmS $SCREEN_SESSION_NGROK bash -c "ngrok tcp $MINECRAFT_PORT --log stdout > ngrok.log"
    echo -e "${CYAN}Memulai Ngrok (Sesi: ${SCREEN_SESSION_NGROK})...${NC}"
    sleep 5

    # 2. Memulai Monitor Otomatis
    export -f safe_shutdown monitor_server get_ram get_external_ip process_admins set_ram # Export semua fungsi penting
    screen -dmS $SCREEN_SESSION_MONITOR bash -c 'monitor_server'
    echo -e "${CYAN}Memulai Monitor Otomatis (Sesi: ${SCREEN_SESSION_MONITOR})...${NC}"

    # 3. Memulai Server Minecraft
    echo -e "${CYAN}Memulai Server PaperMC (Sesi: ${SCREEN_SESSION_MC}) dengan ${MAX_RAM_CURRENT}...${NC}"
    screen -dmS $SCREEN_SESSION_MC java $AIKAR_FLAGS_CURRENT -jar $SERVER_JAR --nogui

    # 4. Tambahkan Admin (Tunggu 60 detik)
    echo -e "${YELLOW}Menunggu 60 detik untuk server memuat agar admin dapat diproses...${NC}"
    sleep 60
    process_admins

    echo -e "${BLUE}--------------------------------------------------${NC}"

    # 5. Menampilkan IP dan Port Ngrok & IP Public (Tampilan Estetik)
    echo -e "${CYAN}Mencari Alamat Publik...${NC}"
    NGROK_URL=""
    for i in {1..15}; do
        NGROK_URL=$(grep -o 'tcp://[^[:space:]]*' ngrok.log | tail -1)
        if [ -n "$NGROK_URL" ]; then
            break
        fi
        sleep 1
    done

    EXTERNAL_IP=$(get_external_ip)

    if [ -z "$NGROK_URL" ]; then
        echo -e "${BG_RED}❌ NGROK GAGAL TERHUBUNG!${NC}"
        echo -e "${RED}  Server mungkin berjalan, tapi Ngrok gagal. Cek sesi Ngrok: screen -r $SCREEN_SESSION_NGROK${NC}"
    else
        echo -e "${BG_GREEN}✅ ALAMAT PUBLIK SIAP!${NC}"
        echo -e "  ${BOLD}NAMA SERVER: ${SERVER_NAME}${NC}"
        echo -e "  ${BOLD}----------------------------------------${NC}"
        echo -e "  ${BOLD}${CYAN}1. NGROK (INSTAN/SANGAT MUDAH):${NC}"
        echo -e "     ${BOLD}${GREEN}JAVA (PC):${NC} $NGROK_URL"
        echo -e "     ${BOLD}${GREEN}BEDROCK (HP):${NC} Host ${NGROK_URL%%:*} Port ${CYAN}19132${NC}"
        echo -e "  ${BOLD}----------------------------------------${NC}"
        echo -e "  ${BOLD}${CYAN}2. IP PUBLIC (PERMANEN/PORT FORWARD):${NC}"
        echo -e "     ${BOLD}${YELLOW}JAVA (PC):${NC} ${EXTERNAL_IP}:${MINECRAFT_PORT}"
        echo -e "     ${BOLD}${YELLOW}BEDROCK (HP):${NC} ${EXTERNAL_IP}:19132"
        echo -e "  ${BOLD}----------------------------------------${NC}"
        echo -e "${YELLOW}PERHATIAN: IP Public (No. 2) hanya bekerja jika Anda melakukan Port Forwarding di router rumah Anda!${NC}"
        echo -e "${CYAN}CATATAN: Server siap. Mabar dimulai!${NC}"
    fi

    echo -e "${BLUE}==========================================================${NC}"

    # 6. Lampirkan ke konsol server
    echo -e "${CYAN}Melampirkan ke konsol server '$SCREEN_SESSION_MC'...${NC}"
    screen -r $SCREEN_SESSION_MC
}

# --- LOGIKA PENENTUAN MODE ---
if [ "$1" == "set_ram" ]; then
    set_ram "$2"
elif [ "$1" == "start" ] || [ -z "$1" ]; then
    main_setup_and_start
else
    echo -e "${RED}❌ ERROR:${NC} Perintah tidak dikenal."
    echo "Penggunaan:"
    echo -e "  1. Jalankan Server: ${YELLOW}./xipsercloud.sh start${NC} atau ${YELLOW}./xipsercloud.sh${NC}"
    echo -e "  2. Ganti RAM: ${YELLOW}./xipsercloud.sh set_ram <nilai_ram>${NC} (contoh: 6G atau 8192M)"
fi
