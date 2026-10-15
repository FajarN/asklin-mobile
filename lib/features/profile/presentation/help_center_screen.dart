import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  Future<void> _launchUrlHelper(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Pusat Bantuan & Kontak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Kontak Utama Sekretariat Pusat
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
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
                          child: const Icon(Icons.headset_mic, color: AppColors.primaryRed, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sekretariat Pengurus Pusat',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Asosiasi Klinik Indonesia (ASKLIN)',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),

                    _ContactRow(
                      icon: Icons.location_on_outlined,
                      label: 'Alamat Kantor',
                      value: 'Jl. Pinang Ranti II No. 1A, Makasar, Jakarta Timur, DKI Jakarta 13560',
                    ),
                    const SizedBox(height: 12),

                    _ContactRow(
                      icon: Icons.phone_outlined,
                      label: 'Telepon Kantor',
                      value: '(021) 8098928',
                      actionTitle: 'Panggil',
                      onAction: () => _launchUrlHelper('tel:0218098928'),
                    ),
                    const SizedBox(height: 12),

                    _ContactRow(
                      icon: Icons.mail_outline,
                      label: 'Email Resmi',
                      value: 'pp_asklin@asklin.org',
                      actionTitle: 'Email',
                      onAction: () => _launchUrlHelper('mailto:pp_asklin@asklin.org'),
                    ),
                    const SizedBox(height: 12),

                    _ContactRow(
                      icon: Icons.language,
                      label: 'Website Resmi',
                      value: 'https://asklin.org',
                      actionTitle: 'Buka Web',
                      onAction: () => _launchUrlHelper('https://asklin.org'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Cepat Layanan WhatsApp
            InkWell(
              onTap: () => _launchUrlHelper('https://wa.me/6281219486667?text=Halo%20Admin%20ASKLIN,%20saya%20anggota%20klinik%20ingin%20bertanya%20terkait%20layanan%20keanggotaan.'),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF25D366).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat, color: Colors.white, size: 28),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chat Layanan WhatsApp ASKLIN',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Konsultasi pendaftaran, verifikasi, dan bantuan teknis',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tanya Jawab Sering Ditanyakan (FAQ)
            const Text(
              'Pertanyaan Sering Diajukan (FAQ)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),

            Card(
              child: ExpansionTile(
                title: const Text('Berapa lama verifikasi keanggotaan klinik?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text(
                      'Proses verifikasi biasanya memakan waktu 3-7 hari kerja melalui verifikasi berkas oleh Pengurus Cabang dan pengesahan oleh Pengurus Pusat.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            Card(
              child: ExpansionTile(
                title: const Text('Kapan saya bisa mengunduh SK dan Sertifikat?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text(
                      'Tombol unduh SK dan Sertifikat akan otomatis aktif setelah status keanggotaan klinik berubah menjadi "Terverifikasi / Aktif (Approved)".',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
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
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? actionTitle;
  final VoidCallback? onAction;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.actionTitle,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primaryRed),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        if (actionTitle != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(50, 30),
            ),
            child: Text(
              actionTitle!,
              style: const TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

