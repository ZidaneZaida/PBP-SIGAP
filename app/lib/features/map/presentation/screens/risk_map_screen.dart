import 'peta_screen.dart';

export 'peta_screen.dart';

/// Wrapper kompatibilitas untuk [PetaScreen]
class RiskMapScreen extends PetaScreen {
  const RiskMapScreen({
    super.key,
    super.onNavigateToDashboard,
    super.onNavigateToAlerts,
    super.onNavigateToFamily,
    super.onTabSelected,
    super.embedded = false,
  });
}
