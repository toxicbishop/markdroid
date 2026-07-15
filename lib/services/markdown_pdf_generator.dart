import 'dart:io';
import 'package:markdown/markdown.dart' as md;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:highlight/highlight.dart' show highlight, Node;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'settings_service.dart';

class MarkdownPdfGenerator {
  late pw.Font _regularFont;
  late pw.Font _boldFont;
  late pw.Font _italicFont;
  late pw.Font _monoFont;

  static const _tokenColors = {
    'keyword': PdfColor.fromInt(0xFFCC99CD),
    'string': PdfColor.fromInt(0xFF7EC699),
    'comment': PdfColor.fromInt(0xFF999999),
    'number': PdfColor.fromInt(0xFFF08D49),
    'function': PdfColor.fromInt(0xFF6196CC),
    'class': PdfColor.fromInt(0xFFE8BF6A),
    'operator': PdfColor.fromInt(0xFF67CDBE),
    'punctuation': PdfColor.fromInt(0xFFCDD3DE),
  };

  static const _codeBgColor = PdfColor.fromInt(0xFF1E1E1E);

  late PdfColor _textColor;
  late PdfColor _codeTextColor;
  late double _baseFontSize;

  Future<void> _initFonts() async {
    _regularFont = await PdfGoogleFonts.robotoRegular();
    _boldFont = await PdfGoogleFonts.robotoBold();
    _italicFont = await PdfGoogleFonts.robotoItalic();
    _monoFont = await PdfGoogleFonts.robotoMonoRegular();
  }

