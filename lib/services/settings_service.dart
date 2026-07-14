import 'package:shared_preferences/shared_preferences.dart';

class PdfSettings {
  final String pageSize; // 'A4', 'Letter'
  final int fontSize; // 12, 14, 16
  final String theme; // 'Light', 'Dark'
  final String margins; // 'Normal (25.4mm)', 'Narrow (12.7mm)'

  PdfSettings({
    required this.pageSize,
    required this.fontSize,
    required this.theme,
    required this.margins,
  });

  PdfSettings copyWith({
    String? pageSize,
    int? fontSize,
    String? theme,
    String? margins,
  }) {
    return PdfSettings(
      pageSize: pageSize ?? this.pageSize,
      fontSize: fontSize ?? this.fontSize,
      theme: theme ?? this.theme,
      margins: margins ?? this.margins,
    );
  }
}

class SettingsService {
  static const _keyPageSize = 'pdf_page_size';
  static const _keyFontSize = 'pdf_font_size';
  static const _keyTheme = 'pdf_theme';
  static const _keyMargins = 'pdf_margins';

  Future<PdfSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return PdfSettings(
      pageSize: prefs.getString(_keyPageSize) ?? 'A4',
      fontSize: prefs.getInt(_keyFontSize) ?? 14,
      theme: prefs.getString(_keyTheme) ?? 'Light',
      margins: prefs.getString(_keyMargins) ?? 'Normal (25.4mm)',
    );
  }

  Future<void> saveSettings(PdfSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPageSize, settings.pageSize);
    await prefs.setInt(_keyFontSize, settings.fontSize);
    await prefs.setString(_keyTheme, settings.theme);
    await prefs.setString(_keyMargins, settings.margins);
  }
}
