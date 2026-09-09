import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:salah/models/app_settings.dart';

/// Renders the keepsake page to an image and saves it: a PNG to the gallery, or
/// a PDF shared out (e.g. to Drive). Web (preview) always shares the PDF.
class ExportService {
  /// Capture the widget behind [key] as PNG bytes. Returns null if the boundary
  /// isn't mounted yet.
  Future<Uint8List?> capturePng(GlobalKey key, {double pixelRatio = 3}) async {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;
    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  /// Save [png] according to [target]. Returns a short message describing what
  /// happened, for a confirmation to the user.
  Future<String> save({
    required Uint8List png,
    required ExportTarget target,
    required String dateKey,
  }) async {
    if (kIsWeb) {
      await _sharePdf(png, dateKey);
      return 'Opened your day to download.';
    }
    return switch (target) {
      ExportTarget.pngGallery => _saveToGallery(png, dateKey),
      ExportTarget.pdfDrive => _sharePdfAnd(png, dateKey),
    };
  }

  Future<String> _saveToGallery(Uint8List png, String dateKey) async {
    await Gal.putImageBytes(png, name: 'salah-$dateKey');
    return 'Saved to your gallery.';
  }

  Future<String> _sharePdfAnd(Uint8List png, String dateKey) async {
    await _sharePdf(png, dateKey);
    return 'Ready to save to Drive.';
  }

  Future<void> _sharePdf(Uint8List png, String dateKey) async {
    final doc = pw.Document();
    final image = pw.MemoryImage(png);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
      ),
    );
    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: 'salah-$dateKey.pdf');
  }
}
