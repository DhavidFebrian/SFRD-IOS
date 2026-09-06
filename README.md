# 📱 RWC - Media Production (iOS & Multiplatform)

Project aplikasi mobile **RWC - Media Production** (sebelumnya SFRD) berbasis **Flutter** yang dirancang khusus untuk berjalan di **iOS (iPhone/iPad)** dan Android.

> [!NOTE]
> Project ini dibuat terpisah dari project Android asli (`SFRD`) sehingga seluruh kode Android Anda sebelumnya tetap utuh 100%.

---

## 🚀 Cara Build File `.ipa` (iOS) Tanpa Memiliki Komputer Mac

Karena Anda menggunakan Windows, pembuatan file installer iOS (`.ipa`) dilakukan secara otomatis menggunakan **GitHub Actions** yang berjalan di server Mac cloud milik GitHub (gratis).

### Langkah 1: Push Project ini ke Repository GitHub
Jalankan file helper `push_to_github.bat` di folder `SFRD_IOS`, atau jalankan perintah:
```bash
git add .
git commit -m "Update RWC - Media Production iOS v8.8.11"
git push origin main
```

### Langkah 2: Tunggu Build Otomatis di GitHub
1. Buka halaman repository Anda di GitHub: [https://github.com/DhavidFebrian/SFRD-IOS](https://github.com/DhavidFebrian/SFRD-IOS)
2. Klik tab **Actions**.
3. Workflow **"Build iOS IPA & Multiplatform"** akan otomatis berjalan di server macOS cloud.
4. Setelah selesai (bercentang hijau), klik build tersebut dan scroll ke bagian **Artifacts**.
5. Download file zip **`RWC-Media-Production-iOS-IPA`** yang berisi file installer `RWC-Media-Production.ipa`.

---

## 📲 Cara Install File `.ipa` ke iPhone dari Komputer Windows

### Opsi 1: Menggunakan 3uTools (Sudah Terpasang di PC Ini!)
1. Buka aplikasi **3uTools** yang sudah terpasang di PC Anda (`C:\Program Files\3uTools9\3uTools.exe`).
2. Sambungkan iPhone ke laptop menggunakan kabel USB. Buka kunci iPhone dan pilih **Trust this computer** jika muncul pop-up.
3. Di 3uTools:
   - **Metode A (IPA Signature)**: Masuk ke tab **Toolbox** > klik **IPA Signature** > klik **Add IPA** (pilih file `.ipa` yang sudah didownload) > pilih **Sign with Apple ID** > masukkan Apple ID Anda > klik **Start Signing**. Setelah signed, klik **Install**.
   - **Metode B (Apps Install)**: Masuk ke tab **Apps** > klik **Import & Install ipa** > pilih file `.ipa`.
4. Di iPhone: Buka **Settings > General > VPN & Device Management**, klik nama Apple ID Anda, lalu tekan **Trust**.
5. Buka aplikasi **RWC - Media Production** di iPhone dan mulai gunakan!

### Opsi 2: Menggunakan Sideloadly
1. Download & install **[Sideloadly](https://sideloadly.io/)** di laptop Windows.
2. Sambungkan iPhone via USB, drag & drop file `.ipa` ke Sideloadly, masukkan Apple ID dan klik **Start**.
3. Di iPhone: Buka **Settings > General > VPN & Device Management** > klik **Trust**.

---

## 📂 Struktur Modul & Fitur (SFRD_IOS)

- `lib/core/services/sheets_service.dart` : Komunikasi backend dengan Google Apps Script.
- `lib/features/dashboard/` : Dashboard utama RWC dengan quick stats (Aktif, Done, Foto Ulang, Total).
- `lib/features/weekly_meeting/` : Manajemen listing Weekly Meeting, autofill Nama ME, live preview catatan, pencarian, dan broadcast WhatsApp.
- `lib/features/attendance/` : Antarmuka presensi wajah (Face Recognition).
- `lib/features/marketing/` : Generator mockup Instagram (rasio 1:1, 4:5, 9:16), editor caption, dan WhatsApp Blast.
- `lib/features/tasks/` : Manajemen tugas & jadwal survei properti.
- `lib/features/settings/` : Profil pengguna, info versi v8.8.11 (Build 891), dan ganti URL Google Apps Script.
- `ios/Runner/Info.plist` : Konfigurasi perizinan Apple (Kamera, Galeri Foto, Lokasi).
- `.github/workflows/build_ios.yml` : Otomatisasi compile `.ipa` di cloud Mac.
