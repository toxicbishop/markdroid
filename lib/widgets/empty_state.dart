import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF1E2D5A),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: AppTheme.onSurfaceMuted,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No conversions yet',
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pick a .md file and it will be\nconverted to a shareable PDF.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.onSurfaceMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
