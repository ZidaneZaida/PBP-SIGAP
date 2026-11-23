import 'package:flutter/material.dart';
import 'core/network/token_manager.dart';
import 'core/theme/app_colors.dart';
import 'features/splash/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isLoggedIn = await TokenManager.isLoggedIn();
  final user = await TokenManager.getUserData();
  final userName = user?['full_name'] as String? ?? 'Warga Padang';

  runApp(SigapApp(
    isUserLoggedIn: isLoggedIn,
    userName: userName,
  ));
}

class SigapApp extends StatelessWidget {
  final bool isUserLoggedIn;
  final String userName;

  const SigapApp({
    super.key,
    this.isUserLoggedIn = false,
    this.userName = 'Warga Padang',
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIGAP - Siaga Bencana Kota Padang',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.backgroundCream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryDark,
          primary: AppColors.primary,
          secondary: AppColors.mintAccent,
          surface: AppColors.backgroundCream,
          brightness: Brightness.light,
        ),
      ),
      home: SplashScreen(
        isUserLoggedIn: isUserLoggedIn,
        userName: userName,
      ),
    );
  }
}
