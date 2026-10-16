import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

class OrganisasiScreen extends StatefulWidget {
  const OrganisasiScreen({Key? key}) : super(key: key);

  @override
  State<OrganisasiScreen> createState() => _OrganisasiScreenState();
}

class _OrganisasiScreenState extends State<OrganisasiScreen> {
  final _apiClient = ApiClient();
  String _tingkat = 'pusat'; // 'pusat', 'daerah', 'cabang'
  bool _isLoading = true;
  Map<String, dynamic>? _organisasiData;

  @override
  void initState() {
    super.initState();
    _fetchOrganisasi();
  }

  Future<void> _fetchOrganisasi() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get(
        ApiConstants.organisasi,
        queryParameters: {'tingkat': _tingkat},
      );
      if (mounted) {
        setState(() {
          _organisasiData = res.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchHelper(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final ringkasan = _organisasiData?['ringkasan'] ?? {};

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Direktori Organisasi ASKLIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Ringkasan Statistik Nasional
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    _StatCard(title: 'DPP Pusat', count: ringkasan['dpp_count']?.toString() ?? '1'),
                    const SizedBox(width: 10),
                    _StatCard(title: 'DPD Daerah', count: ringkasan['dpd_count']?.toString() ?? '34'),
                    const SizedBox(width: 10),
                    _StatCard(title: 'DPC Cabang', count: ringkasan['dpc_count']?.toString() ?? '152'),
                  ],
                ),
                const SizedBox(height: 16),

                // Filter Tingkat Organisasi
                Row(
                  children: [
                    Expanded(
                      child: AsklinCategoryChip(
                        label: 'Pusat (DPP)',
                        isSelected: _tingkat == 'pusat',
                        onTap: () {
                          setState(() => _tingkat = 'pusat');
                          _fetchOrganisasi();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AsklinCategoryChip(
                        label: 'Daerah (DPD)',
                        isSelected: _tingkat == 'daerah',
                        onTap: () {
                          setState(() => _tingkat = 'daerah');
                          _fetchOrganisasi();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AsklinCategoryChip(
                        label: 'Cabang (DPC)',
                        isSelected: _tingkat == 'cabang',
                        onTap: () {
                          setState(() => _tingkat = 'cabang');
                          _fetchOrganisasi();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Konten Organisasi Sesuai Tingkat
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                : _tingkat == 'pusat'
                    ? _buildPusatContent()
                    : _tingkat == 'daerah'
                        ? _buildDaerahContent()
                        : _buildCabangContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPusatContent() {
    final detail = _organisasiData?['detail'] ?? {};
    final pengurus = _organisasiData?['pengurus'] as List? ?? [];
    final isPengurusPusat = _organisasiData?['is_pengurus_pusat'] == true;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card Sekretariat Pusat
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.softRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.account_balance, color: AppColors.primaryRed, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail['nama_struktur'] ?? 'Dewan Pengurus Pusat ASKLIN',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text('Periode ${detail['periode'] ?? '2023 - 2028'}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        detail['alamat_sekretariat'] ?? 'Jl. Kramat VII No. 34, Senen, Jakarta Pusat',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        detail['email_sekretariat'] ?? 'dpp@asklin.org',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                if (isPengurusPusat && detail['telp_sekretariat'] != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: Colors.green),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Hotline DPP: ${detail['telp_sekretariat']}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                          ),
                        ),
                        InkWell(
                          onTap: () => _launchHelper('tel:${detail['telp_sekretariat']}'),
                          child: const Icon(Icons.call, size: 18, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Struktur Kepengurusan Pusat',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.softRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${pengurus.length} Personil',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryRed),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (pengurus.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text('Belum ada data pengurus pusat.', style: TextStyle(color: AppColors.textMuted)),
            ),
          )
        else
          ...pengurus.map((p) => _buildPengurusCard(p, isPengurusPusat)),
      ],
    );
  }

  Widget _buildPengurusCard(dynamic p, bool isPengurusPusat) {
    final int level = p['level'] ?? 0;
    final String jabatan = p['jabatan'] ?? '';
    final String nama = p['nama_lengkap'] ?? '';
    final String? parentJabatan = p['parent_jabatan'];
    final String? noTelp = p['no_telp'];
    final bool canViewContact = p['can_view_contact'] == true;

    // Margin kiri berdasarkan level tree
    final double leftPadding = level == 0 ? 0 : (level == 1 ? 14 : 26);

    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    if (level == 0) {
      badgeBg = const Color(0xFFFDE8E8);
      badgeText = AppColors.primaryRed;
      badgeLabel = 'PIMPINAN INTI';
    } else if (level == 1) {
      badgeBg = const Color(0xFFE6F4EA);
      badgeText = const Color(0xFF137333);
      badgeLabel = 'KOORDINATOR / BIDANG';
    } else {
      badgeBg = const Color(0xFFE8F0FE);
      badgeText = const Color(0xFF1A73E8);
      badgeLabel = 'ANGGOTA / STAF';
    }

    return Padding(
      padding: EdgeInsets.only(left: leftPadding, bottom: 8),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: level == 0 ? AppColors.primaryRed.withOpacity(0.3) : AppColors.borderSubtle,
            width: level == 0 ? 1.2 : 0.8,
          ),
        ),
        elevation: level == 0 ? 1.5 : 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: level == 0 ? 22 : 18,
                    backgroundColor: level == 0 ? AppColors.primaryRed : AppColors.softRed,
                    child: Text(
                      nama.isNotEmpty ? nama.trim().split(' ').map((w) => w[0]).take(2).join('').toUpperCase() : 'P',
                      style: TextStyle(
                        fontSize: level == 0 ? 13 : 11,
                        fontWeight: FontWeight.bold,
                        color: level == 0 ? Colors.white : AppColors.primaryRed,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                badgeLabel,
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeText),
                              ),
                            ),
                            if (parentJabatan != null && level > 0) ...[
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Bawahan: $parentJabatan',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nama,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: level == 0 ? 14 : 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          jabatan,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: level == 0 ? AppColors.primaryRed : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Aksi Kontak Khusus Pengurus Pusat (Hanya WhatsApp dan Email, tanpa nomor default)
              if (canViewContact) ...[
                const Divider(height: 16),
                Row(
                  children: [
                    const Icon(Icons.phone_android, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      (noTelp != null && noTelp.isNotEmpty) ? noTelp : 'Belum diisi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: (noTelp != null && noTelp.isNotEmpty) ? FontWeight.w600 : FontWeight.normal,
                        fontStyle: (noTelp != null && noTelp.isNotEmpty) ? FontStyle.normal : FontStyle.italic,
                        color: (noTelp != null && noTelp.isNotEmpty) ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    // Tombol WhatsApp (Hanya jika noTelp ada)
                    if (noTelp != null && noTelp.isNotEmpty) ...[
                      InkWell(
                        onTap: () {
                          final cleanPhone = noTelp.replaceAll(RegExp(r'[^0-9]'), '');
                          final formatted = cleanPhone.startsWith('0') ? '62${cleanPhone.substring(1)}' : cleanPhone;
                          _launchHelper('https://wa.me/$formatted');
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F4EA),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF34A853).withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.chat, size: 13, color: Color(0xFF137333)),
                              SizedBox(width: 4),
                              Text('WhatsApp', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF137333))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    // Tombol Email (Hanya jika email ada)
                    if (email != null && email.isNotEmpty) ...[
                      InkWell(
                        onTap: () => _launchHelper('mailto:$email'),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.softRed,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.primaryRed.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.email_outlined, size: 13, color: AppColors.primaryRed),
                              SizedBox(width: 4),
                              Text('Email', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryRed)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaerahContent() {
    final list = _organisasiData?['daftar_dpd'] as List? ?? [];
    final isPengurusPusat = _organisasiData?['is_pengurus_pusat'] == true;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final dpd = list[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.map_outlined, color: AppColors.primaryRed),
            title: Text(dpd['nama_struktur'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(dpd['alamat_sekretariat'] ?? 'Sekretariat DPD Provinsi', style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () {
              _showDetailOrganisasiModal(
                context,
                title: dpd['nama_struktur'] ?? 'DPD ASKLIN',
                periode: dpd['periode'] ?? '2023 - 2028',
                alamat: dpd['alamat_sekretariat'] ?? 'Sekretariat DPD Provinsi',
                email: dpd['email_sekretariat'] ?? 'dpd@asklin.org',
                telp: dpd['telp_sekretariat'] ?? 'Hubungi Pengurus Pusat',
                isPengurusPusat: isPengurusPusat,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCabangContent() {
    final list = _organisasiData?['daftar_dpc'] as List? ?? [];
    final isPengurusPusat = _organisasiData?['is_pengurus_pusat'] == true;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final dpc = list[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.location_city, color: AppColors.primaryRed),
            title: Text(dpc['nama_struktur'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('Provinsi: ${dpc['provinsi_name'] ?? '-'}', style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () {
              _showDetailOrganisasiModal(
                context,
                title: dpc['nama_struktur'] ?? 'DPC ASKLIN',
                periode: dpc['periode'] ?? '2023 - 2028',
                alamat: dpc['alamat_sekretariat'] ?? 'Sekretariat Cabang',
                email: dpc['email_sekretariat'] ?? 'dpc@asklin.org',
                telp: dpc['telp_sekretariat'] ?? 'Hubungi Sekretariat Daerah',
                isPengurusPusat: isPengurusPusat,
              );
            },
          ),
        );
      },
    );
  }

  void _showDetailOrganisasiModal(
    BuildContext context, {
    required String title,
    required String periode,
    required String alamat,
    required String email,
    required String telp,
    required bool isPengurusPusat,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.softRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance, color: AppColors.primaryRed, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Periode: $periode', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Alamat: ${alamat.isNotEmpty ? alamat : 'Belum diisi'}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Text('Email: ${email.isNotEmpty && !email.contains('asklin.org') ? email : (email.isNotEmpty ? email : 'Belum diisi')}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Text('Kontak / No. Telp: ${telp.isNotEmpty && !telp.contains('Hubungi') ? telp : 'Belum diisi'}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),

              if (isPengurusPusat && (telp.isNotEmpty && !telp.contains('Hubungi') || email.isNotEmpty)) ...[
                Row(
                  children: [
                    if (telp.isNotEmpty && !telp.contains('Hubungi'))
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('WhatsApp'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            final cleanPhone = telp.replaceAll(RegExp(r'[^0-9]'), '');
                            final formatted = cleanPhone.startsWith('0') ? '62${cleanPhone.substring(1)}' : cleanPhone;
                            _launchHelper('https://wa.me/$formatted');
                          },
                        ),
                      ),
                    if (telp.isNotEmpty && !telp.contains('Hubungi') && email.isNotEmpty)
                      const SizedBox(width: 10),
                    if (email.isNotEmpty)
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.email_outlined, size: 18),
                          label: const Text('Kirim Email'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _launchHelper('mailto:$email'),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('TUTUP', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;

  const _StatCard({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryRed,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
