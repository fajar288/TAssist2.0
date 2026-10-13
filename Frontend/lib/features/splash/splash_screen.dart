import 'dart:math' show sqrt;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SplashScreen — Layar awal TAssist
///
/// Urutan animasi:
/// 1. [0ms]      Latar belakang #EEF2F6 (kosong).
/// 2. [300ms]    Icon graduation-cap turun dengan smooth dari atas + glow pulse.
/// 3. [2300ms]   Circle reveal: biru memenuhi seluruh layar via ClipPath.
/// 4. [2850ms]   Teks "TAssist" slide-in dari kanan + shimmer.
/// 5. [4650ms]   Layar biru fade ke halaman login via FadeTransition.
///
/// PENTING — Cara navigasi fade bekerja:
/// SplashScreen menerima [destinationBuilder] callback yang mengembalikan
/// widget halaman tujuan. Ini jauh lebih reliable daripada mencoba me-resolve
/// named route dari dalam PageRouteBuilder, karena MaterialApp tidak mengekspos
/// routes map-nya secara publik.
///
/// Di app.dart, ubah route splash menjadi:
/// ```dart
/// splashRoute: (_) => SplashScreen(
///   destinationBuilder: (_) => const LoginPage(),
/// ),
/// ```
class SplashScreen extends StatefulWidget {
  /// Builder yang mengembalikan widget halaman tujuan setelah splash.
  /// Dipakai di dalam PageRouteBuilder untuk fade transition.
  ///
  /// Contoh penggunaan di app.dart:
  /// ```dart
  /// SplashScreen(destinationBuilder: (_) => const LoginPage())
  /// ```
  final WidgetBuilder destinationBuilder;

  const SplashScreen({super.key, required this.destinationBuilder});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ─── Warna ──────────────────────────────────────────────────────────────────
  static const _blue = Color(0xFF1A6EE0);
  static const _bg   = Color(0xFFEEF2F6);

  // ─── Controllers & Animations ───────────────────────────────────────────────

  /// Fase 1 – Icon turun + fade-in + scale landing saat mendarat
  late final AnimationController _iconDropCtrl;
  late final Animation<Offset>   _iconSlideAnim;
  late final Animation<double>   _iconFadeAnim;
  late final Animation<double>   _iconScaleAnim;

  /// Fase 2 – Glow berdenyut di sekitar icon (loop)
  late final AnimationController _glowPulseCtrl;
  late final Animation<double>   _glowAnim;

  /// Fase 3 – Circle reveal via ClipPath
  late final AnimationController _revealCtrl;
  late final Animation<double>   _revealAnim;

  /// Fase 4 – Teks slide-in + fade
  late final AnimationController _textCtrl;
  late final Animation<Offset>   _textSlideAnim;
  late final Animation<double>   _textFadeAnim;

  /// Fase 5 – Shimmer satu kali menyapu teks
  late final AnimationController _shimmerCtrl;
  late final Animation<double>   _shimmerAnim;

  @override
  void initState() {
    super.initState();

    // ── Fase 1: Icon drop ────────────────────────────────────────────────────
    //
    // Durasi 900ms (lebih panjang dari sebelumnya 700ms) agar tidak terburu-buru.
    _iconDropCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Kurva slide: Cubic(0.25, 0.1, 0.25, 1.0) = kurva "ease" standar CSS.
    // Akselerasi sedang di awal, melambat sangat halus di akhir.
    // Lebih smooth dari easeOutBack yang memberikan bounce/overshoot agresif.
    _iconSlideAnim = Tween<Offset>(
      begin: const Offset(0, -0.7),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _iconDropCtrl,
      curve: const Cubic(0.25, 0.1, 0.25, 1.0),
    ));

