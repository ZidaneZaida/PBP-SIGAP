import 'home_screen.dart';

export 'home_screen.dart';

/// Alias / Wrapper untuk [HomeScreen] untuk kompatibilitas mundur.
class DashboardScreen extends HomeScreen {
  const DashboardScreen({
    super.key,
    super.userName = 'Warga Padang',
    super.initialEmergencyState = false,
    super.initialTsunamiWarning = true,
  });
}
