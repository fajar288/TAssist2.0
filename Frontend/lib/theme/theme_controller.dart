import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

/// Controls and persists the application's [ThemeMode] (`light`, `dark`, `system`).
class ThemeController extends ChangeNotifier {
  ThemeController._();

  @visibleForTesting
  ThemeController.forTest();

  static final ThemeController instance = ThemeController._();

  static const String _prefsKey = 'tassist_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  String get label => switch (_themeMode) {
        ThemeMode.light => 'Terang',
        ThemeMode.dark => 'Gelap',
        ThemeMode.system => 'Ikuti Sistem',
      };

  IconData get icon => switch (_themeMode) {
        ThemeMode.light => Icons.light_mode_rounded,
        ThemeMode.dark => Icons.dark_mode_rounded,
        ThemeMode.system => Icons.brightness_auto_rounded,
      };

  /// Loads the persisted theme preference from [SharedPreferences].
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      _themeMode = _parseMode(raw);
      notifyListeners();
    } catch (_) {
      // Keep default ThemeMode.system if SharedPreferences is unavailable.
    }
  }

  /// Updates the active [ThemeMode] and persists it to [SharedPreferences].
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.name);
    } catch (_) {
      // Ignore persistence errors in restricted environments/tests.
    }
  }

  static ThemeMode _parseMode(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  /// Shows a shared bottom sheet allowing users to pick Light, Dark, or System theme.
  static Future<void> showThemeSelectorSheet(
    BuildContext context, {
    ThemeController? controller,
  }) {
    final activeController = controller ?? instance;

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AnimatedBuilder(
          animation: activeController,
          builder: (sheetCtx, _) {
            final current = activeController.themeMode;
            final surface = AppTheme.surfaceOf(sheetCtx);
            final textPrimary = AppTheme.textPrimaryOf(sheetCtx);
            final textSecondary = AppTheme.textSecondaryOf(sheetCtx);
            final border = AppTheme.cardBorderOf(sheetCtx);

            Widget optionTile({
              required ThemeMode mode,
              required IconData iconData,
              required String title,
              required String subtitle,
            }) {
              final selected = current == mode;
              final accent = AppTheme.primaryOf(sheetCtx);
              return InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                onTap: () async {
                  await activeController.setThemeMode(mode);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primaryGhostOf(sheetCtx)
                        : AppTheme.surfaceVariantOf(sheetCtx),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: selected ? accent : border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        iconData,
                        color: selected ? accent : textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: accent,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusLg),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: border,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                    ),
                  ),
                  Text(
                    'Tema Tampilan',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pilih mode tampilan yang nyaman untuk mata Anda.',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  optionTile(
                    mode: ThemeMode.system,
                    iconData: Icons.brightness_auto_rounded,
                    title: 'Ikuti Sistem',
                    subtitle: 'Menyesuaikan pengaturan perangkat secara otomatis',
                  ),
                  const SizedBox(height: 10),
                  optionTile(
                    mode: ThemeMode.light,
                    iconData: Icons.light_mode_rounded,
                    title: 'Mode Terang',
                    subtitle: 'Latar cerah dengan kontras tinggi',
                  ),
                  const SizedBox(height: 10),
                  optionTile(
                    mode: ThemeMode.dark,
                    iconData: Icons.dark_mode_rounded,
                    title: 'Mode Gelap',
                    subtitle: 'Latar gelap nyaman di pencahayaan minim',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
