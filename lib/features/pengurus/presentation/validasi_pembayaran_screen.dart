import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

class ValidasiPembayaranScreen extends StatefulWidget {
  final bool isEmbedded;
  const ValidasiPembayaranScreen({Key? key, this.isEmbedded = false}) : super(key: key);

  @override
  State<ValidasiPembayaranScreen> createState() => _ValidasiPembayaranScreenState();
}

class _ValidasiPembayaranScreenState extends State<ValidasiPembayaranScreen> {
  final _apiClient = ApiClient();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  String _selectedStatus = '0'; // Default: Menunggu Verifikasi
  Map<String, dynamic>? _summaryData;
  List<dynamic> _pembayaranList = [];

  final List<Map<String, String>> _statusFilters = const [
    {'label': 'Menunggu (Pending)', 'value': '0'},
    {'label': 'Lunas / Disetujui', 'value': '1'},
    {'label': 'Ditolak', 'value': '2'},
    {'label': 'Semua Data', 'value': ''},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final queryParams = <String, dynamic>{};
      if (_selectedStatus.isNotEmpty) {
        queryParams['status'] = _selectedStatus;
      }
      if (_searchController.text.trim().isNotEmpty) {
        queryParams['search'] = _searchController.text.trim();
      }

      final res = await _apiClient.dio.get(
        ApiConstants.bendaharaPembayaran,
        queryParameters: queryParams,
      );

      if (res.data['success'] == true) {
        setState(() {
          _summaryData = res.data['summary'] as Map<String, dynamic>?;
          final paginated = res.data['data'] as Map<String, dynamic>?;
          _pembayaranList = (paginated?['data'] as List<dynamic>?) ?? [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat daftar pembayaran: $e'),
          backgroundColor: AppColors.statusRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _prosesVerifikasi({
    required int id,
    required String aksi,
    String? catatan,
  }) async {
    try {
      final res = await _apiClient.dio.post(
        '${ApiConstants.bendaharaPembayaran}/$id/verifikasi',
        data: {
          'aksi': aksi,
          'catatan': catatan,
        },
      );

      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message'] ?? 'Verifikasi berhasil diproses.'),
            backgroundColor: aksi == 'approve' ? AppColors.statusGreen : AppColors.statusRed,
          ),
        );
        _loadData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses verifikasi: $e'),
          backgroundColor: AppColors.statusRed,
        ),
      );
    }
  }

  void _showApproveConfirmDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Setujui Pembayaran?'),
        content: Text(
          'Konfirmasi penerimaan ${item['total_rupiah']} untuk klinik ${item['nama_klinik']}.\n\nStatus klinik akan otomatis diperbarui menjadi LUNAS dan dapat menerbitkan e-Sertifikat.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusGreen),
            onPressed: () {
              Navigator.pop(context);
              _prosesVerifikasi(id: item['id'] as int, aksi: 'approve');
            },
            child: const Text('SETUJUI (LUNAS)', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> item) {
    final catatanController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tolak Pembayaran Iuran',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.statusRed),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Klinik: ${item['nama_klinik']} (${item['total_rupiah']})',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text(
              'Alasan Penolakan / Catatan untuk Klinik:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: catatanController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Contoh: Nominal transfer kurang, struk buram/tidak terbaca, dll.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.cancel, size: 18),
                label: const Text('KIRIM PENOLAKAN', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (catatanController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Harap masukkan alasan penolakan.')),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  _prosesVerifikasi(
                    id: item['id'] as int,
                    aksi: 'reject',
                    catatan: catatanController.text.trim(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageZoom(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Bukti Transfer Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                height: 400,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Gagal menampilkan file gambar bukti.'),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summaryData ?? {};
    final pendingCount = summary['total_pending'] ?? 0;
    final lunasCount = summary['total_lunas'] ?? 0;
    final nominalLunasRupiah = summary['nominal_lunas_rupiah'] ?? 'Rp 0';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // Header
          if (widget.isEmbedded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  _buildKpiPill('Pending: $pendingCount', Colors.amber.shade700),
                  const SizedBox(width: 8),
                  _buildKpiPill('Lunas: $lunasCount', Colors.green.shade700),
                  const Spacer(),
                  Text(
                    nominalLunasRupiah,
                    style: const TextStyle(
                      color: AppColors.primaryRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20, color: AppColors.primaryRed),
                    tooltip: 'Muat Ulang',
                    onPressed: _loadData,
                  ),
                ],
              ),
            )
          else
            AsklinHeaderOrnament(
              height: 180,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Text(
                              'Validasi Pembayaran (Bendahara)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            tooltip: 'Muat Ulang',
                            onPressed: _loadData,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            _buildKpiPill('Pending: $pendingCount', Colors.amber.shade400),
                            const SizedBox(width: 8),
                            _buildKpiPill('Lunas: $lunasCount', Colors.green.shade400),
                            const Spacer(),
                            Text(
                              nominalLunasRupiah,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Search Bar & Filter Chips
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama klinik, nomor anggota...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _loadData();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onSubmitted: (_) => _loadData(),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((f) {
                      final isSelected = _selectedStatus == f['value'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(
                            f['label']!,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primaryRed,
                          backgroundColor: Colors.white,
                          onSelected: (val) {
                            setState(() => _selectedStatus = f['value']!);
                            _loadData();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // List Data
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                : _pembayaranList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey),
                            SizedBox(height: 10),
                            Text('Tidak ada konfirmasi pembayaran sesuai filter.', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppColors.primaryRed,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          itemCount: _pembayaranList.length,
                          itemBuilder: (context, index) {
                            final item = _pembayaranList[index] as Map<String, dynamic>;
                            return _buildPembayaranCard(item);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPembayaranCard(Map<String, dynamic> item) {
    final status = (item['status'] ?? '0').toString();
    final statusLabel = item['status_label'] ?? 'Menunggu';
    final buktiUrl = item['bukti_url'] as String?;

    Color badgeBg = Colors.amber.shade100;
    Color badgeFg = Colors.amber.shade900;
    if (status == '1') {
      badgeBg = Colors.green.shade100;
      badgeFg = Colors.green.shade800;
    } else if (status == '2') {
      badgeBg = Colors.red.shade100;
      badgeFg = Colors.red.shade800;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Klinik & Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['nama_klinik'] ?? 'Klinik ASKLIN',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'No. Anggota: ${item['no_anggota'] ?? '-'} • ${item['lokasi'] ?? ''}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: badgeFg, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Info Pembayaran & Bukti Thumbnail
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['kategori_nama'] ?? 'Iuran Anggota',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['total_rupiah'] ?? 'Rp 0',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryRed,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tgl Bayar: ${item['tanggal_bayar'] ?? '-'}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Bukti Transfer Thumbnail
                if (buktiUrl != null)
                  InkWell(
                    onTap: () => _showImageZoom(buktiUrl),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              buktiUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 28),
                            ),
                            Container(
                              color: Colors.black.withOpacity(0.2),
                              child: const Icon(Icons.zoom_in, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            if (item['keterangan'] != null && item['keterangan'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Catatan: ${item['keterangan']}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ),
            ],

            // Action Buttons untuk Verifikator
            if (status == '0') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.statusRed,
                        side: const BorderSide(color: AppColors.statusRed),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => _showRejectDialog(item),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Validasi (Lunas)', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => _showApproveConfirmDialog(item),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
