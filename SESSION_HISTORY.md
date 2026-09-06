# SFRD iOS - Session History & Knowledge Base

**Tanggal**: 06 - 07 September 2026  
**Conversation ID**: `118f968f-ed5d-4653-b8ec-ec73dac2f17a`  
**Repository**: `https://github.com/DhavidFebrian/SFRD-IOS.git`  
**Lokasi Project**:
- Working/Git Repo: `c:\Users\dhavi\antigravity\SFRD\SFRD_IOS`
- Standalone Folder: `c:\Users\dhavi\antigravity\SFRD_IOS`

---

## 1. Ringkasan Milestone Proyek

### A. Migrasi & Sinkronisasi Fitur dari Android ke iOS
- Memindahkan fungsionalitas utama dari project Android (`SFRD`) ke Flutter iOS (`SFRD_IOS`).
- Sinkronisasi arsitektur MVVM / Provider state management.
- Mengaktifkan seluruh modul:
  - **Weekly Meeting**: Sinkronisasi Google Sheets live, status filter (Open, Sold, Rented, dll), indikator tugas, badge harga, dan galeri foto.
  - **Media Management**: Grid layout, status tagging, direct preview listing.
  - **Task Dashboard**: To-do list berbasis listing, checkmark update real-time.
  - **Instagram Mockup**: Generator visual feed/story otomatis dengan kanvas interaktif dan export PNG.

### B. Integrasi Website raywhitecipete.net
- **Service**: `lib/core/services/rwc_scraper_service.dart`
- **Reverse-Engineering**: Diadopsi dari `ScheduleViewModel.kt` di Android.
- **Fitur**:
  - Scraping detail properti dari `https://raywhitecipete.net/ListingView/Detail/{cleanId}`.
  - Ekstraksi gambar AWS S3 asli (unwrapping `/ListingView/Proxy?url=https://s3-ap-southeast-1.amazonaws.com/...`).
  - Filtering logo, icon, avatar, watermark untuk memastikan galeri murni foto properti.
  - Ekstraksi spesifikasi lengkap (LT, LB, KT, KM, Harga, Deskripsi, Kontak ME WhatsApp).
  - Caching lokal (SharedPreferences + In-Memory) dengan validitas 12 jam.
- **UI Widget**: `lib/core/widgets/listing_detail_bottom_sheet.dart`
  - Carousel foto swipeable dengan nomor halaman (`1 / N`).
  - Thumbnail filmstrip navigator di bawah carousel.
  - Quick action WhatsApp chat dan direct link ke website.

---

## 2. CI/CD & Build Pipeline (GitHub Actions)

### A. Workflow File
- Terletak di `.github/workflows/build_ios.yml`.
- Berjalan di runner `macos-latest`.
- Menggunakan Flutter SDK stable, CocoaPods, dan command:
  ```bash
  flutter build ios --release --no-codesign
  ```
- Mengemas output `Runner.app` ke dalam struktur `Payload/Runner.app` lalu men-zip menjadi file `.ipa` yang kompatibel untuk sideloading (3uTools, AltStore, TrollStore).
- Mengunggah artifact build dengan nama: `RWC-Media-Production-iOS-IPA`.

### B. Output File IPA
- `c:\Users\dhavi\antigravity\SFRD_IOS\build_output\RWC-Media-Production.ipa`
- `c:\Users\dhavi\antigravity\SFRD\SFRD_IOS\build_output\RWC-Media-Production.ipa`

---

## 3. Prosedur Sideloading & Signing (3uTools)

1. Buka **3uTools** di PC Windows.
2. Masuk ke **Toolbox** > **IPA Signature** > **Add IPA**.
3. Pilih `C:\Users\dhavi\antigravity\SFRD_IOS\build_output\RWC-Media-Production.ipa`.
4. Pilih **Sign with Apple ID** > klik **Start Signing** sampai status **Signature Succeeded**.
5. Sambungkan iPhone via kabel lightning/USB-C.
6. Buka menu **iDevice** > **Apps** > klik **Install IPA**.
7. Pilih file hasil signed dari 3uTools dan tunggu hingga 100%.
8. **Trust Developer Certificate**:
   - Di iPhone: Buka **Settings** > **General** > **VPN & Device Management** > Pilih Apple ID > tap **Trust**.
   - Jika ada notifikasi "Developer Mode Required": Buka **Settings** > **Privacy & Security** > scroll ke bawah > aktifkan **Developer Mode** > Restart iPhone.
