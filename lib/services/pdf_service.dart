import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:markdown_2_pdf/markdown_2_pdf.dart';
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
      // Step 1: Use native Markdown to PDF rendering instead of HTML/WebView
      // This bypasses the Android WebView which is blocked on Vivo/Oppo devices
      final source = StringMarkdownSource(markdownContent);
      
      final converter = MarkdownToPdfConverter(
        options: PredefinedPdfOptions.defaultOptions.copyWith(
          title: fileName,
        ),
      );

      // Step 2: Convert to bytes directly
      final pdfBytes = await converter.convertToBytes(source);

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
}
