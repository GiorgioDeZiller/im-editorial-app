import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await NotificationService.requestPermissions();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const IMEditorialApp(),
    ),
  );
}

class IMEditorialApp extends StatelessWidget {
  const IMEditorialApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    return MaterialApp(
      title: 'IM Editorial',
      debugShowCheckedModeBanner: false,
      theme: ThemeService.light,
      darkTheme: ThemeService.dark,
      themeMode: themeService.mode,
      home: const HomeScreen(),
    );
  }
}
