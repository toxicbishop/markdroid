import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/file_service.dart';
import '../theme/app_theme.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:markdown/markdown.dart' as md;

class CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    String language = '';
    if (element.attributes['class'] != null &&
        element.attributes['class']!.startsWith('language-')) {
      language = element.attributes['class']!.substring(9);
    }

    // Fallback for inline code (no language, single line)
    if (language.isEmpty && !element.textContent.contains('\n')) {
      return null; // let flutter_markdown handle it as inline code
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: HighlightView(
        element.textContent,
        language: language.isEmpty ? 'plaintext' : language,
        theme: atomOneDarkTheme,
        padding: const EdgeInsets.all(16),
        textStyle: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
        ),
      ),
    );
  }
}

class PreviewScreen extends StatefulWidget {
  final PickedMarkdownFile file;

  const PreviewScreen({super.key, required this.file});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appPrimary,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.file.fileName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              widget.file.sizeFormatted,
              style: TextStyle(
                fontSize: 12,
                color: context.appOnSurfaceMuted,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: context.appAccent,
          labelColor: context.appAccent,
          unselectedLabelColor: context.appOnSurfaceMuted,
          tabs: const [
            Tab(text: 'Preview'),
            Tab(text: 'Source'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Rendered markdown preview
                Container(
                  color: Colors.white,
                  child: Markdown(
                    data: widget.file.content,
                    builders: {
                      'code': CodeElementBuilder(),
                    },
                    styleSheet: MarkdownStyleSheet(
                      h1: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                      h2: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1f2937),
                      ),
                      h3: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                      p: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF374151),
                        height: 1.6,
                      ),
                      code: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Color(0xFFdc2626),
                        backgroundColor: Color(0xFFf3f4f6),
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: const Color(0xFF1e293b),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      blockquote: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1e40af),
                        fontStyle: FontStyle.italic,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        color: const Color(0xFFeff6ff),
                        border: Border(
                          left: BorderSide(
                            color: context.appAccent,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                  ),
                ),
                // Raw source view
                Container(
                  color: const Color(0xFF0d1117),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      widget.file.content,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Color(0xFFe6edf3),
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom action bar
          Container(
            color: context.appSurface,
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text('Convert to PDF'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
