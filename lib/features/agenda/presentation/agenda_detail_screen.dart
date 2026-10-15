import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/formatted_content_widget.dart';

class AgendaDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const AgendaDetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  State<AgendaDetailScreen> createState() => _AgendaDetailScreenState();
}

class _AgendaDetailScreenState extends State<AgendaDetailScreen> {
  final _apiClient = ApiClient();
  Map<String, dynamic>? _detailData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFullEvent();
  }

  Future<void> _fetchFullEvent() async {
    final slug = widget.item['slug'] ?? widget.item['id']?.toString();
    if (slug == null) {
      setState(() {
        _detailData = widget.item;
        _isLoading = false;
      });
      return;
    }

    try {
      final res = await _apiClient.dio.get('${ApiConstants.agenda}/$slug');
      if (res.data['success'] == true) {
        setState(() {
          _detailData = res.data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _detailData = widget.item;
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _detailData = widget.item;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _detailData ?? widget.item;
    final statusPill = data['status_pill'] ?? 'Pendaftaran Buka';
    final isUpcoming = statusPill == 'Pendaftaran Buka' || statusPill == 'Sedang Berlangsung';
    final rawContent = data['konten_html'] ?? data['konten_bersih'] ?? data['excerpt'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detail Kegiatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Merah Header
            Container(
              width: double.infinity,
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryRed, AppColors.primaryDarkRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_available, size: 54, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        statusPill,
                        style: TextStyle(
                          color: isUpcoming ? AppColors.statusGreen : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['judul'] ?? 'Agenda ASKLIN',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info Tanggal & Waktu
                  _InfoRow(
                    icon: Icons.calendar_month,
                    title: 'Tanggal Pelaksanaan',
                    value: data['tanggal_formatted'] ?? 'Lihat jadwal resmi',
                  ),
                  const SizedBox(height: 12),

                  // Info Jam
                  if (data['jam_formatted'] != null) ...[
                    _InfoRow(
                      icon: Icons.access_time,
                      title: 'Waktu / Jam',
                      value: data['jam_formatted'],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Info Lokasi
                  _InfoRow(
                    icon: Icons.location_on,
                    title: 'Tempat / Lokasi',
                    value: data['lokasi'] ?? 'ASKLIN Indonesia',
                  ),
                  const Divider(height: 32),

                  const Text(
                    'Deskripsi & Rincian Kegiatan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),

                  _isLoading
                      ? const Center(child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(color: AppColors.primaryRed),
                        ))
                      : FormattedContentWidget(rawText: rawContent),

                  const SizedBox(height: 30),

                  if (isUpcoming)
                    AsklinPrimaryButton(
                      text: 'DAFTAR KEGIATAN INI',
                      icon: Icons.app_registration,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pendaftaran kegiatan dibuka melalui portal resmi ASKLIN.'),
                            backgroundColor: AppColors.statusGreen,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.softRed,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryRed, size: 20),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
      ],
    );
  }
}
