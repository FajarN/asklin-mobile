import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

class BeritaScreen extends StatefulWidget {
  const BeritaScreen({Key? key}) : super(key: key);

  @override
  State<BeritaScreen> createState() => _BeritaScreenState();
}

class _BeritaScreenState extends State<BeritaScreen> {
  final _apiClient = ApiClient();
  final _searchController = TextEditingController();

  List<dynamic> _beritaList = [];
  List<dynamic> _kategoriList = [];
  int? _selectedKategoriId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBerita();
  }

  Future<void> _fetchBerita() async {
    setState(() => _isLoading = true);
    try {
      final queryParams = <String, dynamic>{};
      if (_searchController.text.isNotEmpty) {
        queryParams['search'] = _searchController.text;
      }
      if (_selectedKategoriId != null) {
        queryParams['kategori_id'] = _selectedKategoriId;
      }

      final res = await _apiClient.dio.get(
        ApiConstants.berita,
        queryParameters: queryParams,
      );

      setState(() {
        _beritaList = res.data['data'] ?? [];
        _kategoriList = res.data['kategori'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Berita & Artikel Terkini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar & Filter Kategori Horizontal
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
                        label: 'Semua',
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

          // Daftar Berita
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                : _beritaList.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada berita pada kategori ini.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primaryRed,
                        onRefresh: _fetchBerita,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _beritaList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final item = _beritaList[index];
                            return _BeritaCard(item: item);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _BeritaCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _BeritaCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final thumbUrl = item['thumb_url'];
    final kategoriNama = item['kategori']?['nama'] ?? 'ASKLIN';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          // Navigasi ke detail berita
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar Thumbnail
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

              // Teks Berita
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
}
