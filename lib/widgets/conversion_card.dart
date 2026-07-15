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
          color: context.appSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isConverting
                ? context.appAccent
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
                  ? SizedBox(
                      key: const ValueKey('loading'),
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: context.appAccent,
                      ),
                    )
                  : Container(
                      key: const ValueKey('icon'),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: context.appAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.upload_file_rounded,
                        color: context.appAccent,
                        size: 32,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              isConverting ? 'Converting to PDF…' : 'Pick a Markdown file',
              style: TextStyle(
                color: context.appOnSurface,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isConverting
                  ? 'This usually takes a second'
                  : 'Supports .md, .markdown, and .txt',
              style: TextStyle(
                color: context.appOnSurfaceMuted,
                fontSize: 13,
              ),
            ),
            if (!isConverting) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _formatBadge(context, 'GFM Tables'),
                  const SizedBox(width: 8),
                  _formatBadge(context, 'Code blocks'),
                  const SizedBox(width: 8),
                  _formatBadge(context, 'Blockquotes'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _formatBadge(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.appAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.appAccent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: context.appAccent,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
