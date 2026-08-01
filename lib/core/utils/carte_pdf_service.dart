import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' show GlobalKey;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/carte_model.dart';
import '../../data/repositories/fichier_repository.dart';
import '../theme/carte_theme.dart';
import 'app_logger.dart';

/// Génère un PDF contenant **uniquement** la carte membre (format ISO 7810),
/// prête à imprimer et découper pour remise au client.
class CartePdfService {
  CartePdfService._();

  /// Résolution cible pour l'impression (~300 dpi sur 85,6 mm).
  static const double _printWidthPx = 1011;

  /// Point d'entrée principal : capture le rendu Flutter à l'écran si possible,
  /// sinon reconstruit une carte propre sans décorations débordantes.
  static Future<Uint8List> genererPdf(
    CarteModel carte, {
    GlobalKey? cardKey,
  }) async {
    if (cardKey != null) {
      await Future.delayed(const Duration(milliseconds: 50));
      final png = await _captureCardImage(cardKey);
      if (png != null) return _pdfCarteSeule(png);
    }
    return _genererPdfFallback(carte);
  }

  /// Capture la carte affichée à l'écran (WYSIWYG).
  static Future<Uint8List?> _captureCardImage(GlobalKey key) async {
    try {
      final ctx = key.currentContext;
      if (ctx == null) return null;
      final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final cardWidth = boundary.size.width;
      final pixelRatio = (_printWidthPx / cardWidth).clamp(2.0, 4.0);

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } catch (e, stackTrace) {
      AppLogger.error('Capture de la carte en image échouée', e, stackTrace);
      return null;
    }
  }

  /// PDF = une page exactement à la taille de la carte, image plein format.
  static Future<Uint8List> _pdfCarteSeule(Uint8List pngBytes) async {
    final pdf = pw.Document();
    const format = PdfPageFormat(
      CarteTheme.pdfCardW,
      CarteTheme.pdfCardH,
      marginAll: 0,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.SizedBox(
          width: format.width,
          height: format.height,
          child: pw.Image(
            pw.MemoryImage(pngBytes),
            width: format.width,
            height: format.height,
            fit: pw.BoxFit.fill,
          ),
        ),
      ),
    );

