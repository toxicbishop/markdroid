import 'package:flutter/material.dart';
import '../main.dart';
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

  Future<void> _updateAppTheme(String val) async {
    final markdroidApp = MarkdroidApp.of(context);
    ThemeMode mode;
    if (val == 'Light') {
      mode = ThemeMode.light;
    } else if (val == 'Dark') {
      mode = ThemeMode.dark;
    } else {
      mode = ThemeMode.system;
    }
    await markdroidApp.setTheme(mode, val);
    if (mounted) setState(() {});
  }

  String _getAppThemeString() {
    final mode = MarkdroidApp.of(context).currentTheme;
    if (mode == ThemeMode.light) return 'Light';
    if (mode == ThemeMode.dark) return 'Dark';
    return 'System';
  }

  @override
  Widget build(BuildContext context) {
    if (_settings == null) {
      return Scaffold(
        backgroundColor: context.appPrimary,
        body: Center(child: CircularProgressIndicator(color: context.appAccent)),
      );
    }

    return Scaffold(
      backgroundColor: context.appPrimary,
      appBar: AppBar(
        title: Text('PDF Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDropdownSection(
            title: 'App Theme',
            value: _getAppThemeString(),
            items: const ['System', 'Light', 'Dark'],
            onChanged: (val) => _updateAppTheme(val!),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'PDF EXPORT',
            style: TextStyle(
              color: context.appAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildDropdownSection(
            title: 'PDF Page Size',
            value: _settings!.pageSize,
            items: const ['A4', 'Letter'],
            onChanged: (val) => _updateSettings(_settings!.copyWith(pageSize: val)),
          ),
          const SizedBox(height: 16),
          _buildDropdownSection(
            title: 'PDF Base Font Size',
            value: _settings!.fontSize.toString(),
            items: const ['10', '12', '14', '16', '18'],
            onChanged: (val) => _updateSettings(_settings!.copyWith(fontSize: int.parse(val!))),
          ),
          const SizedBox(height: 16),
          _buildDropdownSection(
            title: 'PDF Theme',
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
          style: TextStyle(
            color: context.appOnSurfaceMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appOnSurfaceMuted.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: context.appSurfaceVariant,
              icon: Icon(Icons.arrow_drop_down_rounded, color: context.appOnSurfaceMuted),
              style: TextStyle(color: context.appOnSurface, fontSize: 16),
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
