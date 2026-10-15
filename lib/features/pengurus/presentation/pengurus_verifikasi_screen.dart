import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import 'verifikasi_klinik_detail_screen.dart';
import 'validasi_pembayaran_screen.dart';

class PengurusVerifikasiScreen extends StatefulWidget {
  const PengurusVerifikasiScreen({super.key});

  @override
  State<PengurusVerifikasiScreen> createState() => _PengurusVerifikasiScreenState();
}

class _PengurusVerifikasiScreenState extends State<PengurusVerifikasiScreen> {
  final _apiClient = ApiClient();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  String _userRole = 'Admin Cabang';
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _anggotaList = [];
  String _selectedStatusFilter = ''; // Kosong = Semua

  final List<Map<String, String>> _statusFilters = const [
    {'label': 'Semua', 'value': ''},
    {'label': 'Menunggu Cabang', 'value': 'waiting'},
    {'label': 'Diverifikasi Cabang', 'value': 'Diverifikasi Cabang'},
    {'label': 'Verifikasi Sekjen', 'value': 'Verifikasi Sekjen'},
    {'label': 'Perlu Perbaikan', 'value': 'Perlu Perbaikan'},
    {'label': 'Disetujui (Approved)', 'value': 'approved'},
  ];

  @override
  void initState() {
    super.initState();
    _initRoleAndData();
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
    ]);
    if (mounted) setState(() => _isLoading = false);
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
      final queryParams = <String, dynamic>{};
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
        setState(() {
          _anggotaList = res.data['data'] as List<dynamic>;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scope = _dashboardData?['scope'] ?? {};
    final kpi = _dashboardData?['kpi_stats'] ?? {};
    final scopeTitle = scope['title'] ?? 'Pengurus ASKLIN';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        color: AppColors.primaryRed,
        onRefresh: _loadAllData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Sliver Header Mewah
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: AppColors.primaryRed,
              actions: [
                IconButton(
                  icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                  tooltip: 'Validasi Iuran Bendahara',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ValidasiPembayaranScreen()),
                    );
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                title: Text(
                  scopeTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryRed, AppColors.primaryDarkRed],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_user, color: Colors.white, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    _userRole.toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pusat Verifikasi Keanggotaan Faskes',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Konten Utama
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KPI Ringkasan
                    Row(
                      children: [
                        _buildKpiCard(
                          label: 'Menunggu',
                          value: (kpi['menunggu_verifikasi'] ?? 0).toString(),
                          icon: Icons.hourglass_top,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 10),
                        _buildKpiCard(
                          label: 'Perbaikan',
                          value: (kpi['perlu_perbaikan'] ?? 0).toString(),
                          icon: Icons.edit_note,
                          color: Colors.amber.shade800,
                        ),
                        const SizedBox(width: 10),
                        _buildKpiCard(
                          label: 'Disetujui',
                          value: (kpi['disetujui'] ?? 0).toString(),
                          icon: Icons.check_circle_outline,
                          color: AppColors.statusGreen,
                        ),
                        const SizedBox(width: 10),
                        _buildKpiCard(
                          label: 'Total',
                          value: (kpi['total_anggota'] ?? 0).toString(),
                          icon: Icons.local_hospital_outlined,
                          color: Colors.blue.shade700,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Shortcut Validasi Iuran Bendahara
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ValidasiPembayaranScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryRed, AppColors.primaryDarkRed],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryRed.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Validasi Iuran Anggota (Bendahara)',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Periksa bukti transfer klinik, setujui status lunas & tolak',
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

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
                    const SizedBox(height: 12),

                    // Filter Chips Status
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _statusFilters.map((f) {
                          final isSelected = _selectedStatusFilter == f['value'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(f['label']!),
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
                          'Daftar Klinik Anggota',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                        ),
                        Text(
                          '${_anggotaList.length} Faskes',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // List Faskes
            _isLoading
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
                    ),
                  )
                : _anggotaList.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Text(
                              'Tidak ada data faskes yang sesuai filter.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, idx) {
                              final item = _anggotaList[idx];
                              return _buildAnggotaCard(item);
                            },
                            childCount: _anggotaList.length,
                          ),
                        ),
                      ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
            const SizedBox(height: 6),
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
    final tglDaftar = item['tanggal_daftar'] ?? '-';

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
            const SizedBox(height: 14),
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
        ),
      ),
    );
  }
}

