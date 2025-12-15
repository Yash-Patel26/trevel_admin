import 'package:flutter/material.dart';
import 'package:trevel_customer/features/splash/presentation/pages/splash_page.dart';
import 'core/theme/theme_manager.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  runApp(const TrevelCustomerApp());
}

class TrevelCustomerApp extends StatelessWidget {
  const TrevelCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Trevel Customer',
          themeMode: ThemeManager.instance.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
            scaffoldBackgroundColor: Colors.black, // Matching existing design
            cardColor: Colors.white,
            useMaterial3: true,
            fontFamily: 'Jost',
            iconTheme: const IconThemeData(color: Colors.black),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.black),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
            scaffoldBackgroundColor: Colors.black,
            cardColor: Colors.grey[900], // Darker card for dark mode
            useMaterial3: true,
            fontFamily: 'Jost',
             iconTheme: const IconThemeData(color: Colors.white),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.white),
            ),
          ),
          home: const SplashPage(),
        );
      },
    );
  }
}
