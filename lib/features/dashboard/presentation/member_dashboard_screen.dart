import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

class MemberDashboardScreen extends StatefulWidget {
  const MemberDashboardScreen({Key? key}) : super(key: key);

  @override
  State<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  final _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _statusData;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final resProfile = await _apiClient.dio.get(ApiConstants.profile);
      final resStatus = await _apiClient.dio.get(ApiConstants.statusKeanggotaan);

      setState(() {
        _profileData = resProfile.data['data'];
        _statusData = resStatus.data['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
      );
    }

    final klinik = _profileData?['klinik'] ?? {};
    final namaKlinik = klinik['nama_klinik'] ?? 'Klinik Pratama Sehat';
    final noAnggota = klinik['no_anggota'] ?? 'Menunggu Verifikasi';
    final status = klinik['status'] ?? 'Draft';
    final isApproved = status.toString().toLowerCase() == 'approved';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Dasbor dengan Motif Merah Melengkung
            AsklinHeaderOrnament(
              height: 220,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dasbor Keanggotaan',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              namaKlinik,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_none, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AsklinStatusBadge(status: status, isApproved: isApproved),
                  ],
                ),
              ),
            ),

            // Kartu Anggota Digital
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Transform.translate(
                offset: const Offset(0, -35),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'KARTU ANGGOTA ASKLIN',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryRed,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.softRed,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                klinik['jenis_klinik'] ?? 'Pratama',
                                style: const TextStyle(
                                  color: AppColors.primaryRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          namaKlinik,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No. Anggota: $noAnggota',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Divider(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Masa Berlaku SIO', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                const SizedBox(height: 2),
                                Text(
                                  klinik['tgl_akhir_ijin'] ?? 'Hingga 2028',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Iuran Anggota', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                const SizedBox(height: 2),
                                Text(
                                  klinik['is_lunas'] == true ? 'LUNAS' : 'MENUNGGU',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: klinik['is_lunas'] == true ? AppColors.statusGreen : AppColors.statusYellow,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Aksi Cepat / Dokumen Digital
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dokumen & Legalitas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionDocCard(
                          title: 'Unduh SK',
                          subtitle: 'Surat Keputusan',
                          icon: Icons.assignment_outlined,
                          isReady: isApproved,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Mengunduh SK Keanggotaan ASKLIN...')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionDocCard(
                          title: 'Sertifikat',
                          subtitle: 'Sertifikat Anggota',
                          icon: Icons.verified_outlined,
                          isReady: isApproved,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Mengunduh Sertifikat Resmi ASKLIN...')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Alur Verifikasi Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status Alur Verifikasi',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 14),
                          _TimelineStep(
                            title: 'Pendaftaran Dokumen',
                            subtitle: 'Klinik melengkapi berkas & perizinan',
                            isDone: true,
                          ),
                          _TimelineStep(
                            title: 'Verifikasi Pengurus Cabang',
                            subtitle: 'Pengecekan wilayah kabupaten/kota',
                            isDone: isApproved,
                          ),
                          _TimelineStep(
                            title: 'Penerbitan SK Pengurus Pusat',
                            subtitle: 'Penerbitan nomor anggota dan e-Sertifikat',
                            isDone: isApproved,
                            isLast: true,
                          ),
                        ],
                      ),
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

class _ActionDocCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isReady;
  final VoidCallback onTap;

  const _ActionDocCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isReady,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isReady ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isReady ? AppColors.softRed : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isReady ? AppColors.primaryRed : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              isReady ? subtitle : 'Belum Tersedia',
              style: TextStyle(
                fontSize: 11,
                color: isReady ? AppColors.textSecondary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isLast;

  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.isDone,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isDone ? AppColors.statusGreen : AppColors.textMuted,
              size: 20,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isDone ? AppColors.statusGreen : AppColors.borderSubtle,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDone ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
