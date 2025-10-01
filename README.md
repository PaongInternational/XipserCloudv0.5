XipserCloud - Server Minecraft PaperMC Super-Optimized
Proyek ini adalah solusi All-in-One untuk menjalankan server Minecraft PaperMC (1.20.4) yang sangat stabil di Termux.
Semua logika (instalasi, peluncuran, auto-shutdown, Ngrok, admin) digabungkan ke dalam satu file xipsercloud.sh untuk mencegah error path.
✨ Spesifikasi Inti Server
| Fitur | Detail |
|---|---|
| RAM Alokasi | 3 GB (3072\text{M}) dengan Aikar's Flags (Jaminan Anti-Lag). |
| Kualitas Server | View Distance 10, Max Pemain 30. |
| Admin System | Dikelola via admin_database.txt. Otomatis OP saat server diluncurkan. |
| Klaim Wilayah | Plugin GriefPrevention (Golden Shovel otomatis dan permanen). |
| Keselamatan | Auto-Shutdown Aman jika Baterai < 5% atau Waktu Berjalan > 12 Jam. |
🚀 Alur Instalasi (Wajib Diikuti BERURUTAN)
Ikuti langkah-langkah ini dengan tepat di Termux.
Langkah 1: Clone Repositori dan Beri Izin
# 1. Instal Git, Update paket, dan instal Termux-API
pkg update -y && pkg install git -y

# 2. Clone repositori ini (Ganti <URL> dengan URL GitHub Anda)
git clone [https://github.com/URL_REPOSITORI_ANDA/XipserCloud.git](https://github.com/URL_REPOSITORI_ANDA/XipserCloud.git) 

# 3. Masuk ke folder proyek
cd XipserCloud

# 4. Berikan izin eksekusi pada skrip utama
chmod +x xipsercloud.sh

Langkah 2: Konfigurasi Database Admin
Buat file admin_database.txt dan isi username admin Anda.
nano admin_database.txt

Isi dengan username Minecraft Anda (satu per baris). Simpan (Ctrl+X, lalu Y, lalu Enter).
Langkah 3: Jalankan Skrip dan Server! (All-in-One)
Skrip ini akan otomatis melakukan instalasi, konfigurasi, dan peluncuran server.
./xipsercloud.sh

> CATATAN: Server akan memakan waktu 1-2 menit untuk loading pertama kali (mengunduh PaperMC, membuat folder, dan mengkonfigurasi EULA). Begitu proses selesai, Anda akan otomatis terhubung ke konsol server.
> 
