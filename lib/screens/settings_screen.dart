import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsService = SettingsService();
  PdfSettings? _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.getSettings();
    setState(() => _settings = settings);
  }

  Future<void> _updateSettings(PdfSettings newSettings) async {
    setState(() => _settings = newSettings);
    await _settingsService.saveSettings(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    if (_settings == null) {
      return const Scaffold(
        backgroundColor: AppTheme.primary,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: const Text('PDF Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDropdownSection(
            title: 'Page Size',
            value: _settings!.pageSize,
            items: const ['A4', 'Letter'],
            onChanged: (val) => _updateSettings(_settings!.copyWith(pageSize: val)),
          ),
          const SizedBox(height: 16),
          _buildDropdownSection(
            title: 'Base Font Size',
            value: _settings!.fontSize.toString(),
            items: const ['10', '12', '14', '16', '18'],
            onChanged: (val) => _updateSettings(_settings!.copyWith(fontSize: int.parse(val!))),
          ),
          const SizedBox(height: 16),
          _buildDropdownSection(
            title: 'Theme',
            value: _settings!.theme,
            items: const ['Light', 'Dark'],
            onChanged: (val) => _updateSettings(_settings!.copyWith(theme: val)),
          ),
          const SizedBox(height: 16),
          _buildDropdownSection(
            title: 'Margins',
            value: _settings!.margins,
            items: const ['Normal (25.4mm)', 'Narrow (12.7mm)'],
            onChanged: (val) => _updateSettings(_settings!.copyWith(margins: val)),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSection({
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.onSurfaceMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E2D5A)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppTheme.surfaceVariant,
              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.onSurfaceMuted),
              style: const TextStyle(color: AppTheme.onSurface, fontSize: 16),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
