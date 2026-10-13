# ASKLIN Mobile Application (Flutter + Laravel REST API)

Aplikasi mobile resmi untuk **ASKLIN (Asosiasi Klinik Indonesia)** berbasis Flutter & Dart dengan backend Laravel REST API.

---

## 📱 Fitur Utama (Sesuai Referensi Desain UI/UX ASKLIN)

1. **Autentikasi & Registrasi Mandiri:**
   - Multi-peran: Anggota Klinik & Pengurus Organisasi.
   - Pendaftaran akun mandiri klinik secara daring.
   - Penyimpanan sesi aman menggunakan *Flutter Secure Storage*.
2. **Dasbor Keanggotaan Digital:**
   - Kartu Anggota ASKLIN Digital.
   - Status verifikasi keanggotaan real-time (*Draft*, *Menunggu Verifikasi*, *Terverifikasi / Aktif*).
   - Akses instan unduh SK Anggota dan e-Sertifikat resmi.
3. **Berita & Artikel Terkini:**
   - Feed berita dan regulasi kesehatan terbaru ASKLIN.
   - Pencarian instan dan filter chip kategori.
4. **Agenda & Kongres Nasional:**
   - Direktori kegiatan mendatang (*Upcoming*) vs riwayat arsip kegiatan (*Past*).
   - Info lokasi, tanggal, dan status pendaftaran.
5. **Direktori Struktur Organisasi:**
   - Ringkasan statistik nasional: 1 DPP Pusat, 34 DPD Provinsi, 152 DPC Cabang.
   - Susunan dewan pembina, pengurus pusat, dan kontak sekretariat.
6. **Profil & Pengaturan:**
   - Ringkasan data pimpinan dan klinik.
   - Pengaturan keamanan dan tombol keluar akun aman.

---

## 🚀 Cloud Build Otomatis (GitHub Actions)

Proyek ini telah dikonfigurasi dengan alur kerja CI/CD otomatis di `.github/workflows/build-apk.yml`.

Setiap kali Anda melakukan `git push` ke repositori GitHub `origin main`, server cloud GitHub akan secara otomatis:
1. Memasang Java JDK 17 dan Flutter SDK terbaru.
2. Menjalankan dependensi (`flutter pub get`).
3. Mengkompilasi APK rilis Android (`flutter build apk --release`).
4. Menyediakan file `asklin-mobile-release.apk` siap unduh di tab **Actions** repositori GitHub Anda.

---

## 📂 Struktur Direktori Bersih (Clean Architecture)

```text
asklin-mobile/
├── .github/workflows/          # Alur kerja Cloud Build GitHub Actions
├── android/                    # Konfigurasi native Android & manifest izin
├── lib/
│   ├── core/
│   │   ├── network/            # ApiClient (Dio) & ApiConstants
│   │   ├── storage/            # SecureStorageService (Token & Sesi)
│   │   ├── theme/              # AppTheme, Palet Warna ASKLIN (#D32F2F)
│   │   └── widgets/            # Reusable Widgets (Header melengkung, Button, Chips)
│   ├── features/
│   │   ├── auth/               # Login & Registrasi Akun Mandiri
│   │   ├── home/               # Bottom Navigation Bar
│   │   ├── dashboard/          # Dasbor Keanggotaan & Dokumen Digital
│   │   ├── berita/             # Direktori Berita & Filter Kategori
│   │   ├── agenda/             # Kalender Kegiatan & Tab Upcoming/Past
│   │   ├── organisasi/         # Direktori DPP, DPD, DPC Nasional
│   │   └── profile/            # Profil Klinik & Logout
│   └── main.dart               # Entry point aplikasi
└── pubspec.yaml                # Konfigurasi dependensi Flutter
```
