class ApiConstants {
  // Ganti IP dengan URL server live atau IP lokal saat dev
  // Contoh: 'http://10.0.2.2:8000/api/v1' untuk Android Emulator
  // Contoh: 'https://asklin.org/api/v1' untuk Production
  static const String baseUrl = 'https://asklin.org/api/v1';
  
  // Kunci Rahasia Otorisasi Akses API Mobile (Testing Staging Key)
  static const String appSecretKey = 'asklin_staging_20102026_secretkey_bc0768671d90666f4c34483f602eae7f1f74391281c6f37b';
  
  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';
  static const String updatePhoto = '/auth/update-photo';
  
  // Anggota Endpoints
  static const String profile = '/anggota/profil';
  static const String statusKeanggotaan = '/anggota/status-keanggotaan';
  static const String dokumenSaya = '/anggota/dokumen-saya';
  static const String downloadSk = '/dokumen/sk-anggota/download';
  static const String downloadSertifikat = '/dokumen/sertifikat/download';
  
  // Public Content
  static const String berita = '/berita';
  static const String agenda = '/agenda';
  static const String organisasi = '/organisasi/struktur';
  
  // Pengurus Monitoring & Verifikasi
  static const String pengurusDashboard = '/pengurus/dashboard';
  static const String pengurusAnggota = '/pengurus/anggota';
  static const String pengurusVerifikasi = '/pengurus/verifikasi';

  // Pembayaran & Iuran Anggota
  static const String pembayaranStatus = '/pembayaran/status';
  static const String pembayaranRiwayat = '/pembayaran/riwayat';
  static const String pembayaranKonfirmasi = '/pembayaran/konfirmasi';
  static const String bendaharaPembayaran = '/bendahara/pembayaran';
}

