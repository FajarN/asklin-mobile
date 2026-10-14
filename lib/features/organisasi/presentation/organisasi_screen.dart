import 'package:flutter/material.dart';
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
      setState(() {
        _organisasiData = res.data['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card Sekretariat Pusat
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance, color: AppColors.primaryRed),
                    const SizedBox(width: 8),
                    Text(
                      detail['nama_struktur'] ?? 'Dewan Pengurus Pusat ASKLIN',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Periode Kepengurusan: ${detail['periode'] ?? '2023 - 2028'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('Alamat: ${detail['alamat_sekretariat'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('Email: ${detail['email_sekretariat'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Susunan Pengurus Pusat',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),

        ...pengurus.map((p) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.softRed,
                child: const Icon(Icons.person, color: AppColors.primaryRed),
              ),
              title: Text(p['nama_lengkap'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(p['jabatan'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.primaryRed)),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDaerahContent() {
    final list = _organisasiData?['daftar_dpd'] as List? ?? [];
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
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCabangContent() {
    final list = _organisasiData?['daftar_dpc'] as List? ?? [];
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
              Text('Alamat: $alamat', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Text('Email: $email', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Text('Kontak: $telp', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
                  child: const Text('TUTUP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

