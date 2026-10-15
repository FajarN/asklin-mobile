import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../berita/presentation/berita_detail_screen.dart';
import '../../agenda/presentation/agenda_detail_screen.dart';

class InformasiScreen extends StatefulWidget {
  final int initialIndex;
  const InformasiScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<InformasiScreen> createState() => _InformasiScreenState();
}

class _InformasiScreenState extends State<InformasiScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _apiClient = ApiClient();

  // State Berita
  final _searchController = TextEditingController();
  List<dynamic> _beritaList = [];
  List<dynamic> _kategoriList = [];
  int? _selectedKategoriId;
  bool _isLoadingBerita = true;

  // State Agenda / Event
  List<dynamic> _agendaList = [];
  bool _isLoadingAgenda = true;
  String _currentAgendaTab = 'upcoming'; // 'upcoming' vs 'past'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
    _fetchBerita();
    _fetchAgenda();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBerita() async {
    setState(() => _isLoadingBerita = true);
    try {
      final queryParams = <String, dynamic>{};
      if (_searchController.text.trim().isNotEmpty) {
        queryParams['search'] = _searchController.text.trim();
      }
      if (_selectedKategoriId != null) {
        queryParams['kategori_id'] = _selectedKategoriId;
      }

      final res = await _apiClient.dio.get(
        ApiConstants.berita,
        queryParameters: queryParams,
      );

      if (mounted) {
        setState(() {
          _beritaList = res.data['data'] ?? [];
          _kategoriList = res.data['kategori'] ?? [];
          _isLoadingBerita = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBerita = false);
    }
  }

  Future<void> _fetchAgenda() async {
    setState(() => _isLoadingAgenda = true);
    try {
      final res = await _apiClient.dio.get(
        ApiConstants.agenda,
        queryParameters: {'tab': _currentAgendaTab},
      );
      if (mounted) {
        setState(() {
          _agendaList = res.data['data'] ?? [];
          _isLoadingAgenda = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAgenda = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Informasi & Kegiatan ASKLIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: const [
            Tab(icon: Icon(Icons.newspaper, size: 20), text: 'Berita & Artikel'),
            Tab(icon: Icon(Icons.event, size: 20), text: 'Event & Agenda'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBeritaTab(),
          _buildAgendaTab(),
        ],
      ),
    );
  }

  Widget _buildBeritaTab() {
    return Column(
      children: [
        // Search & Filter Kategori
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onSubmitted: (_) => _fetchBerita(),
                decoration: InputDecoration(
                  hintText: 'Cari berita, regulasi, akreditasi...',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _fetchBerita();
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    AsklinCategoryChip(
                      label: 'Semua Kategori',
                      isSelected: _selectedKategoriId == null,
                      onTap: () {
                        setState(() => _selectedKategoriId = null);
                        _fetchBerita();
                      },
                    ),
                    const SizedBox(width: 8),
                    ..._kategoriList.map((kat) {
                      final isSel = _selectedKategoriId == kat['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AsklinCategoryChip(
                          label: kat['nama'],
                          isSelected: isSel,
                          onTap: () {
                            setState(() => _selectedKategoriId = kat['id']);
                            _fetchBerita();
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List Berita
        Expanded(
          child: _isLoadingBerita
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
              : _beritaList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.newspaper_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada berita pada kategori ini.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryRed,
                      onRefresh: _fetchBerita,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _beritaList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _beritaList[index];
                          return _buildBeritaCard(item);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildBeritaCard(Map<String, dynamic> item) {
    final thumbUrl = item['thumb_url'];
    final kategoriNama = item['kategori']?['nama'] ?? 'ASKLIN';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BeritaDetailScreen(
                slug: item['slug'] ?? '',
                judul: item['judul'] ?? '',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  width: 90,
                  height: 90,
                  color: AppColors.softRed,
                  child: thumbUrl != null
                      ? Image.network(
                          thumbUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.newspaper, color: AppColors.primaryRed),
                        )
                      : const Icon(Icons.newspaper, color: AppColors.primaryRed, size: 36),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.softRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        kategoriNama,
                        style: const TextStyle(
                          color: AppColors.primaryRed,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['judul'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          item['tanggal'] ?? '',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgendaTab() {
    return Column(
      children: [
        // Filter Subtab Event: Mendatang vs Riwayat
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: AsklinCategoryChip(
                  label: 'Kegiatan Mendatang',
                  isSelected: _currentAgendaTab == 'upcoming',
                  onTap: () {
                    setState(() => _currentAgendaTab = 'upcoming');
                    _fetchAgenda();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AsklinCategoryChip(
                  label: 'Riwayat Kegiatan',
                  isSelected: _currentAgendaTab == 'past',
                  onTap: () {
                    setState(() => _currentAgendaTab = 'past');
                    _fetchAgenda();
                  },
                ),
              ),
            ],
          ),
        ),

        // List Agenda / Event
        Expanded(
          child: _isLoadingAgenda
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
              : _agendaList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _currentAgendaTab == 'upcoming'
                                ? 'Tidak ada agenda kegiatan mendatang saat ini.'
                                : 'Belum ada arsip kegiatan lampau.',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryRed,
                      onRefresh: _fetchAgenda,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _agendaList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final item = _agendaList[index];
                          return _buildAgendaCard(item);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildAgendaCard(Map<String, dynamic> item) {
    final statusPill = item['status_pill'] ?? 'Pendaftaran Buka';
    final isUpcoming = statusPill == 'Pendaftaran Buka' || statusPill == 'Sedang Berlangsung';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUpcoming ? AppColors.statusGreenBg : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    statusPill,
                    style: TextStyle(
                      color: isUpcoming ? AppColors.statusGreen : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  item['lokasi'] ?? 'ASKLIN Pusat',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item['judul'] ?? '',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item['excerpt'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.event, size: 16, color: AppColors.primaryRed),
                const SizedBox(width: 6),
                Text(
                  item['tanggal_formatted'] ?? 'Tanggal Pelaksanaan',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AgendaDetailScreen(item: item),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: const Size(60, 32),
                  ),
                  child: const Text('Detail', style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
