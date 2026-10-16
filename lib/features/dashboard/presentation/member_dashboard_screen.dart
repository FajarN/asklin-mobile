import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import 'pendaftaran_anggota_screen.dart';
import '../../pembayaran/presentation/konfirmasi_iuran_screen.dart';

class MemberDashboardScreen extends StatefulWidget {
  const MemberDashboardScreen({Key? key}) : super(key: key);

  @override
  State<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  final _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _statusData;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final resProfile = await _apiClient.dio.get(ApiConstants.profile);
      final resStatus = await _apiClient.dio.get(ApiConstants.statusKeanggotaan);

      setState(() {
        _profileData = resProfile.data['data'];
        _statusData = resStatus.data['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadDocument(String endpoint, String title) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mengunduh berkas resmi $title...'),
            backgroundColor: AppColors.primaryRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Download file bytes directly using ApiClient with Bearer token header
      final response = await _apiClient.dio.get<List<int>>(
        endpoint,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Berkas dokumen kosong atau belum tersedia');
      }

      final dir = await getApplicationDocumentsDirectory();
      final filename = endpoint.contains('sk') ? 'SK_Anggota_ASKLIN.pdf' : 'Sertifikat_Anggota_ASKLIN.pdf';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dokumen $title berhasil diunduh'),
            backgroundColor: AppColors.statusGreen,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Buka',
              textColor: Colors.white,
              onPressed: () => OpenFilex.open(file.path),
            ),
          ),
        );
      }

      // Directly open file using default PDF viewer
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh berkas dokumen: $e'),
            backgroundColor: AppColors.statusRed,
          ),
        );
      }
    }
  }

  void _showDocumentPreviewModal({
    required BuildContext context,
    required String docType, // 'sk' or 'sertifikat'
    required String title,
    required Map<String, dynamic> klinik,
    required bool isApproved,
    required String endpoint,
  }) {
    final isSk = docType == 'sk';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Title bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isApproved ? const Color(0xFFE8F5E9) : AppColors.softRed,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSk ? Icons.assignment : Icons.verified,
                          color: isApproved ? AppColors.statusGreen : AppColors.primaryRed,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isSk ? 'Pratinjau SK Anggota Resmi' : 'Pratinjau Sertifikat Anggota Resmi',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Canvas Dokumen Asli dengan Background Website Resmi (Interactive Zoom & Pan)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: InteractiveViewer(
                        boundaryMargin: const EdgeInsets.all(30),
                        minScale: 0.5,
                        maxScale: 3.5,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: isSk
                                  ? _buildSkPreviewCanvas(klinik, isApproved)
                                  : _buildSertifikatPreviewCanvas(klinik, isApproved),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Petunjuk Zoom
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.zoom_in, size: 16, color: AppColors.textMuted),
                  SizedBox(width: 6),
                  Text(
                    'Cubit (pinch) atau geser layar untuk memperbesar detail dokumen resmi',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action Buttons
              if (isApproved) ...[
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download, size: 20),
                    label: const Text('UNDUH BERKAS RESMI (PDF)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      elevation: 2,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _downloadDocument(endpoint, title);
                    },
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.amber.shade800),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Dokumen PDF resmi baru dapat diunduh setelah status klinik disetujui (Approved) dan iuran diverifikasi lunas.',
                          style: TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('TUTUP PREVIEW', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSertifikatPreviewCanvas(Map<String, dynamic> klinik, bool isApproved) {
    final namaKlinik = klinik['nama_klinik'] ?? 'Klinik Anggota ASKLIN';
    final noAnggota = klinik['no_anggota'] ?? '3216023002-00007.1.2';
    final pj = klinik['nama_kontak'] ?? klinik['nama_pemilik_klinik'] ?? '-';
    final alamat = klinik['alamat_lengkap']?['alamat_klinik'] ?? klinik['alamat_klinik'] ?? '-';
    final kotaCode = klinik['id_kota']?.toString() ?? '3216023002';

    return Container(
      width: 520,
      height: 368,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background resmi asli dari website (public/assets/images/sertifikat.jpg)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/sertifikat.jpg',
              fit: BoxFit.fill,
            ),
          ),

          // Kode Wilayah (Pojok Kiri Atas)
          Positioned(
            left: 42,
            top: 40,
            child: Text(
              'Kode : $kotaCode',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),

          // "Diberikan Kepada :"
          const Positioned(
            left: 0,
            right: 0,
            top: 136,
            child: Text(
              'Diberikan Kepada :',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),

          // Data Klinik
          Positioned(
            left: 46,
            right: 46,
            top: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCertRow('Nama Klinik', namaKlinik, isBold: true),
                const SizedBox(height: 3),
                _buildCertRow('No. Anggota', noAnggota, isBold: true),
                const SizedBox(height: 3),
                _buildCertRow('Penanggung Jawab', pj, isBold: true),
                const SizedBox(height: 3),
                _buildCertRow('Alamat', alamat, isBold: false),
              ],
            ),
          ),

          // Berlaku (Kiri Bawah)
          Positioned(
            left: 42,
            bottom: 24,
            child: Text(
              'Berlaku : ${DateTime.now().year - 2} - ${DateTime.now().year + 3}',
              style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),

          // Pengurus Pusat & TTD (Tengah Bawah)
          Positioned(
            left: 140,
            right: 140,
            bottom: 18,
            child: Column(
              children: [
                const Text(
                  'Pengurus Pusat Asosiasi Klinik Indonesia (ASKLIN)',
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  'Ketua Umum',
                  style: TextStyle(fontSize: 8.5, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Image.asset(
                  'assets/images/ttd.png',
                  height: 34,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 2),
                const Text(
                  'dr. Eddi Junaidi, SpOG.,SH.,MKes',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // QR Code Keabsahan (Kanan Bawah)
          Positioned(
            right: 42,
            bottom: 22,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black12),
              ),
              child: const Icon(Icons.qr_code_2, size: 48, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkPreviewCanvas(Map<String, dynamic> klinik, bool isApproved) {
    final namaKlinik = (klinik['nama_klinik'] ?? 'Klinik Anggota ASKLIN').toString().toUpperCase();
    final noAnggota = klinik['no_anggota'] ?? '3216192003-01463.1.1';
    final jenis = klinik['jenis_klinik'] ?? 'Pratama';
    final kriteria = klinik['kriteria_klinik'] ?? 'Rawat Jalan';
    final rawAlamat = klinik['alamat_lengkap']?['alamat_klinik'] ?? klinik['alamat_klinik'] ?? '-';
    final alamat = rawAlamat.toString()
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ', ')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final rt = klinik['alamat_lengkap']?['rt'] ?? klinik['rt'] ?? '-';
    final rw = klinik['alamat_lengkap']?['rw'] ?? klinik['rw'] ?? '-';
    final kota = klinik['alamat_lengkap']?['kota'] ?? klinik['kota_name'] ?? 'Kabupaten Bekasi';
    final prov = klinik['alamat_lengkap']?['provinsi'] ?? klinik['provinsi_name'] ?? 'Jawa Barat';
    final telp = klinik['tlf_klinik'] ?? klinik['no_telp'] ?? '-';
    final pemilik = klinik['nama_pemilik_klinik'] ?? klinik['nama_kontak'] ?? '-';
    final badanHukum = klinik['bentuk_badan_usaha'] ?? 'Perorangan / Badan Usaha';

    final subNo = noAnggota.contains('-') ? noAnggota.split('-').last : '001';

    return Container(
      width: 480,
      height: 750,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background resmi asli dari website (public/assets/images/skanggota.jpg)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/skanggota.jpg',
              fit: BoxFit.fill,
            ),
          ),

          // Konten SK (Terletak rapi di bawah logo ASKLIN dan di atas bingkai bawah)
          Positioned(
            left: 48,
            right: 48,
            top: 142,
            bottom: 54,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Judul SK
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'SURAT KEPUTUSAN ANGGOTA ASKLIN',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$subNo/SK-Anggota/PP-Asklin/${DateTime.now().year}',
                        style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                const Text(
                  'Dengan ini menyatakan bahwa Pengurus Pusat Asosiasi Klinik Indonesia yang berkedudukan di Jakarta memberikan hak keanggotaan kepada :',
                  style: TextStyle(fontSize: 7.2, color: Colors.black87, height: 1.25),
                ),
                const SizedBox(height: 5),

                // Form 1-9
                _buildSkRow('1. Nama Klinik', namaKlinik),
                _buildSkRow('2. Jenis Klinik', jenis),
                _buildSkRow('3. Kriteria Klinik', kriteria),
                _buildSkRow('4. Alamat', alamat),
                _buildSkRow('5. RT/RW', '$rt / $rw'),
                _buildSkRow('6. Kabupaten/Kota', kota),
                _buildSkRow('7. Propinsi', prov),
                _buildSkRow('8. No.Telp', telp),
                _buildSkRow('9. Pemilik', '$pemilik ($badanHukum)'),
                const SizedBox(height: 5),

                const Text(
                  'Dari hasil verifikasi dan survey lapangan yang dilakukan oleh Pengurus / Staff Asosiasi Klinik Indonesia (ASKLIN) Cabang / Daerah / Pusat maka berhak disyahkan menjadi anggota Asosiasi Klinik Indonesia (ASKLIN) dengan NOMOR ANGGOTA :',
                  style: TextStyle(fontSize: 7.0, color: Colors.black87, height: 1.25),
                ),
                const SizedBox(height: 5),

                // Nomor Anggota Besar di Tengah
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.black26),
                    ),
                    child: Text(
                      noAnggota,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(height: 5),

                // Ketentuan SK
                const Text(
                  '1. Keanggotaan dapat dibekukan apabila :\n'
                  '   a. Tidak mematuhi peraturan dan ketentuan Perundang-undangan Negara RI yang berlaku\n'
                  '   b. Tidak mematuhi peraturan organisasi Asosiasi Klinik Indonesia (ASKLIN)\n'
                  '   c. Alamat dan kepemilikan tidak sesuai dengan yang dicantumkan\n'
                  '   d. Jika klinik tutup sementara atau permanen\n'
                  '2. Keanggotaan dapat dicabut apabila terdaftar di organisasi lain yang sejenis.',
                  style: TextStyle(fontSize: 6.5, color: Colors.black87, height: 1.18),
                ),
                const Spacer(),

                // Tanda Tangan & QR Code Bagian Bawah
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PENGURUS PUSAT ASOSIASI KLINIK INDONESIA\nKETUA UMUM',
                          style: TextStyle(fontSize: 7.2, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 2),
                        Image.asset(
                          'assets/images/ttd.png',
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'dr. Eddi Junaidi, SpOG.,SH.,MKes',
                          style: TextStyle(fontSize: 8.0, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: const Icon(Icons.qr_code_2, size: 44, color: Colors.black87),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildCertRow(String label, String value, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 125,
          child: Text(
            label,
            style: const TextStyle(fontSize: 9.5, color: Colors.black87),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 9.5, color: Colors.black87)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static Widget _buildSkRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 7.3, color: Colors.black87),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 7.3, color: Colors.black87)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 7.3, fontWeight: FontWeight.w600, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
      );
    }

    final klinik = _profileData?['klinik'] ?? _profileData ?? {};
    final user = _profileData?['user'] ?? {};
    final isPengurus = _profileData?['is_pengurus'] == true || user['primary_role'] == 'Superadmin';
    final namaKlinik = klinik['nama_klinik'] ?? user['name'] ?? (isPengurus ? 'Pengurus Pusat ASKLIN' : 'Klinik ASKLIN');
    final noAnggota = klinik['no_anggota'] ?? (isPengurus ? 'Pengurus / Administrator' : 'Menunggu Verifikasi');
    final status = klinik['status'] ?? (isPengurus ? 'approved' : 'Draft');
    final isApproved = status.toString().toLowerCase() == 'approved';
    final isLunas = klinik['status_pembayaran'] == '1' || klinik['is_lunas'] == true || _statusData?['is_lunas'] == true;
    final tglSio = klinik['perijinan']?['tgl_akhir_ijin'] ?? klinik['tgl_akhir_ijin'] ?? (isPengurus ? 'Tetap / Aktif' : 'Hingga 2028');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        color: AppColors.primaryRed,
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
          children: [
            // Header Dasbor dengan Motif Merah Melengkung
            AsklinHeaderOrnament(
              height: 220,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPengurus ? 'Dasbor Pengurus / Admin' : 'Dasbor Keanggotaan',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              namaKlinik,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_none, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AsklinStatusBadge(status: status, isApproved: isApproved),
                  ],
                ),
              ),
            ),

            // Kartu Anggota Digital
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Transform.translate(
                offset: const Offset(0, -35),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isPengurus ? 'IDENTITAS PENGURUS ASKLIN' : 'KARTU ANGGOTA ASKLIN',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryRed,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.softRed,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isPengurus ? 'Administrator' : (klinik['jenis_klinik'] ?? 'Pratama'),
                                style: const TextStyle(
                                  color: AppColors.primaryRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          namaKlinik,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isPengurus ? 'Role: Administrator Sistem' : 'No. Anggota: $noAnggota',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Divider(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isPengurus ? 'Status Jabatan' : 'Masa Berlaku SIO', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                const SizedBox(height: 2),
                                Text(
                                  isPengurus ? 'Pengurus Aktif' : tglSio,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: isPengurus
                                  ? null
                                  : () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const KonfirmasiIuranScreen()),
                                      );
                                      _loadDashboardData();
                                    },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(isPengurus ? 'Hak Akses' : 'Iuran Anggota', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      if (!isPengurus) const Icon(Icons.chevron_right, size: 13, color: AppColors.textMuted),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isPengurus ? 'SUPERADMIN' : (isLunas ? 'LUNAS' : 'MENUNGGU'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: (isPengurus || isLunas) ? AppColors.statusGreen : AppColors.primaryRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Banner Lengkapi Pendaftaran Faskes jika status masih waiting, create_dokter, atau perlu perbaikan
            if (!isApproved && !isPengurus)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.softRed,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.primaryRed.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.assignment_late, color: AppColors.primaryRed, size: 24),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Formulir Pendaftaran Anggota Faskes',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryRed),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Faskes Anda belum menyelesaikan pendaftaran lengkap atau data masih memerlukan perbaikan berkas/SDM.',
                        style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit_note, size: 18),
                          label: const Text('LENGKAPI FORMULIR PENDAFTARAN & SDM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PendaftaranAnggotaScreen(initialData: klinik),
                              ),
                            );
                            if (updated == true) {
                              _loadDashboardData();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Aksi Cepat / Keuangan & Iuran
            if (!isPengurus)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Keuangan & Iuran Anggota',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const KonfirmasiIuranScreen()),
                        );
                        _loadDashboardData();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isLunas ? Colors.green.shade200 : AppColors.primaryRed.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isLunas ? Colors.green.shade50 : AppColors.softRed,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isLunas ? Icons.verified_user : Icons.payment,
                                color: isLunas ? Colors.green : AppColors.primaryRed,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Konfirmasi Iuran Tahunan',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isLunas ? Colors.green.shade100 : Colors.amber.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isLunas ? 'LUNAS' : 'PENDING',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isLunas ? Colors.green.shade800 : Colors.amber.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isLunas
                                        ? 'Status iuran lunas. Lihat mutasi dan riwayat pembayaran.'
                                        : 'Upload struk/bukti transfer bank Mandiri ASKLIN.',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

            // Aksi Cepat / Dokumen Digital
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dokumen & Legalitas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionDocCard(
                          title: 'Unduh SK',
                          subtitle: 'Surat Keputusan',
                          icon: Icons.assignment_outlined,
                          isReady: true,
                          onTap: () {
                            _showDocumentPreviewModal(
                              context: context,
                              docType: 'sk',
                              title: 'Surat Keputusan (SK) Anggota',
                              klinik: klinik,
                              isApproved: isApproved,
                              endpoint: ApiConstants.downloadSk,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionDocCard(
                          title: 'Sertifikat',
                          subtitle: 'Sertifikat Anggota',
                          icon: Icons.verified_outlined,
                          isReady: true,
                          onTap: () {
                            _showDocumentPreviewModal(
                              context: context,
                              docType: 'sertifikat',
                              title: 'Sertifikat Keanggotaan ASKLIN',
                              klinik: klinik,
                              isApproved: isApproved,
                              endpoint: ApiConstants.downloadSertifikat,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Alur Verifikasi Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status Alur Verifikasi',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 14),
                          _TimelineStep(
                            title: 'Pendaftaran Dokumen',
                            subtitle: 'Klinik melengkapi berkas & perizinan',
                            isDone: true,
                          ),
                          _TimelineStep(
                            title: 'Verifikasi Pengurus Cabang',
                            subtitle: 'Pengecekan wilayah kabupaten/kota',
                            isDone: isApproved,
                          ),
                          _TimelineStep(
                            title: 'Penerbitan SK Pengurus Pusat',
                            subtitle: 'Penerbitan nomor anggota dan e-Sertifikat',
                            isDone: isApproved,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}

class _ActionDocCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isReady;
  final VoidCallback onTap;

  const _ActionDocCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isReady,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isReady ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isReady ? AppColors.softRed : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isReady ? AppColors.primaryRed : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              isReady ? subtitle : 'Belum Tersedia',
              style: TextStyle(
                fontSize: 11,
                color: isReady ? AppColors.textSecondary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isLast;

  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.isDone,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isDone ? AppColors.statusGreen : AppColors.textMuted,
              size: 20,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isDone ? AppColors.statusGreen : AppColors.borderSubtle,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDone ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}

