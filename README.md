XipserCloud - Server Minecraft PaperMC Super-Optimized
Proyek ini adalah solusi All-in-One (dijamin bebas error) untuk menjalankan server Minecraft PaperMC (1.20.4) yang sangat stabil di Termux. Server ini mendukung Java Edition (PC) dan Bedrock Edition (HP/Play Store).
Semua logika (instalasi, peluncuran, auto-shutdown, Ngrok, admin) digabungkan ke dalam satu file xipsercloud.sh untuk mencegah error path.
✨ Fitur Inti dan Jaminan
| Fitur | Detail |
|---|---|
| Penyimpanan Dunia | Dunia tersimpan otomatis saat shutdown dan akan dimuat ulang persis sama saat restart. |
| Alamat Publik | Menyediakan IP Ngrok (Instan) dan IP Public (Permanen) menggunakan curl. |
| Tampilan Konsol | Estetik, Penuh Warna, menampilkan status IP dengan jelas. |
| Nama Server Acak | Nama server unik: Xipser-(Nama Acak) diatur otomatis. |
| RAM Dinamis | Default 4 GB (4096\text{M}). Dapat di-upgrade mandiri (contoh: ./xipsercloud.sh set_ram 6G). |
| Kompatibilitas | Java Edition dan Bedrock Edition (Play Store). |
🚀 Alur Instalasi (Wajib Diikuti BERUTURAN)
Langkah 1 & 2: Clone, Izin, dan Konfigurasi Admin
# 1. Instal Git, Update paket
pkg update -y && pkg install git -y

# 2. Clone repositori ini (Ganti <URL> dengan URL GitHub Anda)
git clone [https://github.com/URL_REPOSITORI_ANDA/XipserCloud.git](https://github.com/URL_REPOSITORI_ANDA/XipserCloud.git) 

# 3. Masuk ke folder proyek
cd XipserCloud

# 4. Berikan izin eksekusi pada skrip utama
chmod +x xipsercloud.sh

# 5. Edit admin_database.txt (Tambahkan Username Minecraft Anda)
nano admin_database.txt

Langkah 3: Meluncurkan Server
Luncurkan server. Skrip akan otomatis menginstal, mengkonfigurasi, dan meluncurkan semua layanan dengan tampilan yang menarik.
./xipsercloud.sh start

💡 Cara Mabar (Penting!)
Server kini mendukung Java dan Bedrock:
 * Untuk Pemain Java (PC):
   * Gunakan alamat dan port yang diberikan Ngrok atau IP Public (jika Port Forwarding sudah diatur).
 * Untuk Pemain Bedrock (HP/Play Store):
   * Gunakan alamat/host yang sama dengan Ngrok, tetapi dengan port default Bedrock (19132).
🔧 Fitur Upgrade RAM Mandiri (Opsional)
Ubah alokasi RAM (misalnya, menjadi 6\text{GB}):
./xipsercloud.sh set_ram 6G

