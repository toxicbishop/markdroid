import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ConversionCard extends StatelessWidget {
  final bool isConverting;
  final VoidCallback? onTap;

  const ConversionCard({
    super.key,
    required this.isConverting,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isConverting
                ? AppTheme.accent
                : const Color(0xFF1E2D5A),
            width: isConverting ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isConverting
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppTheme.accent,
                      ),
                    )
                  : Container(
                      key: const ValueKey('icon'),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.upload_file_rounded,
                        color: AppTheme.accent,
                        size: 32,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              isConverting ? 'Converting to PDF…' : 'Pick a Markdown file',
              style: const TextStyle(
                color: AppTheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isConverting
                  ? 'This usually takes a second'
                  : 'Supports .md, .markdown, and .txt',
              style: const TextStyle(
                color: AppTheme.onSurfaceMuted,
                fontSize: 13,
              ),
            ),
            if (!isConverting) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _formatBadge('GFM Tables'),
                  const SizedBox(width: 8),
                  _formatBadge('Code blocks'),
                  const SizedBox(width: 8),
                  _formatBadge('Blockquotes'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _formatBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.accent,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
