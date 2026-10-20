import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../data/pemilihan_model.dart';

class PemilihanHasilScreen extends StatefulWidget {
  final int pemilihanId;

  const PemilihanHasilScreen({
    Key? key,
    required this.pemilihanId,
  }) : super(key: key);

  @override
  State<PemilihanHasilScreen> createState() => _PemilihanHasilScreenState();
}

class _PemilihanHasilScreenState extends State<PemilihanHasilScreen> {
  final _apiClient = ApiClient();
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _pemilihan;
  Map<String, dynamic>? _statistik;
  Map<String, dynamic>? _pemenang;
  List<KandidatModel> _kandidatList = [];

  @override
  void initState() {
    super.initState();
    _fetchHasil();
  }

  Future<void> _fetchHasil() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.dio.get(ApiConstants.pemilihanHasil(widget.pemilihanId));
      if (res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>;
        final rawKandidat = (data['kandidat'] as List<dynamic>?) ?? [];

        if (mounted) {
          setState(() {
            _pemilihan = data['pemilihan'];
            _statistik = data['statistik'];
            _pemenang = data['pemenang_terunggul'];
            _kandidatList = rawKandidat.map((k) => KandidatModel.fromJson(k)).toList();
            _isLoading = false;
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _errorMessage = res.data['message'] ?? 'Gagal memuat hasil pemilihan.';
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.response?.data?['message'] ?? 'Gagal menghubungi server.';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Suara Real Count'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _fetchHasil, child: const Text('Coba Lagi')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchHasil,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Election Title Card
                      if (_pemilihan != null) _buildElectionHeader(),
                      const SizedBox(height: 14),

                      // Metrics Grid
                      if (_statistik != null) _buildMetricsGrid(),
                      const SizedBox(height: 14),

                      // Leading Candidate Banner
                      if (_pemenang != null) _buildLeadingBanner(),
                      const SizedBox(height: 18),

                      // Per-Candidate Real Count Breakdown
                      const Text(
                        'Rekapitulasi Suara Per Calon',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      ..._kandidatList.map((kand) => _buildCandidateResultCard(kand)),
                      const SizedBox(height: 16),

                      // Secret Ballot Confidentiality Notice
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Icon(Icons.security, size: 20, color: Colors.amber),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Asas LUBER JURDIL: Hasil rekapitulasi ditampilkan secara anonim dan transparan tanpa memperlihatkan pilihan masing-masing klinik demi menjaga kerahasiaan suara.',
                                style: TextStyle(fontSize: 11, color: Colors.brown, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildElectionHeader() {
    final p = _pemilihan!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (p['tingkat'] ?? '').toString().toUpperCase(),
                    style: const TextStyle(color: AppColors.primaryRed, fontSize: 10, fontWeight: FontWeight.bold),
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
                    'Periode ${p['periode'] ?? ''}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              p['judul'] ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              p['wilayah'] ?? '',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final s = _statistik!;
    final totalDpt = s['total_dpt'] ?? 0;
    final totalSuara = s['total_suara'] ?? 0;
    final partisipasi = s['persentase_partisipasi'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'DPT SAH',
            value: '$totalDpt',
            subtitle: 'Klinik Approve',
            color: Colors.blue,
            icon: Icons.local_hospital_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: 'SUARA MASUK',
            value: '$totalSuara',
            subtitle: 'Sudah Voting',
            color: Colors.green,
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: 'PARTISIPASI',
            value: '$partisipasi%',
            subtitle: 'Tingkat Hadir',
            color: AppColors.primaryRed,
            icon: Icons.pie_chart_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildLeadingBanner() {
    final lead = _pemenang!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade700, Colors.red.shade900],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CALON TERUNGGUL SEMENTARA',
                  style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  'No. ${lead['nomor_urut']} - ${lead['nama_calon']}',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '${lead['total_suara']} Suara (${lead['persentase']}%)',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateResultCard(KandidatModel kand) {
    final isUnggul = _pemenang != null && _pemenang!['id'] == kand.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isUnggul ? AppColors.primaryRed : Colors.grey.shade200,
          width: isUnggul ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                // Nomor Urut
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isUnggul ? AppColors.primaryRed : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${kand.nomorUrut}',
                    style: TextStyle(
                      color: isUnggul ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Nama & Klinik
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kand.namaLengkap,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (kand.asalKlinik != null && kand.asalKlinik!.isNotEmpty)
                        Text(
                          kand.asalKlinik!,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),

                // Perolehan Suara
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${kand.persentase}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isUnggul ? AppColors.primaryRed : Colors.black87,
                      ),
                    ),
                    Text(
                      '${kand.totalSuara} Suara',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: kand.persentase / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isUnggul ? AppColors.primaryRed : Colors.blueGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
