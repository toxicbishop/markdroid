import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme/app_theme.dart';
import '../services/file_service.dart';
import '../services/pdf_service.dart';

class EditorScreen extends StatefulWidget {
  final PickedMarkdownFile? initialFile;

  const EditorScreen({super.key, this.initialFile});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _textController;
  late FocusNode _focusNode;

  final _pdfService = PdfService();
  bool _isConverting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _textController = TextEditingController(text: widget.initialFile?.content ?? '');
    _focusNode = FocusNode();
    
    // Auto focus on edit if it's a new file
    if (widget.initialFile == null) {
      _focusNode.requestFocus();
    }
    
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        // hide keyboard when switching to preview
        _focusNode.unfocus();
        setState(() {}); // refresh preview
      } else {
        setState(() {}); // to show toolbar again
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _insertText(String prefix, [String suffix = '']) {
    final text = _textController.text;
    final selection = _textController.selection;
    
    if (selection.start == -1) {
      _textController.text = text + prefix + suffix;
      _textController.selection = TextSelection.collapsed(
          offset: _textController.text.length - suffix.length);
      return;
    }

    final start = selection.start;
    final end = selection.end;
    final selectedText = text.substring(start, end);
    
    final newText = text.replaceRange(start, end, '$prefix$selectedText$suffix');
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + prefix.length + selectedText.length),
    );
  }

  Future<void> _convertToPdf() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot convert empty file'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isConverting = true);

    String fileName = widget.initialFile?.nameWithoutExtension ?? 'Untitled';
    if (widget.initialFile == null) {
      // Prompt for filename
      final name = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController(text: fileName);
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text('Save PDF as', style: TextStyle(color: AppTheme.onSurface)),
            content: TextField(
              controller: controller,
              style: const TextStyle(color: AppTheme.onSurface),
              decoration: const InputDecoration(
                hintText: 'Filename',
                hintStyle: TextStyle(color: AppTheme.onSurfaceMuted),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accent)),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
      if (name == null || name.isEmpty) {
        setState(() => _isConverting = false);
        return;
      }
      fileName = name;
    }

    final result = await _pdfService.convertMarkdownToPdf(
      markdownContent: _textController.text,
      fileName: fileName,
    );

    setState(() => _isConverting = false);

    if (!mounted) return;
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: Text(widget.initialFile?.fileName ?? 'New Document'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.onSurfaceMuted,
          tabs: const [
            Tab(text: 'Edit'),
            Tab(text: 'Preview'),
          ],
        ),
        actions: [
          IconButton(
            icon: _isConverting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent))
                : const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.accent),
            onPressed: _isConverting ? null : _convertToPdf,
            tooltip: 'Convert to PDF',
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Edit Tab
                Container(
                  color: const Color(0xFF0d1117),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: Color(0xFFe6edf3),
                      height: 1.5,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Type markdown here...',
                      hintStyle: TextStyle(color: Color(0xFF484f58)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
                // Preview Tab
                Container(
                  color: Colors.white,
                  child: Markdown(
                    data: _textController.text,
                    styleSheet: MarkdownStyleSheet(
                      h1: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                      h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1f2937)),
                      h3: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                      p: const TextStyle(fontSize: 15, color: Color(0xFF374151), height: 1.6),
                      code: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Color(0xFFdc2626), backgroundColor: Color(0xFFf3f4f6)),
                      codeblockDecoration: BoxDecoration(color: const Color(0xFF1e293b), borderRadius: BorderRadius.circular(8)),
                      blockquote: const TextStyle(fontSize: 15, color: Color(0xFF1e40af), fontStyle: FontStyle.italic),
                      blockquoteDecoration: const BoxDecoration(
                        color: Color(0xFFeff6ff),
                        border: Border(left: BorderSide(color: AppTheme.accent, width: 4)),
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                  ),
                ),
              ],
            ),
          ),
          // Markdown Toolbar
          if (_tabController.index == 0) // Only show in Edit mode
            Container(
              color: AppTheme.surface,
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : MediaQuery.of(context).padding.bottom),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    _ToolbarButton(icon: Icons.format_bold_rounded, tooltip: 'Bold', onPressed: () => _insertText('**', '**')),
                    _ToolbarButton(icon: Icons.format_italic_rounded, tooltip: 'Italic', onPressed: () => _insertText('*', '*')),
                    _ToolbarButton(icon: Icons.strikethrough_s_rounded, tooltip: 'Strikethrough', onPressed: () => _insertText('~~', '~~')),
                    Container(width: 1, height: 24, color: AppTheme.onSurfaceMuted.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 4)),
                    _ToolbarButton(icon: Icons.title_rounded, tooltip: 'Heading 1', onPressed: () => _insertText('# ')),
                    _ToolbarButton(icon: Icons.format_size_rounded, tooltip: 'Heading 2', onPressed: () => _insertText('## ')),
                    Container(width: 1, height: 24, color: AppTheme.onSurfaceMuted.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 4)),
                    _ToolbarButton(icon: Icons.format_list_bulleted_rounded, tooltip: 'Bulleted List', onPressed: () => _insertText('- ')),
                    _ToolbarButton(icon: Icons.format_list_numbered_rounded, tooltip: 'Numbered List', onPressed: () => _insertText('1. ')),
                    _ToolbarButton(icon: Icons.check_box_outline_blank_rounded, tooltip: 'Task List', onPressed: () => _insertText('- [ ] ')),
                    Container(width: 1, height: 24, color: AppTheme.onSurfaceMuted.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 4)),
                    _ToolbarButton(icon: Icons.code_rounded, tooltip: 'Code', onPressed: () => _insertText('`', '`')),
                    _ToolbarButton(icon: Icons.data_object_rounded, tooltip: 'Code Block', onPressed: () => _insertText('\n```\n', '\n```\n')),
                    _ToolbarButton(icon: Icons.format_quote_rounded, tooltip: 'Quote', onPressed: () => _insertText('> ')),
                    _ToolbarButton(icon: Icons.link_rounded, tooltip: 'Link', onPressed: () => _insertText('[', '](url)')),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolbarButton({required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: AppTheme.onSurfaceMuted, size: 22),
      tooltip: tooltip,
      onPressed: onPressed,
      splashRadius: 20,
    );
  }
}
