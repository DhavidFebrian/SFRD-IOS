import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/state/app_state_provider.dart';
import 'main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ],
      child: const SfrdApp(),
    ),
  );
}

class SfrdApp extends StatelessWidget {
  const SfrdApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final activeTheme = AppTheme.buildTheme(
      style: state.selectedThemeStyle,
      isDark: state.isDarkTheme,
    );

    return MaterialApp(
      title: 'RWC - Media Production',
      debugShowCheckedModeBanner: false,
      theme: activeTheme,
      darkTheme: activeTheme,
      themeMode: state.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: const MainScreen(),
    );
  }
}