  Future<File> generatePdf(String markdownText, String fileName) async {
    await _initFonts();

    final settings = await SettingsService().getSettings();
    _baseFontSize = settings.fontSize.toDouble();
    _textColor = settings.theme == 'Dark' ? PdfColors.white : PdfColors.black;
    _codeTextColor = PdfColors.white;

    final document = md.Document(extensionSet: md.ExtensionSet.gitHubFlavored);
    final nodes = document.parse(markdownText);

    final pdf = pw.Document();

    final marginValue = settings.margins.contains('Narrow')
        ? 12.7 * PdfPageFormat.mm
        : 25.4 * PdfPageFormat.mm;
    final pageFormat =
        settings.pageSize == 'Letter' ? PdfPageFormat.letter : PdfPageFormat.a4;
    final backgroundColor = settings.theme == 'Dark'
        ? PdfColor.fromInt(0xFF121212)
        : PdfColors.white;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(marginValue),
        pageTheme: pw.PageTheme(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.all(marginValue),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: backgroundColor),
          ),
        ),
        build: (context) {
          return _buildNodes(nodes);
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final safeName =
        fileName.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_');
    final file = File('${dir.path}/$safeName.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  List<pw.Widget> _buildNodes(List<md.Node> nodes) {
    final widgets = <pw.Widget>[];
    for (var node in nodes) {
      final widget = _buildNode(node);
      if (widget != null) {
        widgets.add(widget);
      }
    }
    return widgets;
  }

  pw.Widget? _buildNode(md.Node node) {
    if (node is md.Element) {
      return _buildElement(node);
    } else if (node is md.Text) {
      return pw.Text(node.text,
          style: pw.TextStyle(
              font: _regularFont, color: _textColor, fontSize: _baseFontSize));
    }
    return null;
  }

  pw.Widget? _buildElement(md.Element element) {
    switch (element.tag) {
      case 'h1':
        return _buildHeading(element.textContent, 28);
      case 'h2':
        return _buildHeading(element.textContent, 24);
      case 'h3':
        return _buildHeading(element.textContent, 20);
      case 'h4':
        return _buildHeading(element.textContent, 18);
      case 'h5':
        return _buildHeading(element.textContent, 16);
      case 'h6':
        return _buildHeading(element.textContent, 14);
      case 'p':
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.RichText(text: _buildRichText(element)),
        );
      case 'pre':
      case 'code':
        return _buildCodeBlock(element);
      case 'ul':
        return _buildList(element, false);
      case 'ol':
        return _buildList(element, true);
      case 'blockquote':
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.only(left: 12, top: 4, bottom: 4),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
                left: pw.BorderSide(color: PdfColors.grey400, width: 4)),
          ),
          child: pw.RichText(
            text: _buildRichText(element,
                style:
                    pw.TextStyle(font: _italicFont, color: PdfColors.grey700)),
          ),
        );
      case 'hr':
        return pw.Divider(color: PdfColors.grey400);
      case 'table':
        return _buildTable(element);
      default:
        return pw.RichText(text: _buildRichText(element));
    }
  }

  pw.Widget _buildHeading(String text, double size) {
    final scaledSize = size + (_baseFontSize - 12);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
      child: pw.Text(text,
          style: pw.TextStyle(
              font: _boldFont, fontSize: scaledSize, color: _textColor)),
    );
  }

  pw.TextSpan _buildRichText(md.Node node, {pw.TextStyle? style}) {
    if (node is md.Text) {
      return pw.TextSpan(
          text: node.text,
          style: style ??
              pw.TextStyle(
                  font: _regularFont,
                  color: _textColor,
                  fontSize: _baseFontSize));
    } else if (node is md.Element) {
      switch (node.tag) {
        case 'strong':
        case 'b':
          return _buildRichTextChildren(node.children,
              style: style?.copyWith(font: _boldFont) ??
                  pw.TextStyle(
                      font: _boldFont,
                      color: _textColor,
                      fontSize: _baseFontSize));
        case 'em':
        case 'i':
          return _buildRichTextChildren(node.children,
              style: style?.copyWith(font: _italicFont) ??
                  pw.TextStyle(
                      font: _italicFont,
                      color: _textColor,
                      fontSize: _baseFontSize));
        case 'code':
          return pw.TextSpan(
            text: node.textContent,
            style: style?.copyWith(
                  font: _monoFont,
                  color: const PdfColor.fromInt(0xFFEF4444),
                  background: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF3F4F6),
                  ),
                ) ??
                pw.TextStyle(
                  font: _monoFont,
                  fontSize: _baseFontSize - 1,
                  color: const PdfColor.fromInt(0xFFEF4444),
                  background: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF3F4F6),
                  ),
                ),
          );
        case 'a':
          return _buildRichTextChildren(node.children,
              style: style?.copyWith(
                      color: PdfColors.blue,
                      decoration: pw.TextDecoration.underline) ??
                  pw.TextStyle(
                    font: _regularFont,
                    fontSize: _baseFontSize,
                    color: PdfColors.blue,
                    decoration: pw.TextDecoration.underline,
                  ));
        default:
          return _buildRichTextChildren(node.children, style: style);
      }
    }
    return const pw.TextSpan();
  }

  pw.TextSpan _buildRichTextChildren(List<md.Node>? children,
      {pw.TextStyle? style}) {
    if (children == null) return const pw.TextSpan();
    return pw.TextSpan(
      children: children.map((c) => _buildRichText(c, style: style)).toList(),
    );
  }

  pw.Widget _buildCodeBlock(md.Element element) {
    // Extract language from class (e.g. "language-dart")
    String? language;
    String codeText = element.textContent;

    if (element.tag == 'pre' && element.children?.isNotEmpty == true) {
      final codeElement = element.children!.first;
      if (codeElement is md.Element && codeElement.tag == 'code') {
        final className = codeElement.attributes['class'];
        if (className != null && className.startsWith('language-')) {
          language = className.substring('language-'.length);
        }
        codeText = codeElement.textContent;
      }
    } else if (element.tag == 'code') {
      final className = element.attributes['class'];
      if (className != null && className.startsWith('language-')) {
        language = className.substring('language-'.length);
      }
    }

    List<pw.TextSpan> spans = [];
    if (language != null) {
      final highlighted = highlight.parse(codeText, language: language);
      spans = _convertHighlightNodes(highlighted.nodes);
    } else {
      spans = [
        pw.TextSpan(
            text: codeText,
            style: pw.TextStyle(font: _monoFont, color: _codeTextColor))
      ];
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _codeBgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.RichText(text: pw.TextSpan(children: spans)),
    );
  }

  List<pw.TextSpan> _convertHighlightNodes(List<Node>? nodes) {
    if (nodes == null) return [];
    final spans = <pw.TextSpan>[];
    for (final node in nodes) {
      if (node.value != null) {
        final color = _tokenColors[node.className] ?? _codeTextColor;
        spans.add(pw.TextSpan(
          text: node.value,
          style: pw.TextStyle(font: _monoFont, color: color),
        ));
      } else if (node.children != null) {
        // Nested nodes inherit the parent's class color if they don't have their own
        final color = _tokenColors[node.className] ?? _codeTextColor;
        for (final child in node.children!) {
          if (child.value != null) {
            final childColor = _tokenColors[child.className] ?? color;
            spans.add(pw.TextSpan(
              text: child.value,
              style: pw.TextStyle(font: _monoFont, color: childColor),
            ));
          } else if (child.children != null) {
            spans.addAll(_convertHighlightNodes(child.children));
          }
        }
      }
    }
    return spans;
  }

  pw.Widget _buildList(md.Element list, bool isOrdered) {
    final items = <pw.Widget>[];
    int index = 1;
    for (final li in list.children ?? []) {
      if (li is md.Element && li.tag == 'li') {
        items.add(pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 20,
              padding: const pw.EdgeInsets.only(right: 8),
              child: pw.Text(
                isOrdered ? '$index.' : '•',
                style: pw.TextStyle(font: _regularFont),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.RichText(text: _buildRichText(li)),
              ),
            ),
          ],
        ));
        index++;
      }
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8, left: 16),
      child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start, children: items),
    );
  }

  pw.Widget _buildTable(md.Element table) {
    final rows = <pw.TableRow>[];
    for (final child in table.children ?? []) {
      if (child is md.Element &&
          (child.tag == 'thead' || child.tag == 'tbody')) {
        for (final tr in child.children ?? []) {
          if (tr is md.Element && tr.tag == 'tr') {
            final cells = <pw.Widget>[];
            for (final td in tr.children ?? []) {
              if (td is md.Element && (td.tag == 'td' || td.tag == 'th')) {
                final isHeader = td.tag == 'th';
                cells.add(pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.RichText(
                    text: _buildRichText(td,
                        style: pw.TextStyle(
                          font: isHeader ? _boldFont : _regularFont,
                        )),
                  ),
                ));
              }
            }
            if (cells.isNotEmpty) {
              rows.add(pw.TableRow(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300)),
                ),
                children: cells,
              ));
            }
          }
        }
      }
    }
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        children: rows,
      ),
    );
  }
}
