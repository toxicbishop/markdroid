import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import '../services/file_service.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';
import '../widgets/conversion_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/history_tile.dart';
import 'preview_screen.dart';
import 'editor_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _fileService = FileService();
  final _pdfService = PdfService();

  bool _isConverting = false;
  String? _lastConvertedPath;
  List<FileSystemEntry> _history = [];

  static const MethodChannel _intentChannel = MethodChannel('markdroid/intent');

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _intentChannel.setMethodCallHandler((call) async {
      if (call.method == 'openFile') {
        final String path = call.arguments;
        _handleIncomingFile(path);
      }
    });
  }

  Future<void> _handleIncomingFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return;

    final content = await file.readAsString();
    final stat = await file.stat();

    final pickedFile = PickedMarkdownFile(
      content: content,
      fileName: path.split('/').last,
      filePath: path,
      sizeBytes: stat.size,
    );

    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditorScreen(initialFile: pickedFile),
      ),
    );

    if (result is ConversionResult &&
        result.success &&
        result.outputPath != null) {
      setState(() => _lastConvertedPath = result.outputPath);
      await _loadHistory();
      _showSuccessSheet(result.outputPath!);
    }
  }

  Future<void> _loadHistory() async {
    final files = await _pdfService.listConvertedPdfs();
    setState(() {
      _history = files.map((f) => FileSystemEntry(path: f.path)).toList();
    });
  }

  Future<void> _pickAndConvert() async {
    final files = await _fileService.pickMultipleMarkdownFiles();
    setState(() => _isConverting = false);

    if (files.isEmpty) return;

    if (files.length == 1) {
      await _processSingleFile(files.first);
      return;
    }

    // Batch mode
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text('Batch Conversion',
            style: TextStyle(color: context.appOnSurface)),
        content: Text('Convert ${files.length} files to PDF?',
            style: TextStyle(color: context.appOnSurfaceMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(color: context.appOnSurfaceMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: context.appAccent,
                foregroundColor: Colors.white),
            child: const Text('Convert All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isConverting = true);

    // show progress dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: context.appSurface,
          content: Row(
            children: [
              CircularProgressIndicator(color: context.appAccent),
              const SizedBox(width: 20),
              Text('Converting ${files.length} files...',
                  style: TextStyle(color: context.appOnSurface)),
            ],
          ),
        ),
      );
    }

    int successCount = 0;
    for (var file in files) {
      final result = await _pdfService.convertMarkdownToPdf(
        markdownContent: file.content,
        fileName: file.nameWithoutExtension,
      );
      if (result.success) successCount++;
    }

    // Hide progress dialog
    if (mounted) Navigator.pop(context);

    setState(() => _isConverting = false);

    await _loadHistory();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Successfully converted $successCount of ${files.length} files',
              style: TextStyle(color: context.appOnSurface)),
          backgroundColor: context.appSurfaceVariant,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _processSingleFile(PickedMarkdownFile file) async {
    final proceed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PreviewScreen(file: file)),
    );

    if (proceed != true) return;

    setState(() => _isConverting = true);

    final result = await _pdfService.convertMarkdownToPdf(
      markdownContent: file.content,
      fileName: file.nameWithoutExtension,
    );

    setState(() => _isConverting = false);

    if (!mounted) return;

    if (result.success && result.outputPath != null) {
      setState(() => _lastConvertedPath = result.outputPath);
      await _loadHistory();
      _showSuccessSheet(result.outputPath!);
    } else {
      _showError(result.error ?? 'Conversion failed');
    }
  }

  Future<void> _showUrlImportDialog() async {
    final textController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text('Import from URL',
            style: TextStyle(color: context.appOnSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              style: TextStyle(color: context.appOnSurface),
              decoration: InputDecoration(
                hintText: 'https://raw.githubusercontent.com/...',
                hintStyle: TextStyle(color: context.appOnSurfaceMuted),
                filled: true,
                fillColor: context.appSurfaceVariant,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null) {
                  textController.text = data!.text!;
                }
              },
              icon:
                  Icon(Icons.paste_rounded, color: context.appAccent, size: 18),
              label: Text('Paste from Clipboard',
                  style: TextStyle(color: context.appAccent)),
              style: OutlinedButton.styleFrom(
                side:
                    BorderSide(color: context.appAccent.withValues(alpha: 0.5)),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: context.appOnSurfaceMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _importFromUrl(textController.text.trim());
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: context.appAccent,
                foregroundColor: Colors.white),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromUrl(String url) async {
    if (url.isEmpty) return;
    setState(() => _isConverting = true);
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final content = response.body;
        var fileName = url
            .split('/')
            .lastWhere((e) => e.isNotEmpty, orElse: () => 'document')
            .replaceAll(RegExp(r'[^\w\s\-\.]'), '');
        if (fileName.isEmpty) fileName = 'document.md';
        if (!fileName.endsWith('.md')) fileName += '.md';

        final file = PickedMarkdownFile(
          content: content,
          nameWithoutExtension: fileName.substring(0, fileName.length - 3),
          fileName: fileName,
          sizeFormatted: '${(content.length / 1024).toStringAsFixed(1)} KB',
        );
        setState(() => _isConverting = false);
        await _processSingleFile(file);
      } else {
        setState(() => _isConverting = false);
        _showError('Failed to load URL: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isConverting = false);
      _showError('Network error: $e');
    }
  }

  void _showSuccessSheet(String path) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Icon(Icons.check_circle_rounded,
                  color: context.appSuccess, size: 52),
            ),
            const SizedBox(height: 16),
            Text(
              'PDF created successfully',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appOnSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              path.split('/').last,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appOnSurfaceMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pdfService.openPdf(path);
                    },
                    icon: Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text('Open'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pdfService.sharePdf(path);
                    },
                    icon: Icon(Icons.share_rounded, size: 18),
                    label: Text('Share'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final r = await _pdfService.saveToDownloads(path);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      r.success
                          ? 'Saved to Downloads'
                          : 'Could not save to Downloads',
                    ),
                    backgroundColor:
                        r.success ? context.appSuccess : context.appError,
                  ),
                );
              },
              child: Text(
                'Save to Downloads',
                style: TextStyle(color: context.appOnSurfaceMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $message'),
        backgroundColor: context.appError,
      ),
    );
  }

  void _showActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.appOnSurfaceMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.appAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.edit_note_rounded, color: context.appAccent),
              ),
              title: Text(
                'New File',
                style: TextStyle(
                  color: context.appOnSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Create and edit with built-in editor',
                style:
                    TextStyle(color: context.appOnSurfaceMuted, fontSize: 13),
              ),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditorScreen()),
                );
                if (result is ConversionResult &&
                    result.success &&
                    result.outputPath != null) {
                  setState(() => _lastConvertedPath = result.outputPath);
                  await _loadHistory();
                  _showSuccessSheet(result.outputPath!);
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.appAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(Icons.file_upload_rounded, color: context.appAccent),
              ),
              title: Text(
                'Import .md',
                style: TextStyle(
                  color: context.appOnSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Pick one or multiple Markdown files',
                style:
                    TextStyle(color: context.appOnSurfaceMuted, fontSize: 13),
              ),
              onTap: () {
                Navigator.pop(context);
                if (!_isConverting) _pickAndConvert();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.appAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.link_rounded, color: context.appAccent),
              ),
              title: Text(
                'Import from URL',
                style: TextStyle(
                  color: context.appOnSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Download Markdown from GitHub or web',
                style:
                    TextStyle(color: context.appOnSurfaceMuted, fontSize: 13),
              ),
              onTap: () {
                Navigator.pop(context);
                if (!_isConverting) _showUrlImportDialog();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Mark',
              style: TextStyle(color: context.appOnSurface),
            ),
            Text(
              'droid',
              style: TextStyle(color: context.appAccent),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          if (_history.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear history',
              onPressed: _confirmClearHistory,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        color: context.appAccent,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: ConversionCard(
                  isConverting: _isConverting,
                  onTap: _isConverting ? null : _pickAndConvert,
                ),
              ),
            ),
            if (_history.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: const EmptyState(),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Text(
                        'CONVERTED FILES',
                        style: TextStyle(
                          color: context.appOnSurfaceMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_history.length} file${_history.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: context.appOnSurfaceMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => HistoryTile(
                      entry: _history[i],
                      isNew: _history[i].path == _lastConvertedPath,
                      onOpen: () => _pdfService.openPdf(_history[i].path),
                      onShare: () => _pdfService.sharePdf(_history[i].path),
                      onDelete: () async {
                        final ok =
                            await _pdfService.deletePdf(_history[i].path);
                        if (ok) await _loadHistory();
                      },
                    ),
                    childCount: _history.length,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'main_action',
        onPressed: _isConverting ? null : _showActionSheet,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: _isConverting
              ? const SizedBox(
                  key: ValueKey('converting'),
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(Icons.add_rounded, key: ValueKey('add'), size: 28),
        ),
      ),
    );
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(
          'Clear all PDFs?',
          style: TextStyle(color: context.appOnSurface),
        ),
        content: Text(
          'This will delete all converted PDFs from app storage. Files saved to Downloads are unaffected.',
          style: TextStyle(color: context.appOnSurfaceMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              for (final f in _history) {
                await _pdfService.deletePdf(f.path);
              }
              await _loadHistory();
            },
            child:
                Text('Delete all', style: TextStyle(color: context.appError)),
          ),
        ],
      ),
    );
  }
}

class FileSystemEntry {
  final String path;
  String get name => path.split('/').last;
  FileSystemEntry({required this.path});
}
