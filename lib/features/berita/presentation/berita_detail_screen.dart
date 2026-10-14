import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/theme/app_theme.dart';

class BeritaDetailScreen extends StatefulWidget {
  final String slug;
  final String judul;

  const BeritaDetailScreen({
    Key? key,
    required this.slug,
    required this.judul,
  }) : super(key: key);

  @override
  State<BeritaDetailScreen> createState() => _BeritaDetailScreenState();
}

class _BeritaDetailScreenState extends State<BeritaDetailScreen> {
  final _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final res = await _apiClient.dio.get('${ApiConstants.berita}/${widget.slug}');
      setState(() {
        _detail = res.data['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detail Berita', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
          : _detail == null
              ? const Center(child: Text('Gagal memuat artikel.'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gambar Thumbnail Header
                      if (_detail!['thumb_url'] != null)
                        Image.network(
                          _detail!['thumb_url'],
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 200,
                            color: AppColors.softRed,
                            child: const Icon(Icons.newspaper, size: 60, color: AppColors.primaryRed),
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kategori & Tanggal
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.softRed,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _detail!['kategori']?['nama'] ?? 'ASKLIN',
                                    style: const TextStyle(
                                      color: AppColors.primaryRed,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      _detail!['tanggal'] ?? '',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Judul Berita
                            Text(
                              _detail!['judul'] ?? widget.judul,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                            const Divider(height: 30),

                            // Konten Teks Bersih
                            Text(
                              _detail!['konten_bersih'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.7,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
