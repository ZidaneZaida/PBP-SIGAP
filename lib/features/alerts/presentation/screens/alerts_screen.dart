import 'peringatan_screen.dart';

export 'peringatan_screen.dart';

/// Wrapper kompatibilitas untuk [PeringatanScreen]
class AlertsScreen extends PeringatanScreen {
  const AlertsScreen({
    super.key,
    super.onNavigateToDashboard,
    super.onNavigateToFamily,
    super.onNavigateToMap,
    super.onTabSelected,
    super.initialEmergencyState = false,
    super.embedded = false,
  });
}
