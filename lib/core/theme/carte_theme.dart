import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

/// Palette et identité visuelle de la carte membre (écran + PDF).
abstract final class CarteTheme {
  // ── Asset ─────────────────────────────────────────────────────────────────
  static const String logoTogoAsset =
      'assets/images/logo_republique_togolaise.png';

  // ── Identité institution ──────────────────────────────────────────────────
  static const String institutionName = 'ENTREPRENARIAT & DÉVELOPPEMENT';
  static const String institutionShort = 'ED';
  static const String cardSubtitle = 'CARTE MEMBRE';
  static const String orgQr = 'Entreprenariat-et-Developpement';

  // ── Dégradé carte (vert Togo officiel) ────────────────────────────────────
  static const Color greenStart = Color(0xFF006A4E);
  static const Color greenMid = Color(0xFF008751);
  static const Color greenEnd = Color(0xFF00A060);

  static const List<Color> gradientColors = [greenStart, greenMid, greenEnd];

  static const LinearGradient cardGradient = LinearGradient(
    colors: gradientColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color goldAccent = Color(0xFFFFCE00);

  static const LinearGradient logoGradient = LinearGradient(
    colors: [greenStart, greenEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── PDF (mêmes teintes) ───────────────────────────────────────────────────
  static const PdfColor pdfGreen1 = PdfColor.fromInt(0xFF006A4E);
  static const PdfColor pdfGreen2 = PdfColor.fromInt(0xFF008751);
  static const PdfColor pdfGreen3 = PdfColor.fromInt(0xFF00A060);
  static const List<PdfColor> pdfGradient = [pdfGreen1, pdfGreen2, pdfGreen3];

  static const PdfColor white = PdfColors.white;
  static const PdfColor white75 = PdfColor(1, 1, 1, 0.75);
  static const PdfColor white60 = PdfColor(1, 1, 1, 0.60);
  static const PdfColor white25 = PdfColor(1, 1, 1, 0.25);
  static const PdfColor white15 = PdfColor(1, 1, 1, 0.15);
  static const PdfColor white14 = PdfColor(1, 1, 1, 0.14);

  // ── Dimensions ISO 7810 ───────────────────────────────────────────────────
  static const double isoRatio = 54.0 / 85.6;
  static const double maxPreviewWidth = 520;
  static const double pdfCardW = 85.6 * 2.834;
  static const double pdfCardH = 54.0 * 2.834;

  static double borderRadius(double height) => height * 0.045;
  static double innerBorderRadius(double height) => borderRadius(height) - 1.2;

  static BoxShadow cardShadow(double height) => BoxShadow(
        color: greenStart.withValues(alpha: 0.35),
        blurRadius: height * 0.20,
        spreadRadius: height * 0.02,
        offset: Offset(0, height * 0.08),
      );
}
