#!/bin/bash
# XIPSERCLOUD - SKRIP ALL-IN-ONE (SETUP, MONITOR, START)
# Didesain untuk Termux agar bebas error dengan menggabungkan semua fungsi.

# --- KONFIGURASI PENTING ---
SERVER_JAR="paper.jar"
MINECRAFT_PORT=25565
MAX_RAM="3072M" # 3 GB RAM
NGROK_TOKEN="33RKXoLi8mLMccvpJbo1LoN3fCg_4AEGykdpBZeXx2TFHaCQj"

# SCREEN SESSIONS (Wajib)
SCREEN_SESSION_MC="mc"
SCREEN_SESSION_NGROK="ngrok"
SCREEN_SESSION_MONITOR="monitor"

# Aikar's Flags untuk Optimasi Kualitas Tinggi dan Anti-Lag
AIKAR_FLAGS="-Xms512M -Xmx$MAX_RAM -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+AggressiveOpts -XX:G1HeapRegionSize=16M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedSiteCount=4 -XX:G1MixedSiteRatio=3 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://aikar.co/mcflags.html"

# --- FUNGSI 1: SHUTDOWN AMAN (Untuk Monitor) ---
function safe_shutdown() {
    local reason=$1
    
    echo "[MONITOR] Memicu shutdown aman: $reason"
    
    # Kirim peringatan ke pemain melalui konsol MC
    screen -S $SCREEN_SESSION_MC -X stuff "say §c[SERVER] §4Otomatis mati dalam 60 detik! Karena: $reason. Dunia sedang disimpan...\n"
    sleep 30
    screen -S $SCREEN_SESSION_MC -X stuff "say §c[SERVER] §4Shutdown final dalam 30 detik! Menyimpan dunia...\n"
    sleep 30

    screen -S $SCREEN_SESSION_MC -X stuff "save-all\n"
    sleep 5
    screen -S $SCREEN_SESSION_MC -X stuff "stop\n"
    
    echo "[MONITOR] Server Minecraft telah diperintahkan untuk mati. Mengakhiri monitor."
    exit 0
}

