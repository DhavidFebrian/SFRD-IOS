# 📱 SFRD iOS & Multiplatform Project

Project aplikasi mobile SFRD berbasis **Flutter** yang dirancang khusus untuk berjalan di **iOS (iPhone/iPad)** dan Android.

> [!NOTE]
> Project ini dibuat terpisah dari project Android asli (`SFRD`) sehingga seluruh kode Android Anda sebelumnya tetap utuh 100%.

---

## 🚀 Cara Build File `.ipa` (iOS) Tanpa Memiliki Komputer Mac

Karena Anda menggunakan Windows, pembuatan file installer iOS (`.ipa`) dilakukan secara otomatis menggunakan **GitHub Actions** yang berjalan di server Mac cloud milik GitHub (gratis).

### Langkah 1: Push Project ini ke Repository GitHub
1. Buat repository baru di GitHub Anda (misalnya bernama `SFRD-iOS`).
2. Di terminal, masuk ke folder `SFRD_IOS`:
   ```bash
   cd SFRD_IOS
   git init
   git add .
   git commit -m "Initial commit for SFRD iOS"
   git branch -M main
   git remote add origin https://github.com/USERNAME-KAMU/SFRD-iOS.git
   git push -u origin main
   ```

### Langkah 2: Tunggu Build Otomatis di GitHub
1. Buka halaman repository Anda di GitHub.
2. Klik tab **Actions**.
3. Workflow **"Build iOS IPA & Multiplatform"** akan otomatis berjalan di server macOS.
4. Setelah selesai (bercentang hijau), klik build tersebut dan scroll ke bagian **Artifacts**.
5. Download file zip **`SFRD-iOS-IPA`** yang berisi file installer `SFRD-Release.ipa`.

---

## 📲 Cara Install File `.ipa` ke iPhone dari Windows

Anda bisa menginstall file `.ipa` ke iPhone tanpa Mac menggunakan salah satu tools gratis berikut:

### Opsi A: Menggunakan Sideloadly (Paling Mudah di Windows)
1. Download & install **[Sideloadly](https://sideloadly.io/)** di laptop Windows Anda.
2. Sambungkan iPhone ke laptop menggunakan kabel USB.
3. Buka Sideloadly, drag & drop file `SFRD-Release.ipa` ke dalam aplikasi Sideloadly.
4. Masukkan Apple ID Anda dan klik **Start**.
5. Di iPhone Anda: Buka **Settings > General > VPN & Device Management**, lalu klik *Trust* pada Apple ID Anda.
6. Aplikasi SFRD langsung bisa dibuka di iPhone!

### Opsi B: Menggunakan AltStore
1. Download **[AltServer Windows](https://altstore.io/)**.
2. Install AltStore ke iPhone Anda lewat AltServer.
3. Kirim file `.ipa` ke iPhone (lewat iCloud Drive, Telegram, atau AirDrop), lalu buka via AltStore untuk menginstall.

---

## 📂 Struktur Modul & Fitur (SFRD_IOS)

- `lib/features/dashboard/` : Dashboard utama dengan quick stats dan menu navigasi.
- `lib/features/weekly_meeting/` : Manajemen listing Weekly Meeting, autofill Nama ME, live preview catatan, dan broadcast WhatsApp.
- `lib/features/attendance/` : Antarmuka presensi wajah (Face Recognition).
- `lib/features/marketing/` : Generator mockup Instagram (rasio 1:1, 4:5, 9:16) dan WhatsApp Blast.
- `lib/features/tasks/` : Manajemen tugas & jadwal survei properti.
- `lib/features/settings/` : Profil pengguna dan konfigurasi aplikasi.
- `ios/Runner/Info.plist` : Konfigurasi perizinan Apple (Kamera, Galeri Foto, Lokasi).
- `.github/workflows/build_ios.yml` : Otomatisasi compile `.ipa` di cloud Mac.
