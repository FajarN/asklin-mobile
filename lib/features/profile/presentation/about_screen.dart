import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tentang ASKLIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo & Identitas Aplikasi
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.softRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_hospital, color: AppColors.primaryRed, size: 50),
            ),
            const SizedBox(height: 14),
            const Text(
              'ASKLIN MOBILE',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Versi 1.0.0 (Build Release)',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Profil Singkat
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mengenal ASKLIN',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tujuan kemitraan untuk organisasi ASKLIN adalah untuk mencapai upaya peningkatan kualitas dan pelayanan klinik anggota ASKLIN demi mencapai sasaran akhir adalah kesehatan bagi masyarakat yang menerima pelayanan klinik. Adapun bentuk kemitraan yang akan dilaksanakan oleh ASKLIN adalah kerjasama dengan pihak asuransi dan juga beberapa pihak yang dapat menunjang kegiatan operasional klinik. Sehingga dengan adanya ASKLIN kemitraan yang dikembangnkan saling menguntungkan bagi masing-masing pihak.',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 13, height: 1.6, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Visi & Misi Card
            Card(
              color: AppColors.backgroundLight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Visi ASKLIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryRed)),
                    SizedBox(height: 8),
                    Text(
                      '”Menjadikan Klinik sebagai sarana pelayanan kesehatan terdepan dalam melayani kesehatan masyarakat dengan sistem rujukan yang terarah dan terpadu”.',
                      style: TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                    ),
                    Divider(height: 24),
                    Text('Misi ASKLIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryRed)),
                    SizedBox(height: 8),
                    Text(
                      '1. Membantu/memfasilitasi klinik menyelesaikan permasalahan.\n2. Menjaga standar klinik dalam memberikan pelayanan kepada masyarakat.\n3. Menghindari/mencegah persaingan tidak sehat antar klinik.\n4. Melakukan advokasi/pembelaan bagi klinik.\n5. Menyampaikan informasi kepada klinik tentang program-program Pemerintah tentang kesehatan yang harus dilaksanakan bersama masyarakat.\n6. Membantu terlaksananya tertib administrasi klinik dalam rangka menuju pelayanan yang berkualitas dan dapat dipertanggungjawabkan.',
                      style: TextStyle(fontSize: 12, height: 1.6, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              '© 2026 Pengurus Pusat ASKLIN Indonesia\nSeluruh Hak Cipta Dilindungi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

