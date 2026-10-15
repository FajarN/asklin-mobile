import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class FormattedContentWidget extends StatelessWidget {
  final String rawText;

  const FormattedContentWidget({Key? key, required this.rawText}) : super(key: key);

  String _cleanAndFormatText(String text) {
    var cleaned = text
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<p>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]*>'), '');

    // Format agar emoji dan poin-poin memiliki baris tersendiri
    cleaned = cleaned.replaceAll('✅', '\n✅ ');
    cleaned = cleaned.replaceAll('✔️', '\n✔️ ');
    cleaned = cleaned.replaceAll('📍', '\n📍 ');
    cleaned = cleaned.replaceAll('📅', '\n📅 ');
    cleaned = cleaned.replaceAll('⏰', '\n⏰ ');
    cleaned = cleaned.replaceAll('🏨', '\n🏨 ');
    cleaned = cleaned.replaceAll('💰', '\n💰 ');
    cleaned = cleaned.replaceAll('📞', '\n📞 ');
    cleaned = cleaned.replaceAll('🔗', '\n🔗 ');
    cleaned = cleaned.replaceAll('🔹', '\n🔹 ');
    cleaned = cleaned.replaceAll('🔸', '\n🔸 ');

    // Rapikan spasi dan baris ganda
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return cleaned.trim();
  }

  @override
  Widget build(BuildContext context) {
    final formatted = _cleanAndFormatText(rawText);
    final paragraphs = formatted.split('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((para) {
        final trimmed = para.trim();
        if (trimmed.isEmpty) return const SizedBox.shrink();

        // Jika paragraf berisi poin emoji
        final isBullet = trimmed.contains('✅') || trimmed.contains('✔️') || trimmed.contains('📍');

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            trimmed,
            style: TextStyle(
              fontSize: 14,
              height: isBullet ? 1.6 : 1.7,
              color: AppColors.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
        );
      }).toList(),
    );
  }
}