# --- FUNGSI 2: MONITOR OTOMATIS (Berjalan di sesi terpisah) ---
function monitor_server() {
    # --- Konfigurasi Shutdown ---
    MAX_RUNTIME_SECONDS=$((12 * 60 * 60)) # 12 jam
    LOW_BATTERY_THRESHOLD=5              # 5 persen
    CHECK_INTERVAL_SECONDS=60            # Cek setiap 1 menit
    RUNTIME_START=$(date +%s)
    
    echo "Monitor Otomatis Aktif (Shutdown: 12 jam / Baterai $LOW_BATTERY_THRESHOLD%)."
    
    while true; do
        # 1. Cek Sesi MC (Jika sesi mc mati, monitor juga mati)
        if ! screen -list | grep -q ".$SCREEN_SESSION_MC"; then
            echo "[MONITOR] Sesi server 'mc' tidak aktif. Mengakhiri monitor."
            exit 0
        fi
        
        # 2. Cek Waktu Berjalan
        CURRENT_TIME=$(date +%s)
        RUNTIME=$((CURRENT_TIME - RUNTIME_START))
        
        if [ $RUNTIME -ge $MAX_RUNTIME_SECONDS ]; then
            safe_shutdown "Waktu maksimal berjalan (12 jam) telah tercapai"
        fi
        
        # 3. Cek Baterai (Memerlukan termux-api dan jq)
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
    echo "MEMPROSES DATABASE ADMIN..."
    
    if [ -f "admin_database.txt" ]; then
        while IFS= read -r player_name; do
            # Abaikan baris kosong dan komentar
            if [[ -n "$player_name" && ! "$player_name" =~ ^# ]]; then
                echo "-> Mengirim perintah OP untuk: $player_name"
                # Mengirim perintah '/op <username>' ke konsol Minecraft (sesi mc)
                screen -S $SCREEN_SESSION_MC -X stuff "op $player_name\n"
                sleep 0.5 
            fi
        done < admin_database.txt
        echo "✅ SEMUA ADMIN DARI DATABASE TELAH DIPROSES. Status OP kini permanen."
    else
        echo "PERINGATAN: admin_database.txt tidak ditemukan. Tidak ada admin yang didaftarkan secara otomatis."
    fi
}

# --- FUNGSI UTAMA: SETUP & START ---

function main_setup_and_start() {
    echo "=========================================================="
    echo "          [XIPSERCLOUD] Setup & Launch Script             "
    echo "=========================================================="

    # --- SETUP TAHAP 1: INSTALASI DEPENDENSI ---
    echo "[SETUP] Memperbarui paket Termux dan menginstal Java 17, Ngrok, jq, termux-api..."
    pkg update -y
    pkg install openjdk-17 wget screen ngrok jq termux-api -y
    
    # Konfigurasi Ngrok
    echo "[SETUP] Mengkonfigurasi Ngrok dengan token Anda..."
    ngrok authtoken $NGROK_TOKEN

    # --- SETUP TAHAP 2: DOWNLOAD DAN KONFIGURASI FILE SERVER ---
    
    PAPER_BUILD="514"
    MINECRAFT_VERSION="1.20.4"
    PAPER_URL="https://api.papermc.io/v2/projects/paper/versions/$MINECRAFT_VERSION/builds/$PAPER_BUILD/downloads/paper-$MINECRAFT_VERSION-$PAPER_BUILD.jar"

    if [ ! -f "$SERVER_JAR" ]; then
        echo "[SETUP] Mengunduh file server PaperMC $MINECRAFT_VERSION..."
        wget -O $SERVER_JAR "$PAPER_URL"
    fi

    # EULA dan Konfigurasi Awal
    echo "[SETUP] Menerima EULA dan menjalankan sebentar untuk konfigurasi..."
    echo "eula=true" > eula.txt

    if [ ! -f "server.properties" ]; then
        java -Xms128M -Xmx256M -jar $SERVER_JAR --nogui &
        SERVER_PID=$!
        sleep 20
        kill $SERVER_PID
        wait $SERVER_PID 2>/dev/null
    fi

    # Modifikasi server.properties
    echo "[SETUP] Mengatur server.properties: Max Pemain=30, View Distance=10, MOTD..."
    sed -i 's/max-players=20/max-players=30/' server.properties
    sed -i 's/view-distance=10/view-distance=10/' server.properties
    sed -i 's/motd=A Minecraft Server/motd=§l§6XipserCloud §r§f- §aServer Resmi§r/g' server.properties
    sed -i 's/online-mode=true/online-mode=false/' server.properties 

    # Instalasi dan Konfigurasi GriefPrevention
    echo "[SETUP] Menginstal dan mengkonfigurasi plugin GriefPrevention..."
    mkdir -p plugins
    GP_URL="https://dev.bukkit.org/projects/grief-prevention/files/4908920/download"
    if [ ! -f "plugins/GriefPrevention.jar" ]; then
        wget -O plugins/GriefPrevention.jar "$GP_URL"
    fi

    GP_CONFIG="plugins/GriefPrevention/config.yml"
    if [ -f "$GP_CONFIG" ]; then
        # Memastikan Golden Shovel diberikan otomatis
        sed -i 's/GiveManualClaimToolOnFirstLogin: false/GiveManualClaimToolOnFirstLogin: true/' $GP_CONFIG
    fi
    echo "[SETUP] Konfigurasi Server Selesai."

    # --- START TAHAP 3: PELUNCURAN SERVER ---
    echo "-------------------------------------------------"
    echo "           STARTING XIPSERCLOUD SERVER           "
    echo "-------------------------------------------------"

    # Membersihkan sesi screen yang mungkin terputus agar tidak ada error
    screen -wipe > /dev/null

    # 1. Memulai Ngrok 
    screen -dmS $SCREEN_SESSION_NGROK bash -c "ngrok tcp $MINECRAFT_PORT --log stdout > ngrok.log"
    echo "Memulai Ngrok (Sesi: $SCREEN_SESSION_NGROK)..."
    sleep 5

    # 2. Memulai Monitor Otomatis (Menggunakan fungsi monitor_server)
    # Penting: Monitor dijalankan di screen, tapi fungsinya di-export ke dalam sesi
    export -f safe_shutdown monitor_server
    screen -dmS $SCREEN_SESSION_MONITOR bash -c 'monitor_server'
    echo "Memulai Monitor Otomatis (Sesi: $SCREEN_SESSION_MONITOR)..."

    # 3. Memulai Server Minecraft
    echo "Memulai Server PaperMC (Sesi: $SCREEN_SESSION_MC) dengan $MAX_RAM..."
    screen -dmS $SCREEN_SESSION_MC java $AIKAR_FLAGS -jar $SERVER_JAR --nogui

    # 4. Tambahkan Admin (Tunggu 60 detik agar server memuat penuh)
    echo "Menunggu 60 detik untuk server memuat agar perintah OP dapat dieksekusi..."
    sleep 60
    process_admins

    echo "-------------------------------------------------"

    # 5. Menampilkan IP dan Port Ngrok
    echo "Menunggu alamat publik Ngrok..."
    NGROK_URL=""
    for i in {1..15}; do
        NGROK_URL=$(grep -o 'tcp://[^[:space:]]*' ngrok.log | tail -1)
        if [ -n "$NGROK_URL" ]; then
            break
        fi
        sleep 1
    done

    if [ -z "$NGROK_URL" ]; then
        echo "  [!] Gagal mendapatkan IP Ngrok. Coba cek manual: screen -r $SCREEN_SESSION_NGROK"
    else
        echo "  🌐 Server IP & Port (Bagikan Ini!):"
        echo "  ---> §l$NGROK_URL"
        echo "  Catatan: Server siap. Kualitas tinggi diaktifkan."
    fi

    echo "-------------------------------------------------"

    # 6. Lampirkan ke konsol server
    echo "Melampirkan ke konsol server '$SCREEN_SESSION_MC'..."
    screen -r $SCREEN_SESSION_MC
}

# Jalankan Fungsi Utama
main_setup_and_start
