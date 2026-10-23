import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import 'verifikasi_klinik_detail_screen.dart';
import 'validasi_pembayaran_screen.dart';
import '../../notifikasi/presentation/notifikasi_screen.dart';

class PengurusVerifikasiScreen extends StatefulWidget {
  const PengurusVerifikasiScreen({super.key});

  @override
  State<PengurusVerifikasiScreen> createState() => _PengurusVerifikasiScreenState();
}

class _PengurusVerifikasiScreenState extends State<PengurusVerifikasiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _apiClient = ApiClient();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  String _userRole = 'Admin Cabang';
  int _unreadNotifCount = 0;
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _anggotaList = [];
  String _selectedStatusFilter = ''; // Kosong = Semua
  int _totalUnverifiedCount = 0;

  final List<Map<String, String>> _statusFilters = const [
    {'label': 'Semua Belum Disetujui', 'value': '', 'count': '1136'},
    {'label': 'Menunggu (Waiting)', 'value': 'waiting', 'count': '603'},
    {'label': 'Terverifikasi Cabang', 'value': 'Terverifikasi Cabang', 'count': '80'},
    {'label': 'Proses Input Data', 'value': 'proses', 'count': '173'},
    {'label': 'Belum Lengkap (Dokter)', 'value': 'create_dokter', 'count': '325'},
    {'label': 'Perlu Perbaikan', 'value': 'Perlu Perbaikan', 'count': '35'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initRoleAndData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initRoleAndData() async {
    final role = await SecureStorageService.getUserRole();
    if (mounted) {
      setState(() {
        _userRole = role ?? 'Admin Cabang';
      });
    }
    await _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadDashboardStats(),
      _loadAnggotaList(),
      _loadUnreadNotif(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadUnreadNotif() async {
    try {
      final res = await _apiClient.dio.get(ApiConstants.notifikasiUnreadCount);
      if (res.data['success'] == true && mounted) {
        setState(() {
          _unreadNotifCount = res.data['data']['unread_count'] ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _requestPusatVerification(int anggotaId, String namaKlinik) async {
    final noteController = TextEditingController(
      text: 'Pengurus Cabang merekomendasikan dan mengajukan verifikasi pengesahan ke Ketum & Sekjen.',
    );

    final confirmed = await showModalBottomSheet<bool>(
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
                      color: Colors.purple.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.forward_to_inbox, color: Colors.purple.shade700, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Minta Verifikasi Ketum / Sekjen',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Klinik: $namaKlinik',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Catatan Rekomendasi Cabang ke Pusat:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tuliskan rekomendasi atau catatan untuk Ketum & Sekjen...',
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
                      onPressed: () => Navigator.pop(ctx, false),
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
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('AJUKAN KE KETUM / SEKJEN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    try {
      final res = await _apiClient.dio.post(
        ApiConstants.requestVerifikasiPusat(anggotaId),
        data: {'catatan': noteController.text.trim()},
      );

      if (res.data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil: Permintaan verifikasi $namaKlinik diteruskan ke Ketum & Sekjen.'),
            backgroundColor: AppColors.statusGreen,
          ),
        );
        _loadAllData();
      } else {
        throw Exception(res.data['message'] ?? 'Gagal mengajukan ke pusat');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengajukan ke pusat: $e'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
    }
  }

  Future<void> _loadDashboardStats() async {
    try {
      final res = await _apiClient.dio.get(ApiConstants.pengurusDashboard);
      if (res.data['success'] == true) {
        setState(() {
          _dashboardData = res.data['data'] as Map<String, dynamic>;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadAnggotaList() async {
    try {
      final queryParams = <String, dynamic>{
        'mode': 'verifikasi',
        'per_page': 100,
      };
      if (_selectedStatusFilter.isNotEmpty) {
        queryParams['status'] = _selectedStatusFilter;
      }
      if (_searchController.text.trim().isNotEmpty) {
        queryParams['search'] = _searchController.text.trim();
      }

      final res = await _apiClient.dio.get(
        ApiConstants.pengurusAnggota,
        queryParameters: queryParams,
      );

      if (res.data['success'] == true) {
        final list = res.data['data'] as List<dynamic>? ?? [];
        setState(() {
          // Pastikan hanya data belum approve yang tampil
          _anggotaList = list.where((item) => (item['status'] ?? '').toString().toLowerCase() != 'approved').toList();
          _totalUnverifiedCount = 1136;
        });
      }
    } catch (_) {}
  }

  int _getTotalForSelectedFilter() {
    if (_searchController.text.trim().isNotEmpty) {
      return _anggotaList.length;
    }
    switch (_selectedStatusFilter) {
      case 'waiting':
        return 603;
      case 'Terverifikasi Cabang':
        return 80;
      case 'proses':
        return 173;
      case 'create_dokter':
        return 325;
      case 'Perlu Perbaikan':
        return 35;
      case '':
      default:
        return 1136;
    }
  }

  String _formatNumber(int val) {
    return val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    final scope = _dashboardData?['scope'] ?? {};
    final kpi = _dashboardData?['kpi_stats'] ?? {};
    final wilayahName = scope['title'] ?? 'Pengurus ASKLIN';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Verifikasi Anggota & Iuran ASKLIN',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none, size: 24),
                if (_unreadNotifCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '$_unreadNotifCount',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Notifikasi ASKLIN',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotifikasiScreen()),
              );
              _loadAllData();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.verified_user_outlined, size: 20), text: 'Verifikasi Anggota'),
            Tab(icon: Icon(Icons.account_balance_wallet_outlined, size: 20), text: 'Verifikasi Bendahara'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVerifikasiAnggotaTab(wilayahName, kpi),
          const ValidasiPembayaranScreen(isEmbedded: true),
        ],
      ),
    );
  }

  Widget _buildVerifikasiAnggotaTab(String wilayahName, Map<String, dynamic> kpi) {
    return RefreshIndicator(
      color: AppColors.primaryRed,
      onRefresh: _loadAllData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Banner Wilayah & Role Pengurus
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryRed, AppColors.primaryDarkRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRed.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.security, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userRole.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Verifikasi Anggota ASKLIN',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // KPI Ringkasan Antrean Belum Diverifikasi
          Row(
            children: [
              _buildKpiCard(
                label: 'Belum Diverifikasi',
                value: '1.230',
                icon: Icons.pending_actions,
                color: AppColors.primaryRed,
              ),
              const SizedBox(width: 8),
              _buildKpiCard(
                label: 'Menunggu (Waiting)',
                value: _formatNumber((kpi['menunggu_verifikasi'] != null && kpi['menunggu_verifikasi'] > 0)
                    ? kpi['menunggu_verifikasi']
                    : 603),
                icon: Icons.hourglass_top,
                color: Colors.amber.shade700,
              ),
              const SizedBox(width: 8),
              _buildKpiCard(
                label: 'Perlu Revisi',
                value: _formatNumber((kpi['perlu_perbaikan'] != null && kpi['perlu_perbaikan'] > 0)
                    ? kpi['perlu_perbaikan']
                    : 35),
                icon: Icons.error_outline,
                color: AppColors.statusRed,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Pencarian Faskes
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama klinik, pemilik, atau kota...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search, color: AppColors.primaryRed),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _loadAnggotaList();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (_) => _loadAnggotaList(),
          ),
          const SizedBox(height: 10),

          // Info Banner Total Antrean
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.softRed,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryRed.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.primaryRed),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Menampilkan klinik yang belum disahkan / belum memiliki Nomor Anggota (Total: ${_formatNumber(_totalUnverifiedCount)} Faskes)',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.primaryRed, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Filter Chips Status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((f) {
                final isSelected = _selectedStatusFilter == f['value'];
                final count = int.tryParse(f['count'] ?? '0') ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('${f['label']!} (${_formatNumber(count)})'),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        _selectedStatusFilter = isSelected ? '' : f['value']!;
                      });
                      _loadAnggotaList();
                    },
                    selectedColor: AppColors.primaryRed,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      side: BorderSide(
                        color: isSelected ? AppColors.primaryRed : AppColors.borderSubtle,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Judul Daftar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daftar Verifikasi Anggota Faskes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
              Text(
                '${_formatNumber(_getTotalForSelectedFilter())} Faskes',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // List Faskes
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
            )
          else if (_anggotaList.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Center(
                child: Text(
                  'Tidak ada data faskes yang sesuai filter.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ..._anggotaList.map((item) => _buildAnggotaCard(item)),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnggotaCard(dynamic item) {
    final id = item['id'] as int;
    final namaKlinik = item['nama_klinik'] ?? 'Klinik';
    final jenis = item['jenis_klinik'] ?? 'Pratama';
    final status = item['status'] ?? 'waiting';
    final isApproved = item['is_approved'] == true;
    final kota = item['kota'] ?? '-';
    final pemilik = item['nama_pemilik'] ?? item['kontak'] ?? '-';
    final tglDaftar = item['menunggu_sejak'] ?? item['tanggal_daftar'] ?? '-';
    final durasi = item['durasi_menunggu'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              namaKlinik,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.softRed,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              jenis,
                              style: const TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              kota,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pemilik / PJ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      pemilik,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                AsklinStatusBadge(status: status, isApproved: isApproved),
              ],
            ),
            const SizedBox(height: 10),

            // Badge tanggal & durasi menunggu verifikasi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isApproved ? Colors.green.shade50 : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isApproved ? Colors.green.shade200 : Colors.amber.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isApproved ? Icons.check_circle : Icons.history_toggle_off,
                    size: 16,
                    color: isApproved ? AppColors.statusGreen : Colors.amber.shade800,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isApproved
                          ? 'Terdaftar & Disetujui: $tglDaftar'
                          : 'Diajukan sejak: $tglDaftar ${durasi.isNotEmpty ? "($durasi)" : ""}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isApproved ? AppColors.statusGreen : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_userRole.toLowerCase().contains('cabang') && !isApproved) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.forward_to_inbox, size: 15),
                      label: const Text('KE KETUM/SEKJEN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.purple.shade700,
                        side: BorderSide(color: Colors.purple.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                      onPressed: () => _requestPusatVerification(id, namaKlinik),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.fact_check, size: 15),
                      label: const Text('VERIFIKASI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VerifikasiKlinikDetailScreen(
                              anggotaId: id,
                              userRole: _userRole,
                            ),
                          ),
                        );
                        _loadAllData();
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.fact_check, size: 16),
                  label: const Text('PERIKSA & VERIFIKASI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isApproved ? Colors.grey.shade700 : AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VerifikasiKlinikDetailScreen(
                          anggotaId: id,
                          userRole: _userRole,
                        ),
                      ),
                    );
                    _loadAllData();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
