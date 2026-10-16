import 'package:flutter/material.dart';
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
      final token = await SecureStorageService.getToken();
      final url = '${ApiConstants.baseUrl}$endpoint';
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Membuka unduhan dokumen resmi $title...'),
            backgroundColor: AppColors.statusGreen,
          ),
        );
      }
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
    final namaKlinik = klinik['nama_klinik'] ?? 'Klinik Anggota ASKLIN';
    final noAnggota = klinik['no_anggota'] ?? 'Menunggu Pengesahan';
    final pemilik = klinik['nama_pemilik_klinik'] ?? klinik['nama_kontak'] ?? '-';
    final alamat = klinik['alamat_lengkap']?['alamat_klinik'] ?? klinik['alamat_klinik'] ?? '-';
    final kota = klinik['alamat_lengkap']?['kota'] ?? klinik['kota_name'] ?? 'Indonesia';
    final jenis = klinik['jenis_klinik'] ?? 'Klinik Pratama';
    final isSk = docType == 'sk';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
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
              const SizedBox(height: 14),

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
                        isSk ? 'Pratinjau SK Anggota' : 'Pratinjau Sertifikat',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

              // Dokumen Preview Box (Certificate frame design)
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCFDFD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 2), // Gold certificate border
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Kop Surat
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryRed,
                              ),
                              child: const Center(
                                child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'ASOSIASI KLINIK INDONESIA',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryRed, letterSpacing: 0.8),
                                ),
                                Text(
                                  'PENGURUS PUSAT (DPP ASKLIN)',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24, thickness: 1.2, color: Color(0xFFD4AF37)),

                        // Judul Dokumen
                        Text(
                          isSk
                              ? 'SURAT KEPUTUSAN PENGESAHAN KEANGGOTAAN'
                              : 'SERTIFIKAT KEANGGOTAAN RESMI',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary, letterSpacing: 0.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nomor Anggota: $noAnggota',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryRed),
                        ),
                        const SizedBox(height: 14),

                        const Text(
                          'Dengan ini menerangkan bahwa fasilitas pelayanan kesehatan:',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),

                        // Nama Klinik Highlight
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9FB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Column(
                            children: [
                              Text(
                                namaKlinik.toUpperCase(),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                jenis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryRed),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Detail Fields
                        _buildPreviewRow('Penanggung Jawab', pemilik),
                        _buildPreviewRow('Alamat', alamat),
                        _buildPreviewRow('Kab / Kota', kota),
                        _buildPreviewRow('Masa Berlaku', 'Hingga 5 Tahun (Sesuai Ketentuan)'),
                        _buildPreviewRow('Status Legalitas', isApproved ? 'Terdaftar & Sah (Approved)' : 'Menunggu Verifikasi Pusat'),

                        const Divider(height: 20),

                        // Cap Digital & Tanda Tangan
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isApproved ? Icons.verified : Icons.pending,
                                      size: 16,
                                      color: isApproved ? Colors.green : Colors.amber.shade800,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isApproved ? 'TERVERIFIKASI RESMI' : 'DRAFT DOKUMEN',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: isApproved ? Colors.green.shade800 : Colors.amber.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text('Ditandatangani Digital oleh Ketum DPP', style: TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.qr_code_2, size: 36, color: Colors.black87),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Action Buttons
              if (isApproved) ...[
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download, size: 20),
                    label: const Text('UNDUH BERKAS RESMI (PDF)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
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
                const SizedBox(height: 10),
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

  static Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ),
          const Text(': ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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

