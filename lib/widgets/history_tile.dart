import 'dart:io';
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../theme/app_theme.dart';

class HistoryTile extends StatelessWidget {
  final FileSystemEntry entry;
  final bool isNew;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const HistoryTile({
    super.key,
    required this.entry,
    required this.isNew,
    required this.onOpen,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(entry.path);
    final stat = file.existsSync() ? file.statSync() : null;
    final size = stat != null ? _formatSize(stat.size) : '—';
    final modified = stat != null ? _formatDate(stat.modified) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNew
              ? AppTheme.accent.withOpacity(0.5)
              : const Color(0xFF1E2D5A),
          width: isNew ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: Stack(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: AppTheme.error,
                size: 22,
              ),
            ),
            if (isNew)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          entry.name,
          style: const TextStyle(
            color: AppTheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$size • $modified',
          style: const TextStyle(
            color: AppTheme.onSurfaceMuted,
            fontSize: 12,
          ),
        ),
        trailing: PopupMenuButton<String>(
          color: AppTheme.surfaceVariant,
          icon: const Icon(Icons.more_vert_rounded, color: AppTheme.onSurfaceMuted),
          onSelected: (value) {
            switch (value) {
              case 'open':
                onOpen();
                break;
              case 'share':
                onShare();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (_) => [
            _menuItem('open', Icons.open_in_new_rounded, 'Open'),
            _menuItem('share', Icons.share_rounded, 'Share'),
            _menuItem('delete', Icons.delete_outline_rounded, 'Delete',
                color: AppTheme.error),
          ],
        ),
        onTap: onOpen,
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    Color color = AppTheme.onSurface,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color, fontSize: 14)),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
