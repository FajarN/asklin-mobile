import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../data/pemilihan_model.dart';
import 'pemilihan_hasil_screen.dart';

class PemilihanVotingScreen extends StatefulWidget {
  final int pemilihanId;

  const PemilihanVotingScreen({
    Key? key,
    required this.pemilihanId,
  }) : super(key: key);

  @override
  State<PemilihanVotingScreen> createState() => _PemilihanVotingScreenState();
}

class _PemilihanVotingScreenState extends State<PemilihanVotingScreen> {
  final _apiClient = ApiClient();
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  PemilihanDetailModel? _detail;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.dio.get(ApiConstants.pemilihanDetail(widget.pemilihanId));
      if (res.data['success'] == true) {
        if (mounted) {
          setState(() {
            _detail = PemilihanDetailModel.fromJson(res.data['data']);
            _isLoading = false;
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _errorMessage = res.data['message'] ?? 'Gagal memuat detail pemilihan.';
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.response?.data?['message'] ?? 'Terjadi kesalahan jaringan.';
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

  void _confirmAndVote(KandidatModel kandidat) {
    if (_detail == null) return;

    if (!_detail!.isEligible) {
      _showWarningDialog(
        title: 'Hak Suara Tidak Aktif',
        message: _detail!.eligibilityMessage,
      );
      return;
    }

    if (_detail!.hasVoted) {
      _showWarningDialog(
        title: 'Sudah Memilih',
        message: 'Klinik Anda sudah tercatat memberikan suara pada agenda pemilihan ini.',
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.how_to_vote, color: AppColors.primaryRed),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Konfirmasi Pilihan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Anda akan memberikan suara untuk calon:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryRed,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${kandidat.nomorUrut}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kandidat.namaLengkap,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (kandidat.asalKlinik != null && kandidat.asalKlinik!.isNotEmpty)
                          Text(
                            kandidat.asalKlinik!,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'PENTING: Pilihan bersifat One-time Vote (sekali simpan permanen). Pilihan tidak dapat direvisi atau dibatalkan.',
                      style: TextStyle(fontSize: 11, color: Colors.brown, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _submitVote(kandidat);
            },
            child: const Text('Ya, Simpan Suara Saya', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitVote(KandidatModel kandidat) async {
    setState(() => _isSubmitting = true);

    try {
      final res = await _apiClient.dio.post(
        ApiConstants.pemilihanVote(widget.pemilihanId),
        data: {'kandidat_id': kandidat.id},
      );

      if (res.data['success'] == true) {
        if (mounted) {
          _showSuccessVoteDialog(kandidat);
          await _fetchDetail();
        }
      } else {
        if (mounted) {
          _showWarningDialog(
            title: 'Gagal Menyimpan Suara',
            message: res.data['message'] ?? 'Terjadi kesalahan.',
          );
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.response?.data?['message'] ?? 'Gagal memproses suara.';
        _showWarningDialog(
          title: 'Gagal Menyimpan Suara',
          message: msg,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessVoteDialog(KandidatModel kandidat) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppColors.statusGreen, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Suara Berhasil Disimpan!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Terima kasih telah berpartisipasi dalam musyawarah pemilihan ketua ASKLIN. Suara klinik Anda untuk No. ${kandidat.nomorUrut} (${kandidat.namaCalon}) telah tercatat permanen.',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('OK, Mengerti', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showWarningDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Surat Suara Pemilihan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Hasil Real Count',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PemilihanHasilScreen(pemilihanId: widget.pemilihanId),
                ),
              );
            },
          ),
        ],
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
                        ElevatedButton(onPressed: _fetchDetail, child: const Text('Coba Lagi')),
                      ],
                    ),
                  ),
                )
              : _detail == null
                  ? const Center(child: Text('Data tidak tersedia.'))
                  : Stack(
                      children: [
                        RefreshIndicator(
                          onRefresh: _fetchDetail,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              // Election Header Card
                              _buildHeaderCard(dateFormat),
                              const SizedBox(height: 14),

                              // Eligibility Status Banner
                              _buildEligibilityBanner(dateFormat),
                              const SizedBox(height: 20),

                              // Section Title
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Daftar Calon Ketua (${_detail!.kandidat.length})',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PemilihanHasilScreen(pemilihanId: widget.pemilihanId),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.pie_chart_outline, size: 16, color: AppColors.primaryRed),
                                    label: const Text('Real Count', style: TextStyle(fontSize: 12, color: AppColors.primaryRed)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Candidates List
                              ..._detail!.kandidat.map((kand) => _buildCandidateCard(kand)),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                        if (_isSubmitting)
                          Container(
                            color: Colors.black38,
                            child: const Center(
                              child: Card(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(width: 16),
                                      Text('Menyimpan suara...', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
    );
  }

  Widget _buildHeaderCard(DateFormat dateFormat) {
    final d = _detail!;
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
                    d.tingkat.toUpperCase(),
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
                    'Periode ${d.periode}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              d.judul,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    d.wilayah,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            if (d.tanggalMulai != null && d.tanggalSelesai != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${dateFormat.format(d.tanggalMulai!)} s/d ${dateFormat.format(d.tanggalSelesai!)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
            if (d.deskripsi != null && d.deskripsi!.isNotEmpty) ...[
              const Divider(height: 20),
              Text(
                d.deskripsi!,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEligibilityBanner(DateFormat dateFormat) {
    final d = _detail!;
    if (d.hasVoted) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.statusGreen, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Anda Telah Memberikan Suara',
                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    d.waktuVote != null
                        ? 'Waktu vote: ${dateFormat.format(d.waktuVote!)} WIB. Suara telah tersimpan permanen.'
                        : 'Suara klinik telah tercatat permanen di sistem.',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (!d.isEligible) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: AppColors.primaryRed, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hak Suara Terkunci',
                    style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    d.eligibilityMessage,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: const [
          Icon(Icons.how_to_vote_outlined, color: Colors.blue, size: 26),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hak Suara Aktif (1 Klinik 1 Suara)',
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  'Silakan pelajari visi misi dan tekan tombol "PILIH CALON INI" di bawah calon pilihan Anda.',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateCard(KandidatModel kand) {
    final d = _detail!;
    final canVote = d.isEligible && !d.hasVoted && d.isBerlangsung;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: No Urut and Candidate Basic Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nomor Urut Box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryRed.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${kand.nomorUrut}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 14),

                // Avatar Photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: kand.fotoUrl != null && kand.fotoUrl!.isNotEmpty
                      ? Image.network(
                          kand.fotoUrl!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackAvatar(kand),
                        )
                      : _buildFallbackAvatar(kand),
                ),
                const SizedBox(width: 12),

                // Name & Clinic
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kand.namaLengkap,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      if (kand.asalKlinik != null && kand.asalKlinik!.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.local_hospital_outlined, size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                kand.asalKlinik!,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Visi & Misi Accordion
            if ((kand.visi != null && kand.visi!.isNotEmpty) ||
                (kand.misi != null && kand.misi!.isNotEmpty) ||
                (kand.programKerja != null && kand.programKerja!.isNotEmpty))
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 8, bottom: 8),
                  title: const Text(
                    'Lihat Visi, Misi & Program Kerja',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryRed),
                  ),
                  children: [
                    if (kand.visi != null && kand.visi!.isNotEmpty)
                      _buildInfoSection('Visi Calon', kand.visi!),
                    if (kand.misi != null && kand.misi!.isNotEmpty)
                      _buildInfoSection('Misi Calon', kand.misi!),
                    if (kand.programKerja != null && kand.programKerja!.isNotEmpty)
                      _buildInfoSection('Program Kerja Unggulan', kand.programKerja!),
                  ],
                ),
              ),

            const SizedBox(height: 10),

            // Vote Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canVote ? AppColors.primaryRed : Colors.grey.shade300,
                  foregroundColor: canVote ? Colors.white : Colors.grey.shade600,
                  elevation: canVote ? 2 : 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: canVote ? () => _confirmAndVote(kand) : null,
                icon: Icon(
                  d.hasVoted
                      ? Icons.check
                      : !d.isEligible
                          ? Icons.lock
                          : Icons.how_to_vote,
                  size: 18,
                ),
                label: Text(
                  d.hasVoted
                      ? 'SUDAH MEMILIH'
                      : !d.isEligible
                          ? 'HAK SUARA TERKUNCI'
                          : !d.isBerlangsung
                              ? 'PEMILIHAN TIDAK AKTIF'
                              : 'PILIH CALON NO. ${kand.nomorUrut}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(KandidatModel kand) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        kand.namaCalon.isNotEmpty ? kand.namaCalon.substring(0, 1).toUpperCase() : '?',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.grey),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 2),
          Text(content, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
