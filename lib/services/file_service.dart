import 'dart:io';
import 'package:file_picker/file_picker.dart';

class PickedMarkdownFile {
  final String content;
  final String fileName;
  final String filePath;
  final int sizeBytes;

  PickedMarkdownFile({
    required this.content,
    required this.fileName,
    required this.filePath,
    required this.sizeBytes,
  });

  String get nameWithoutExtension => fileName.endsWith('.md')
      ? fileName.substring(0, fileName.length - 3)
      : fileName;

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024)
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class FileService {
  /// Pick a .md file from device storage
  Future<PickedMarkdownFile?> pickMarkdownFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'markdown', 'txt'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final pickedFile = result.files.first;
    if (pickedFile.path == null) return null;

    final file = File(pickedFile.path!);
    final content = await file.readAsString();
    final stat = await file.stat();

    return PickedMarkdownFile(
      content: content,
      fileName: pickedFile.name,
      filePath: pickedFile.path!,
      sizeBytes: stat.size,
    );
  }

  /// Pick multiple .md files
  Future<List<PickedMarkdownFile>> pickMultipleMarkdownFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'markdown', 'txt'],
      allowMultiple: true,
    );

    if (result == null) return [];

    final files = <PickedMarkdownFile>[];
    for (final pickedFile in result.files) {
      if (pickedFile.path == null) continue;
      final file = File(pickedFile.path!);
      final content = await file.readAsString();
      final stat = await file.stat();
      files.add(PickedMarkdownFile(
        content: content,
        fileName: pickedFile.name,
        filePath: pickedFile.path!,
        sizeBytes: stat.size,
      ));
    }
    return files;
  }
}
