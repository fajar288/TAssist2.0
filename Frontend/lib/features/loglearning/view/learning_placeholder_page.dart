import 'package:flutter/material.dart';
import 'package:tassist/theme/app_theme.dart';
import 'package:tassist/widgets/app_empty_state_widget.dart';

class LearningPlaceholderPage extends StatelessWidget {
  const LearningPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOf(context),
      appBar: AppBar(
        title: const Text('Portal Learning'),
        centerTitle: true,
      ),
      body: AppEmptyStateWidget(
        icon: Icons.school_outlined,
        title: 'Integrasi Portal Learning (Coming soon)',
        subtitle:
            'Login melalui portal akademik kampus sedang disiapkan. Gunakan akun email atau Google Sign-In untuk masuk saat ini.',
        actionLabel: 'Kembali ke Login',
        onAction: () => Navigator.of(context).pop(),
      ),
    );
  }
}
