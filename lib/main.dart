import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/key_storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize secure storage service
  await KeyStorageService.instance.initialize();
  
  runApp(const AirGappedVaultApp());
}

class AirGappedVaultApp extends StatelessWidget {
  const AirGappedVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Air Gapped Vault',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
