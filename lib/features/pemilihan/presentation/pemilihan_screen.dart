import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../data/pemilihan_model.dart';
import 'pemilihan_voting_screen.dart';
import 'pemilihan_hasil_screen.dart';

class PemilihanScreen extends StatefulWidget {
  const PemilihanScreen({Key? key}) : super(key: key);

  @override
  State<PemilihanScreen> createState() => _PemilihanScreenState();
}

class _PemilihanScreenState extends State<PemilihanScreen> {
  final _apiClient = ApiClient();
  bool _isLoading = true;
  String? _errorMessage;
  List<PemilihanItemModel> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchPemilihanAktif();
  }

  Future<void> _fetchPemilihanAktif() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.dio.get(ApiConstants.pemilihanAktif);
      if (res.data['success'] == true) {
        final rawList = (res.data['data'] as List<dynamic>?) ?? [];
        if (mounted) {
          setState(() {
            _items = rawList.map((e) => PemilihanItemModel.fromJson(e as Map<String, dynamic>)).toList();
            _isLoading = false;
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _errorMessage = res.data['message'] ?? 'Gagal memuat agenda pemilihan.';
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.response?.data?['message'] ?? 'Gagal terhubung ke server ASKLIN.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pemilihan Ketua ASKLIN'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _fetchPemilihanAktif, child: const Text('Coba Lagi')),
                      ],
                    ),
                  ),
                )
              : _items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.how_to_vote_outlined, size: 48, color: AppColors.primaryRed),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum Ada Agenda Pemilihan',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Saat ini belum ada agenda musyawarah atau pemilihan ketua yang aktif untuk wilayah klinik Anda.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              onPressed: _fetchPemilihanAktif,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Segarkan'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchPemilihanAktif,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Info Banner
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.primaryRed.withOpacity(0.2)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Icon(Icons.how_to_vote, color: AppColors.primaryRed, size: 22),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sistem Pemilihan Ketua (5 Tahunan)',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryRed),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Setiap klinik sah (status Approved) memiliki hak 1 suara. Pilihan bersifat permanen (One-time Vote) dan dijamin rahasia (LUBER JURDIL).',
                                        style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.3),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Election Items
                          ..._items.map((item) => _buildPemilihanCard(item, dateFormat)),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildPemilihanCard(PemilihanItemModel item, DateFormat dateFormat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badges
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.tingkat.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Periode ${item.periode}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                const Spacer(),
                _buildStatusBadge(item.status),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              item.judul,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

            // Region
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.wilayah,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Timeline
            if (item.tanggalMulai != null && item.tanggalSelesai != null)
              Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${dateFormat.format(item.tanggalMulai!)} s/d ${dateFormat.format(item.tanggalSelesai!)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            const Divider(height: 20),

            // Hak Suara Indicator
            _buildHakSuaraIndicator(item, dateFormat),
            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PemilihanHasilScreen(pemilihanId: item.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.pie_chart_outline, size: 16),
                    label: const Text('Hasil Suara', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.hasVoted
                          ? Colors.grey.shade400
                          : !item.isEligible
                              ? Colors.grey.shade300
                              : AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PemilihanVotingScreen(pemilihanId: item.id),
                        ),
                      ).then((_) => _fetchPemilihanAktif());
                    },
                    icon: Icon(
                      item.hasVoted
                          ? Icons.check
                          : !item.isEligible
                              ? Icons.lock
                              : Icons.how_to_vote,
                      size: 16,
                    ),
                    label: Text(
                      item.hasVoted
                          ? 'Sudah Memilih'
                          : !item.isEligible
                              ? 'Hak Terkunci'
                              : 'Buka Surat Suara',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey.shade200;
    Color fg = Colors.grey.shade800;

    if (status == 'aktif') {
      bg = Colors.green.shade100;
      fg = Colors.green.shade800;
    } else if (status == 'selesai') {
      bg = Colors.blue.shade100;
      fg = Colors.blue.shade800;
    } else if (status == 'ditutup') {
      bg = Colors.rose.shade100;
      fg = Colors.rose.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHakSuaraIndicator(PemilihanItemModel item, DateFormat dateFormat) {
    if (item.hasVoted) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, size: 18, color: AppColors.statusGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.waktuVote != null
                    ? 'Klinik telah memberikan suara pada ${dateFormat.format(item.waktuVote!)} WIB (Permanen).'
                    : 'Klinik Anda telah memberikan suara pada pemilihan ini.',
                style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    if (!item.isEligible) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, size: 18, color: AppColors.primaryRed),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.eligibilityMessage,
                style: const TextStyle(fontSize: 11, color: AppColors.primaryRed, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: const [
          Icon(Icons.how_to_vote, size: 18, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hak suara aktif: Klinik berhak memilih 1 calon ketua cabang/daerah.',
              style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
