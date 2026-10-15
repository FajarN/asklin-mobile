import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

class VerifikasiKlinikDetailScreen extends StatefulWidget {
  final int anggotaId;
  final String userRole; // 'Admin Cabang', 'Sekjen', 'Ketua Umum', 'Superadmin', dll

  const VerifikasiKlinikDetailScreen({
    super.key,
    required this.anggotaId,
    required this.userRole,
  });

  @override
  State<VerifikasiKlinikDetailScreen> createState() => _VerifikasiKlinikDetailScreenState();
}

class _VerifikasiKlinikDetailScreenState extends State<VerifikasiKlinikDetailScreen> with SingleTickerProviderStateMixin {
  final _apiClient = ApiClient();
  late TabController _tabController;

  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get('${ApiConstants.pengurusAnggota}/${widget.anggotaId}');
      if (res.data['success'] == true) {
        setState(() {
          _detail = res.data['data'] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _launchUrlHelper(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  bool get _isCabang => widget.userRole.toLowerCase().contains('cabang');
  bool get _isPusat => widget.userRole.toLowerCase().contains('sekjen') ||
      widget.userRole.toLowerCase().contains('ketua') ||
      widget.userRole.toLowerCase().contains('superadmin') ||
      widget.userRole.toLowerCase().contains('pusat');

  void _showActionDialog({
    required String title,
    required String targetStatus,
    required Color buttonColor,
    required IconData icon,
    bool isDanger = false,
  }) {
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: buttonColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: buttonColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Ubah status menjadi: $targetStatus',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Catatan Verifikator (Opsional/Wajib untuk perbaikan):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tuliskan catatan perbaikan berkas, kelengkapan SIP/STR, atau pesan pengesahan...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(icon, size: 18),
                      label: Text(
                        _isSubmitting ? 'Memproses...' : 'SIMPAN KEPUTUSAN',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await _submitVerifikasi(targetStatus, noteController.text.trim());
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitVerifikasi(String status, String keterangan) async {
    setState(() => _isSubmitting = true);
    try {
      final res = await _apiClient.dio.post(
        '${ApiConstants.pengurusVerifikasi}/${widget.anggotaId}',
        data: {
          'status': status,
          'keterangan': keterangan,
        },
      );

      if (res.data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil: Status klinik diperbarui menjadi "$status".'),
            backgroundColor: AppColors.statusGreen,
          ),
        );
        _loadDetail();
      } else {
        throw Exception(res.data['message'] ?? 'Gagal memproses verifikasi');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan verifikasi. Pastikan Anda memiliki wewenang wilayah klinik ini.'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detail Verifikasi Faskes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          backgroundColor: AppColors.primaryRed,
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
      );
    }

    final d = _detail ?? {};
    final namaKlinik = d['nama_klinik'] ?? 'Klinik';
    final noAnggota = d['no_anggota'] ?? '-';
    final status = d['status'] ?? 'waiting';
    final isApproved = status.toString().toLowerCase() == 'approved';
    final jenis = d['jenis_klinik'] ?? 'Pratama';
    final alamat = d['alamat_lengkap'] ?? {};
    final kontak = d['kontak'] ?? {};
    final perijinan = d['perijinan'] ?? {};
    final sdmList = (d['sdm_list'] as List<dynamic>?) ?? [];
    final verifikasi = d['verifikasi'] ?? {};
    final catatan = d['keterangan'] ?? '-';

    final tlf = kontak['tlf_klinik'] ?? kontak['tlf'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Verifikasi Data Klinik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Profil & Izin'),
            Tab(text: 'SDM Dokter'),
            Tab(text: 'Status Verifikasi'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Banner Singkat Faskes
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.softRed,
                  child: const Icon(Icons.local_hospital, color: AppColors.primaryRed, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              namaKlinik,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.softRed,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              jenis,
                              style: const TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No. Anggota: $noAnggota',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 6),
                      AsklinStatusBadge(status: status, isApproved: isApproved),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Konten Tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Profil & Legalitas
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSectionCard(
                        title: 'Legalitas & Perizinan',
                        icon: Icons.gavel_outlined,
                        children: [
                          _buildDetailRow('Nomor Izin Operasional (SIO)', perijinan['no_ijin'] ?? '-'),
                          _buildDetailRow('Tanggal Izin Berlaku', perijinan['tgl_ijin'] ?? '-'),
                          _buildDetailRow('Masa Berlaku SIO Hingga', perijinan['tgl_akhir_ijin'] ?? '-'),
                          _buildDetailRow('Bentuk Badan Hukum', d['bentuk_badan_hukum'] ?? '-'),
                          _buildDetailRow('Status Kepemilikan', d['status_kepemilikan'] ?? '-'),
                          _buildDetailRow('Nama Pemilik Klinik', d['nama_pemilik_klinik'] ?? '-'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildSectionCard(
                        title: 'Alamat Faskes Terdaftar',
                        icon: Icons.location_on_outlined,
                        children: [
                          _buildDetailRow('Alamat Lengkap', alamat['alamat_klinik']?.toString().replaceAll('<br>', '\n') ?? '-'),
                          _buildDetailRow('RT / RW', '${alamat['rt'] ?? '-'} / ${alamat['rw'] ?? '-'}'),
                          _buildDetailRow('Kecamatan', alamat['kecamatan'] ?? '-'),
                          _buildDetailRow('Kabupaten / Kota', alamat['kota'] ?? '-'),
                          _buildDetailRow('Provinsi', alamat['provinsi'] ?? '-'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildSectionCard(
                        title: 'Kontak Penanggung Jawab',
                        icon: Icons.contact_phone_outlined,
                        children: [
                          _buildDetailRow('Nama Kontak PJ', kontak['nama_kontak'] ?? '-'),
                          _buildDetailRow('Telepon Klinik', tlf.isEmpty ? '-' : tlf),
                          _buildDetailRow('Alamat Email', kontak['email'] ?? '-'),
                          if (tlf.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.phone, size: 16),
                                    label: const Text('Hubungi PJ'),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed, foregroundColor: Colors.white),
                                    onPressed: () => _launchUrlHelper('tel:$tlf'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.chat, size: 16),
                                    label: const Text('WhatsApp'),
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                                    onPressed: () => _launchUrlHelper('https://wa.me/$tlf'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // TAB 2: SDM & Tenaga Medis
                sdmList.isEmpty
                    ? const Center(
                        child: Text('Belum ada data dokter / tenaga medis diinput.', style: TextStyle(color: AppColors.textSecondary)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: sdmList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, idx) {
                          final sdm = sdmList[idx];
                          final isPj = sdm['id_kategori_sdm'] == '1' || sdm['peranan']?.toString().toLowerCase().contains('penanggung') == true;

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isPj ? AppColors.softRed : Colors.blue.shade50,
                                        child: Icon(Icons.medical_services, color: isPj ? AppColors.primaryRed : Colors.blue, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sdm['nama_dokter'] ?? sdm['nama'] ?? 'Dokter',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            Text(
                                              isPj ? 'Dokter Penanggung Jawab (PJ)' : 'Dokter Pendamping / Pelaksana',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isPj ? AppColors.primaryRed : AppColors.textSecondary,
                                                fontWeight: isPj ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  _buildDetailRow('Nomor STR', sdm['no_str'] ?? '-'),
                                  _buildDetailRow('Nomor SIP', sdm['no_sip'] ?? '-'),
                                  _buildDetailRow('Masa Berlaku SIP', sdm['tgl_akhir_sip'] ?? '-'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                // TAB 3: Riwayat & Verifikasi
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSectionCard(
                        title: 'Jejak Audit Verifikasi',
                        icon: Icons.history,
                        children: [
                          _buildDetailRow('Verifikasi Cabang', verifikasi['verifikasi_cabang'] ?? 'Belum diverifikasi'),
                          _buildDetailRow('Verifikasi Pusat', verifikasi['verifikasi_pusat'] ?? 'Belum disahkan pusat'),
                          _buildDetailRow('Catatan Saat Ini', catatan),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Verification Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -3)),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isCabang) ...[
                    // Aksi untuk Pengurus Cabang
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: const Text('VERIFIKASI CABANG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            onPressed: () => _showActionDialog(
                              title: 'Verifikasi & Teruskan ke Sekjen Pusat',
                              targetStatus: 'Verifikasi Sekjen',
                              buttonColor: AppColors.statusGreen,
                              icon: Icons.check_circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.edit_note, size: 18),
                            label: const Text('MINTA PERBAIKAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            onPressed: () => _showActionDialog(
                              title: 'Kembalikan untuk Perbaikan Berkas',
                              targetStatus: 'Perlu Perbaikan',
                              buttonColor: Colors.orange.shade700,
                              icon: Icons.edit_note,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (_isPusat) ...[
                    // Aksi untuk Pengurus Pusat (Sekjen, Ketum, Superadmin)
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.verified, size: 18),
                            label: const Text('SETUJUI & TERBITKAN NO. ANGGOTA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            onPressed: () => _showActionDialog(
                              title: 'Pengesahan Anggota Resmi ASKLIN',
                              targetStatus: 'approved',
                              buttonColor: AppColors.statusGreen,
                              icon: Icons.verified,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.reply, size: 18),
                            label: const Text('PERBAIKAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            onPressed: () => _showActionDialog(
                              title: 'Kembalikan untuk Perbaikan Dokumen',
                              targetStatus: 'Perlu Perbaikan',
                              buttonColor: Colors.orange.shade700,
                              icon: Icons.reply,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primaryRed),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