    // Fade-in selesai di 60% pertama animasi → icon sudah fully opaque
    // sebelum mendarat, tidak terkesan "memudar" bersamaan dengan pendaratan.
    _iconFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _iconDropCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Scale landing: aktif hanya di 40% akhir animasi (interval 0.6–1.0).
    // Icon mengecil sedikit (1.0 → 0.88) saat "impact", lalu spring back
    // ke ukuran normal (0.88 → 1.0) dengan kurva elasticOut.
    // Efek ini memberi kesan berat/momentum objek yang jatuh.
    _iconScaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.88), // mengecil saat impact
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.88, end: 1.0)  // spring back ke normal
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(CurvedAnimation(
      parent: _iconDropCtrl,
      curve: const Interval(0.6, 1.0),
    ));

    // ── Fase 2: Glow pulse (loop, 1400ms/siklus) ────────────────────────────
    _glowPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowPulseCtrl, curve: Curves.easeInOut),
    );

    // ── Fase 3: Circle reveal (550ms) ───────────────────────────────────────
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    // easeInCubic: lambat → cepat, memberi kesan "meledak" keluar.
    _revealAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _revealCtrl, curve: Curves.easeInCubic),
    );

    // ── Fase 4: Teks slide-in (450ms) ───────────────────────────────────────
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _textSlideAnim = Tween<Offset>(
      begin: const Offset(0.8, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _textFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn),
    );

    // ── Fase 5: Shimmer satu kali (900ms) ───────────────────────────────────
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    // Bergerak dari -1 ke 2: highlight melintas dari luar kiri ke luar kanan.
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Fase 1 – Icon turun (900ms)
    _iconDropCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 900));

    // Tahan icon di tengah sambil glow berdenyut (1100ms)
    await Future.delayed(const Duration(milliseconds: 1100));

    // Fase 3 – Circle reveal biru (550ms)
    _glowPulseCtrl.stop();
    _revealCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 550));

    // Fase 4 – Teks slide-in (450ms)
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 450));

    // Fase 5 – Shimmer
    _shimmerCtrl.forward();

    // Tahan agar pengguna sempat membaca (900ms)
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    // ── Navigasi dengan FadeTransition ──────────────────────────────────────
    //
    // Mengapa PageRouteBuilder + destinationBuilder, bukan pushReplacementNamed?
    //
    // pushReplacementNamed tidak bisa diberi custom transition karena ia
    // menggunakan transisi default dari MaterialPageRoute (slide di Android,
    // tidak ada di iOS). Untuk FadeTransition kita butuh PageRouteBuilder.
    //
    // Tantangan PageRouteBuilder + named route:
    // MaterialApp menyimpan routes map secara internal di Navigator dan tidak
    // mengeksposnya secara publik. Mencoba mengaksesnya via onGenerateRoute
    // atau findAncestorWidget rapuh dan bisa null.
    //
    // Solusi terbersih:
    // SplashScreen menerima [destinationBuilder] — callback yang mengembalikan
    // widget halaman tujuan. Ini persis seperti yang dilakukan routes map
    // (`loginRoute: (_) => const LoginPage()`), hanya diteruskan langsung.
    // Zero magic, zero lookup, 100% reliable.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        // RouteSettings agar back stack dan deep link tetap konsisten.
        settings: RouteSettings(name: Navigator.defaultRouteName),
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (ctx, animation, secondaryAnimation) {
          // Panggil destinationBuilder untuk mendapat widget halaman tujuan.
          // Sama persis dengan cara routes map bekerja di MaterialApp.
          return widget.destinationBuilder(ctx);
        },
        transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
          // FadeTransition: halaman login fade-in dari opacity 0 ke 1.
          // easeInOut → lambat di awal (tidak tiba-tiba muncul) dan lambat
          // di akhir (tidak mendadak selesai). Terasa sangat natural.
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _iconDropCtrl.dispose();
    _glowPulseCtrl.dispose();
    _revealCtrl.dispose();
    _textCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Setengah diagonal = jarak dari tengah ke sudut terjauh.
    // Radius ini menjamin ClipPath menutupi SELURUH layar termasuk keempat sudut.
    final double maxRevealRadius =
        sqrt(size.width * size.width + size.height * size.height) / 2;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        fit: StackFit.expand,
        children: [

          // ── Layer 1: Panel biru full-layar di-reveal dengan ClipPath ──────
          //
          // Container biru sudah memenuhi SELURUH layar sejak frame pertama.
          // ClipPath membatasi area yang terlihat: lingkaran kecil (radius=0)
          // lalu membesar hingga radius = maxRevealRadius sehingga semua piksel
          // layar tertutup biru.
          AnimatedBuilder(
            animation: _revealAnim,
            builder: (_, __) => ClipPath(
              clipper: _CircleClipper(
                center: Offset(size.width / 2, size.height / 2),
                radius: _revealAnim.value * maxRevealRadius,
              ),
              child: Container(color: _blue),
            ),
          ),

          // ── Layer 2: Icon graduation-cap + glow (memudar saat reveal) ────
          AnimatedBuilder(
            animation: Listenable.merge([_iconFadeAnim, _revealAnim]),
            builder: (_, __) {
              final double opacity =
                  (_iconFadeAnim.value * (1.0 - _revealAnim.value))
                      .clamp(0.0, 1.0);
              return SlideTransition(
                position: _iconSlideAnim,
                child: Opacity(opacity: opacity, child: _buildGlowIcon()),
              );
            },
          ),

          // ── Layer 3: Teks "TAssist" — Poppins w600 + shimmer ─────────────
          AnimatedBuilder(
            animation: Listenable.merge(
                [_textFadeAnim, _textSlideAnim, _shimmerAnim]),
            builder: (_, __) => Center(
              child: SlideTransition(
                position: _textSlideAnim,
                child: Opacity(
                  opacity: _textFadeAnim.value,
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      final double pos = _shimmerAnim.value;
                      return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: const [
                          Colors.white,
                          Color(0xFFD0E8FF),
                          Colors.white,
                          Colors.white,
                        ],
                        stops: [
                          (pos - 0.3).clamp(0.0, 1.0),
                          pos.clamp(0.0, 1.0),
                          (pos + 0.3).clamp(0.0, 1.0),
                          1.0,
                        ],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      'TAssist',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowIcon() {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_glowAnim, _iconScaleAnim]),
        builder: (_, __) => Transform.scale(
          scale: _iconScaleAnim.value,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _blue.withOpacity(0.55 * _glowAnim.value),
                  blurRadius:   40 * _glowAnim.value,
                  spreadRadius: 10 * _glowAnim.value,
                ),
                BoxShadow(
                  color: _blue.withOpacity(0.25 * _glowAnim.value),
                  blurRadius:   80 * _glowAnim.value,
                  spreadRadius: 20 * _glowAnim.value,
                ),
              ],
            ),
            child: const Center(
              child: _GraduationCapIcon(size: 48, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Custom Clipper ───────────────────────────────────────────────────────────

/// Memotong widget menjadi bentuk lingkaran dengan [center] dan [radius]
/// yang bisa berubah setiap frame — digunakan untuk animasi circle reveal.
class _CircleClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  const _CircleClipper({required this.center, required this.radius});

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  bool shouldReclip(covariant _CircleClipper old) =>
      old.radius != radius || old.center != center;
}

// ─── Custom Painter: Graduation Cap ──────────────────────────────────────────

class _GraduationCapIcon extends StatelessWidget {
  final double size;
  final Color  color;

  const _GraduationCapIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _GraduationCapPainter(color: color),
      );
}

class _GraduationCapPainter extends CustomPainter {
  final Color color;
  _GraduationCapPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap  = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // 1. Papan belah ketupat (mortarboard)
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.50, h * 0.12)
        ..lineTo(w * 0.92, h * 0.33)
        ..lineTo(w * 0.50, h * 0.54)
        ..lineTo(w * 0.08, h * 0.33)
        ..close(),
      fill,
    );

    // 2. Badan topi (trapesium)
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.28, h * 0.43)
        ..lineTo(w * 0.72, h * 0.43)
        ..lineTo(w * 0.65, h * 0.72)
        ..lineTo(w * 0.35, h * 0.72)
        ..close(),
      fill,
    );

    // 3. Tali rumbai
    canvas.drawLine(
      Offset(w * 0.92, h * 0.33),
      Offset(w * 0.92, h * 0.60),
      stroke,
    );

    // 4. Lingkaran ujung tali
    canvas.drawCircle(Offset(w * 0.92, h * 0.66), w * 0.055, fill);

    // 5. Titik tengah papan (dekorasi)
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.33),
      w * 0.038,
      Paint()..color = const Color(0xFF1A6EE0),
    );
  }

  @override
  bool shouldRepaint(covariant _GraduationCapPainter old) =>
      old.color != color;
}