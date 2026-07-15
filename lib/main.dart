import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('app_theme') ?? 'System';

  runApp(MarkdroidApp(initialTheme: _parseThemeMode(savedTheme)));
}

ThemeMode _parseThemeMode(String value) {
  switch (value) {
    case 'Light':
      return ThemeMode.light;
    case 'Dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

class MarkdroidApp extends StatefulWidget {
  final ThemeMode initialTheme;
  const MarkdroidApp({super.key, required this.initialTheme});

  static _MarkdroidAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MarkdroidAppState>()!;

  @override
  State<MarkdroidApp> createState() => _MarkdroidAppState();
}

class _MarkdroidAppState extends State<MarkdroidApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialTheme;
  }

  Future<void> setTheme(ThemeMode mode, String stringValue) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', stringValue);
  }

  ThemeMode get currentTheme => _themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Markdroid',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: const HomeScreen(),
    );
  }
}