    return pdf.save();
  }

  // ─── Fallback vectoriel (sans Stack / cercles débordants) ────────────────

  static Future<Uint8List> _genererPdfFallback(CarteModel carte) async {
    final pdf      = pw.Document();
    final qrBytes  = _decodeBase64(carte.qrCodeBase64);
    final font     = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final logoTogo = await _loadAsset(CarteTheme.logoTogoAsset);

    Uint8List? photoBytes;
    if (carte.cheminPhoto.isNotEmpty) {
      photoBytes = await _fetchBytes(FichierRepository.urlPhoto(carte.cheminPhoto));
    }

    const format = PdfPageFormat(
      CarteTheme.pdfCardW,
      CarteTheme.pdfCardH,
      marginAll: 0,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        build: (_) => _buildCardFlat(
          font, fontBold, carte, qrBytes, photoBytes, logoTogo,
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildCardFlat(
      pw.Font font, pw.Font bold,
      CarteModel carte, Uint8List? qrBytes, Uint8List? photoBytes,
      Uint8List logoTogo) {
    const w = CarteTheme.pdfCardW;
    const h = CarteTheme.pdfCardH;
    const radius = 7.0;
    const padH = 10.0;
    const padV = 8.0;

    final photoH = h * 0.38;
    final photoW = photoH * 0.75;
    const badgeSize = 22.0;
    const togoH = 28.0;
    const qrSize = 36.0;

    return pw.ClipRRect(
      horizontalRadius: radius,
      verticalRadius: radius,
      child: pw.Container(
        width: w,
        height: h,
        decoration: const pw.BoxDecoration(
          gradient: pw.LinearGradient(
            colors: CarteTheme.pdfGradient,
            begin: pw.Alignment.topLeft,
            end: pw.Alignment.bottomRight,
          ),
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── En-tête ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                _buildTogoLogo(logoTogo, togoH),
                pw.SizedBox(width: 4),
                _buildLogoBadge(bold, badgeSize),
                pw.SizedBox(width: 5),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                       pw.Text('ENTREPRENARIAT &',
                          style: pw.TextStyle(
                              font: bold, fontSize: 7,
                              color: CarteTheme.white, letterSpacing: 0.4)),
                       pw.Text('DÉVELOPPEMENT',
                          style: pw.TextStyle(
                              font: bold, fontSize: 7,
                              color: CarteTheme.white, letterSpacing: 0.4)),
                       pw.SizedBox(height: 1),
                       // Ligne or
                       pw.Container(
                         height: 1.2,
                         width: double.infinity,
                         color: const PdfColor(1.0, 0.808, 0.0, 0.80),
                       ),
                       pw.SizedBox(height: 1),
                       pw.Text(CarteTheme.cardSubtitle,
                          style: pw.TextStyle(
                              font: font, fontSize: 5.5,
                              color: const PdfColor(1.0, 0.808, 0.0, 0.92),
                              letterSpacing: 1.8)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 4),
                _buildQrBox(qrBytes, qrSize),
              ],
            ),
            // Séparateur
            pw.SizedBox(height: 3),
            pw.Container(height: 0.8, color: const PdfColor(1.0, 0.808, 0.0, 0.55)),
            pw.Spacer(),

            // ── Pied : photo + identité ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  width: photoW,
                  height: photoH,
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: CarteTheme.white60, width: 1),
                    color: CarteTheme.white15,
                  ),
                  child: photoBytes != null
                      ? pw.ClipRRect(
                          horizontalRadius: 3,
                          verticalRadius: 3,
                          child: pw.Image(pw.MemoryImage(photoBytes),
                              fit: pw.BoxFit.cover))
                      : pw.Center(
                          child: pw.Text('PHOTO',
                              style: pw.TextStyle(
                                  font: font, fontSize: 6,
                                  color: CarteTheme.white60))),
                ),
                pw.SizedBox(width: 7),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(carte.nomComplet.toUpperCase(),
                          style: pw.TextStyle(
                              font: bold, fontSize: 8.5,
                              color: CarteTheme.white),
                          maxLines: 2),
                      pw.SizedBox(height: 2),
                      pw.Container(height: 0.6, color: CarteTheme.white25),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: _cardField(font, bold, 'N° MEMBRE',
                                carte.numeroMembre,
                                labelSize: 4.5, valueSize: 6.2, monospace: true),
                          ),
                          pw.SizedBox(width: 4),
                          pw.Expanded(
                            child: _cardField(font, bold, 'N° CLIENT',
                                carte.numeroClient,
                                labelSize: 4.5, valueSize: 6.2, monospace: true),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 1.5),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: _cardField(font, bold, 'EXPIRE',
                                _shortDate(carte.dateExpiration),
                                labelSize: 4.2, valueSize: 6),
                          ),
                          pw.SizedBox(width: 4),
                          pw.Expanded(
                            child: _cardField(
                                font, bold, 'TÉL.',
                                carte.telephone.isNotEmpty ? carte.telephone : '—',
                                labelSize: 4.2, valueSize: 6,
                                align: pw.CrossAxisAlignment.end),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTogoLogo(Uint8List bytes, double height) {
    return pw.Container(
      width: height * 0.75,
      height: height,
      decoration: pw.BoxDecoration(
        color: CarteTheme.white,
        borderRadius: pw.BorderRadius.circular(height * 0.10),
        border: pw.Border.all(
          color: const PdfColor(1.0, 0.808, 0.0, 0.50), // or
          width: 0.8,
        ),
      ),
      padding: pw.EdgeInsets.all(height * 0.05),
      child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
    );
  }

  static pw.Widget _buildLogoBadge(pw.Font bold, double size) {
    final r = size * 0.16;
    const goldPdf = PdfColor(1.0, 0.808, 0.0, 1.0); // #FFCE00
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: const [
            PdfColor(0.106, 0.478, 0.306),  // #1B7A4E
            PdfColor(0.0, 0.565, 0.376),    // #009060
            PdfColor(0.0, 0.690, 0.439),    // #00B070
          ],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: pw.BorderRadius.circular(r),
        border: pw.Border.all(
          color: const PdfColor(1.0, 0.808, 0.0, 0.65),
          width: size * 0.04,
        ),
      ),
      child: pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              CarteTheme.institutionShort,
              style: pw.TextStyle(
                font: bold,
                fontSize: size * 0.48,
                color: goldPdf,
                letterSpacing: 1.5,
              ),
            ),
            pw.SizedBox(height: size * 0.03),
            pw.Container(
              width: size * 0.65,
              height: size * 0.025,
              color: const PdfColor(1.0, 0.808, 0.0, 0.60),
            ),
            pw.SizedBox(height: size * 0.03),
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(horizontal: size * 0.06),
              child: pw.Text(
                'MICROFINANCE',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: bold,
                  fontSize: size * 0.13,
                  color: const PdfColor(1, 1, 1, 0.92),
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildQrBox(Uint8List? qrBytes, double size) {
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        color: CarteTheme.white,
        borderRadius: pw.BorderRadius.circular(size * 0.08),
      ),
      padding: const pw.EdgeInsets.all(2),
      child: qrBytes != null
          ? pw.Image(pw.MemoryImage(qrBytes), fit: pw.BoxFit.contain)
          : pw.SizedBox.shrink(),
    );
  }

  static pw.Widget _cardField(
      pw.Font font, pw.Font bold,
      String label, String value, {
        required double labelSize,
        required double valueSize,
        pw.CrossAxisAlignment align = pw.CrossAxisAlignment.start,
        bool monospace = false,
      }) {
    return pw.Column(
      crossAxisAlignment: align,
      children: [
        pw.Text(label,
            style: pw.TextStyle(font: font, fontSize: labelSize,
                color: CarteTheme.white60, letterSpacing: 0.6)),
        pw.Text(value,
            style: pw.TextStyle(
              font: monospace ? pw.Font.courierBold() : bold,
              fontSize: valueSize,
              color: CarteTheme.white,
            ),
            maxLines: 1),
      ],
    );
  }

  static Future<Uint8List> _loadAsset(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }

  static Future<Uint8List?> _fetchBytes(String url) async {
    if (url.isEmpty) return null;
    try {
      final res = await Dio().get<List<int>>(url,
          options: Options(responseType: ResponseType.bytes));
      if (res.statusCode == 200 && res.data != null) {
        return Uint8List.fromList(res.data!);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.warning('Téléchargement de $url échoué', e, stackTrace);
      return null;
    }
  }

  static Uint8List? _decodeBase64(String b64) {
    try {
      return base64Decode(b64);
    } catch (e, stackTrace) {
      AppLogger.warning('Photo base64 illisible', e, stackTrace);
      return null;
    }
  }

  static String _shortDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.month.toString().padLeft(2,'0')}/${d.year}';
    } catch (_) { return iso; }
  }
}
