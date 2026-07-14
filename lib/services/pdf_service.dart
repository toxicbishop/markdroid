import 'dart:io';
import 'package:markdown/markdown.dart' as md;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'settings_service.dart';
class ConversionResult {
  final bool success;
  final String? outputPath;
  final String? error;

  ConversionResult({required this.success, this.outputPath, this.error});
}

class PdfService {
  /// Converts markdown string to PDF and saves to app documents directory.
  Future<ConversionResult> convertMarkdownToPdf({
    required String markdownContent,
    required String fileName,
  }) async {
    try {
      final settings = await SettingsService().getSettings();
      
      // Step 1: Parse markdown → HTML
      final html = md.markdownToHtml(
        markdownContent,
        extensionSet: md.ExtensionSet.gitHubWeb,
      );

      // Step 2: Wrap with minimal CSS for clean PDF output
      final styledHtml = _wrapWithStyles(html, fileName, settings);

      final format = settings.pageSize == 'Letter' ? PdfPageFormat.letter : PdfPageFormat.a4;

      // Step 3: Convert HTML → PDF bytes via Chromium/WebView renderer
      // ignore: deprecated_member_use
      final pdfBytes = await Printing.convertHtml(
        format: format,
        html: styledHtml,
      );

      // Step 4: Save PDF to disk
      final outputDir = await getApplicationDocumentsDirectory();
      final safeName = fileName
          .replaceAll(RegExp(r'[^\w\s\-]'), '')
          .replaceAll(' ', '_');
      final outputPath = '${outputDir.path}/$safeName.pdf';
      final file = File(outputPath);
      await file.writeAsBytes(pdfBytes);

      return ConversionResult(success: true, outputPath: outputPath);
    } catch (e) {
      return ConversionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Share the PDF file using system share sheet
  Future<void> sharePdf(String filePath) async {
    final file = XFile(filePath);
    await Share.shareXFiles(
      [file],
      subject: 'Converted PDF',
      text: 'PDF converted by Markdroid',
    );
  }

  /// Open the PDF with an external viewer
  Future<void> openPdf(String filePath) async {
    await OpenFile.open(filePath);
  }

  /// Save PDF to Downloads folder (Android)
  Future<ConversionResult> saveToDownloads(String sourcePath) async {
    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        // Fallback to external storage root
        final extDir = await getExternalStorageDirectory();
        if (extDir == null) throw Exception('External storage unavailable');
        final dest = '${extDir.path}/${sourcePath.split('/').last}';
        await File(sourcePath).copy(dest);
        return ConversionResult(success: true, outputPath: dest);
      }
      final dest = '${downloadsDir.path}/${sourcePath.split('/').last}';
      await File(sourcePath).copy(dest);
      return ConversionResult(success: true, outputPath: dest);
    } catch (e) {
      return ConversionResult(success: false, error: e.toString());
    }
  }

  /// List all previously converted PDFs
  Future<List<FileSystemEntity>> listConvertedPdfs() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir
        .listSync()
        .where((f) => f.path.endsWith('.pdf'))
        .toList()
      ..sort((a, b) {
        final aStat = File(a.path).statSync();
        final bStat = File(b.path).statSync();
        return bStat.modified.compareTo(aStat.modified);
      });
    return files;
  }

  /// Delete a PDF file
  Future<bool> deletePdf(String path) async {
    try {
      await File(path).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  String _wrapWithStyles(String html, String title, PdfSettings settings) {
    final isDark = settings.theme == 'Dark';
    final bg = isDark ? '#1a1a1a' : '#ffffff';
    final text = isDark ? '#e5e7eb' : '#1a1a1a';
    final h1 = isDark ? '#ffffff' : '#111111';
    final h2 = isDark ? '#f3f4f6' : '#1f2937';
    final border = isDark ? '#374151' : '#e5e7eb';
    final preBg = isDark ? '#111827' : '#1e293b';
    final preText = isDark ? '#e5e7eb' : '#e2e8f0';
    
    final padding = settings.margins.startsWith('Normal') ? '96px' : '48px';
    final baseSize = settings.fontSize;

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>$title</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, 'Segoe UI', Arial, sans-serif;
      font-size: ${baseSize}px;
      line-height: 1.7;
      color: $text;
      background-color: $bg;
      padding: $padding;
      max-width: 100%;
    }
    h1 { font-size: ${baseSize + 14}px; font-weight: 700; margin: 0 0 16px; color: $h1; border-bottom: 2px solid $border; padding-bottom: 10px; }
    h2 { font-size: ${baseSize + 8}px; font-weight: 600; margin: 28px 0 12px; color: $h2; border-bottom: 1px solid $border; padding-bottom: 6px; }
    h3 { font-size: ${baseSize + 4}px; font-weight: 600; margin: 22px 0 8px; color: $h2; }
    h4, h5, h6 { font-size: ${baseSize + 1}px; font-weight: 600; margin: 16px 0 6px; color: $h2; }
    p { margin: 0 0 14px; }
    ul, ol { margin: 0 0 14px 24px; }
    li { margin: 4px 0; }
    code {
      font-family: 'Courier New', monospace;
      font-size: ${baseSize - 1.5}px;
      background: ${isDark ? '#374151' : '#f3f4f6'};
      border: 1px solid $border;
      border-radius: 4px;
      padding: 1px 5px;
      color: ${isDark ? '#f87171' : '#dc2626'};
    }
    pre {
      background: $preBg;
      color: $preText;
      border-radius: 8px;
      padding: 16px;
      margin: 0 0 16px;
      overflow-x: auto;
    }
    pre code {
      background: none;
      border: none;
      color: inherit;
      padding: 0;
      font-size: ${baseSize - 1.5}px;
    }
    blockquote {
      border-left: 4px solid #4F8EF7;
      background: ${isDark ? '#1e3a8a' : '#eff6ff'};
      padding: 12px 16px;
      margin: 0 0 16px;
      border-radius: 0 6px 6px 0;
      color: ${isDark ? '#bfdbfe' : '#1e40af'};
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 0 0 16px;
      font-size: ${baseSize - 1}px;
    }
    th {
      background: ${isDark ? '#374151' : '#f9fafb'};
      border: 1px solid $border;
      padding: 10px 14px;
      text-align: left;
      font-weight: 600;
    }
    td {
      border: 1px solid $border;
      padding: 8px 14px;
    }
    tr:nth-child(even) td { background: ${isDark ? '#374151' : '#f9fafb'}; }
    a { color: #4F8EF7; text-decoration: none; }
    hr { border: none; border-top: 1px solid $border; margin: 24px 0; }
    img { max-width: 100%; height: auto; border-radius: 6px; }
    strong { font-weight: 600; }
    em { font-style: italic; }
  </style>
</head>
<body>
$html
</body>
</html>''';
  }
}
