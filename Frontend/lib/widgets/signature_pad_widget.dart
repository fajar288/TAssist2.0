// lib/widgets/signature_pad_widget.dart

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:tassist/widgets/app_snackbars.dart';

import '../theme/app_theme.dart';

class SignaturePadWidget extends StatefulWidget {
  final ValueChanged<Uint8List> onSigned;
  final VoidCallback? onCancel;

  const SignaturePadWidget({
    super.key,
    required this.onSigned,
    this.onCancel,
  });

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  final List<List<Offset>> _lines = [];
  bool _isProcessing = false;

  void _clear() {
    setState(() {
      _lines.clear();
    });
  }

  Future<void> _exportSignature() async {
    if (_lines.isEmpty) {
      AppSnackBars.error(
        context,
        'Silakan goreskan tanda tangan Anda terlebih dahulu.',
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final recorder = ui.PictureRecorder();
      const canvasWidth = 400.0;
      const canvasHeight = 200.0;
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
      );

      // Transparent or white background
      final paintBg = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, canvasWidth, canvasHeight), paintBg);

      final paintStroke = Paint()
        ..color = Colors.black
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (final line in _lines) {
        if (line.isEmpty) continue;
        final path = Path();
        path.moveTo(line.first.dx, line.first.dy);
        for (int i = 1; i < line.length; i++) {
          path.lineTo(line[i].dx, line[i].dy);
        }
        canvas.drawPath(path, paintStroke);
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(canvasWidth.toInt(), canvasHeight.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        widget.onSigned(byteData.buffer.asUint8List());
      }
    } catch (e) {
      if (mounted) {
        AppSnackBars.error(context, 'Gagal mengekspor tanda tangan: $e');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tanda Tangan Digital',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                onPressed: _lines.isEmpty ? null : _clear,
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Bersihkan',
                color: AppTheme.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Bubuhkan tanda tangan Anda pada area di bawah ini:',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: _lines.isNotEmpty ? AppTheme.primary : AppTheme.cardBorder,
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _lines.add([details.localPosition]);
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    if (_lines.isNotEmpty) {
                      _lines.last.add(details.localPosition);
                    }
                  });
                },
                child: CustomPaint(
                  painter: _SignaturePainter(_lines),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.onCancel != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppTheme.cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                    ),
                    child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                ),
              if (widget.onCancel != null) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _exportSignature,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                  ),
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Gunakan Tanda Tangan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> lines;

  _SignaturePainter(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw guide line for signing
    final guidePaint = Paint()
      ..color = AppTheme.cardBorder
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(20, size.height * 0.75),
      Offset(size.width - 20, size.height * 0.75),
      guidePaint,
    );

    final strokePaint = Paint()
      ..color = AppTheme.textPrimary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final line in lines) {
      if (line.isEmpty) continue;
      final path = Path();
      path.moveTo(line.first.dx, line.first.dy);
      for (int i = 1; i < line.length; i++) {
        path.lineTo(line[i].dx, line[i].dy);
      }
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
