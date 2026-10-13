import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI style (status bar transparan / merah)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Periksa apakah pengguna sudah memiliki token sesi aktif
  final token = await SecureStorageService.getToken();
  final initialScreen = (token != null && token.isNotEmpty)
      ? const MainNavigationScreen()
      : const LoginScreen();

  runApp(AsklinMobileApp(initialScreen: initialScreen));
}

class AsklinMobileApp extends StatelessWidget {
  final Widget initialScreen;

  const AsklinMobileApp({Key? key, required this.initialScreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASKLIN Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: initialScreen,
    );
  }
}

