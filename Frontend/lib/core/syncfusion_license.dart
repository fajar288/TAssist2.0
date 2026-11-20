/// Syncfusion Community Licence bootstrap (T-05).
///
/// ### Why this is (currently) a no-op
/// The installed Syncfusion Flutter packages (`syncfusion_flutter_pdfviewer`
/// 33.2.13 / `syncfusion_flutter_core` 33.2.15) no longer export a runtime
/// registration API: there is no `SyncfusionLicenseRegistry`,
/// `SyncfusionLicense.registerLicense` or equivalent anywhere in the pub-cache
/// sources. Earlier 2x releases exposed one from `syncfusion_flutter_core`;
/// it was removed, so calling it here would not even compile.
///
/// This class therefore keeps the single call site that T-13 (the annotation
/// viewer) and future Syncfusion widgets use, reads the key from the build,
/// and records whether one was supplied. If a future package version
/// reintroduces a registration entry point, only this file changes.
///
/// ### Supplying the key
/// ```bash
/// flutter run --dart-define=SYNCFUSION_LICENSE_KEY=<key>
/// ```
/// Omitting the define is safe: [register] returns immediately.
///
/// See `Docs/THIRD_PARTY.md` for the licence terms.
class SyncfusionLicense {
  const SyncfusionLicense._();

  /// Compile-time key, empty when the `--dart-define` is not supplied.
  static const String licenseKey = String.fromEnvironment(
    'SYNCFUSION_LICENSE_KEY',
  );

  /// True when a key was baked into this build.
  static bool get hasKey => licenseKey.isNotEmpty;

  /// Registers the Syncfusion Community Licence for this process.
  ///
  /// No-op when no key was supplied, and never throws. Safe to call more than
  /// once.
  static void register() {
    if (licenseKey.isEmpty) return;

    // Intentionally no registry call: the 33.x packages ship none (see the
    // class doc). Kept as the single wiring point for the day they do.
  }
}
