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
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNew
              ? context.appAccent.withValues(alpha: 0.5)
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
                color: context.appError.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.picture_as_pdf_rounded,
                color: context.appError,
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
                  decoration: BoxDecoration(
                    color: context.appSuccess,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          entry.name,
          style: TextStyle(
            color: context.appOnSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$size • $modified',
          style: TextStyle(
            color: context.appOnSurfaceMuted,
            fontSize: 12,
          ),
        ),
        trailing: PopupMenuButton<String>(
          color: context.appSurfaceVariant,
          icon: Icon(Icons.more_vert_rounded, color: context.appOnSurfaceMuted),
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
            _menuItem(context, 'open', Icons.open_in_new_rounded, 'Open'),
            _menuItem(context, 'share', Icons.share_rounded, 'Share'),
            _menuItem(context, 'delete', Icons.delete_outline_rounded, 'Delete',
                color: context.appError),
          ],
        ),
        onTap: onOpen,
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    BuildContext context,
    String value,
    IconData icon,
    String label, {
    Color? color,
  }) {
    color ??= context.appOnSurface;
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
