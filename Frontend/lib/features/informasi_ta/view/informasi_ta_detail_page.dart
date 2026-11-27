// lib/features/informasi_ta/view/informasi_ta_detail_page.dart

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../model/informasi_ta_model.dart';

class InformasiTADetailPage extends StatelessWidget {
  final InformasiTAModel informasi;

  const InformasiTADetailPage({
    super.key,
    required this.informasi,
  });

  @override
  Widget build(BuildContext context) {
    final publishedStr = informasi.publishedAt != null
        ? '${informasi.publishedAt!.day.toString().padLeft(2, '0')}/${informasi.publishedAt!.month.toString().padLeft(2, '0')}/${informasi.publishedAt!.year}'
        : '-';

    final surface = AppTheme.surfaceOf(context);
    final textPrimary = AppTheme.textPrimaryOf(context);
    final textSecondary = AppTheme.textSecondaryOf(context);
    final textMuted = AppTheme.textMutedOf(context);
    final cardBorder = AppTheme.cardBorderOf(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundOf(context),
      appBar: AppBar(
        title: Text(
          informasi.kategori,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration:
              AppTheme.cardDecorationOf(context, radius: AppTheme.radiusMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGhostOf(context),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(
                        color: AppTheme.primaryOf(context).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      informasi.kategori,
                      style: TextStyle(
                        color: AppTheme.primaryOf(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.calendar_today_outlined, size: 14, color: textMuted),
                  const SizedBox(width: 4),
                  Text(
                    publishedStr,
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                informasi.judul,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Diterbitkan oleh: ${informasi.penulis}',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              Divider(height: 32, thickness: 1, color: cardBorder),
              Text(
                informasi.kontenOrFile ?? 'Tidak ada konten tambahan.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
