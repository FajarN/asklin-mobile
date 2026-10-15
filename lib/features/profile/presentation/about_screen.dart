import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

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
              'Asosiasi Klinik Indonesia (ASKLIN) adalah organisasi profesi dan perhimpunan resmi klinik-klinik di seluruh Indonesia yang berdedikasi untuk memajukan standar mutu pelayanan kesehatan, memperkuat tata kelola klinik, dan memperjuangkan aspirasi fasilitas pelayanan kesehatan primer dan sekunder.',
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
                    SizedBox(height: 6),
                    Text(
                      'Menjadi wadah berhimpun klinik di Indonesia yang profesional, berintegritas, dan terpercaya dalam mewujudkan pelayanan kesehatan paripurna bagi masyarakat.',
                      style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.textSecondary),
                    ),
                    Divider(height: 20),
                    Text('Misi ASKLIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryRed)),
                    SizedBox(height: 6),
                    Text(
                      '1. Membina dan mendampingi klinik anggota dalam proses akreditasi dan kepatuhan regulasi.\n2. Mengembangkan kompetensi tenaga medis dan manajemen klinik.\n3. Membangun sinergi yang harmonis dengan Kementerian Kesehatan, BPJS Kesehatan, dan mitra strategis.',
                      style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.textSecondary),
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

