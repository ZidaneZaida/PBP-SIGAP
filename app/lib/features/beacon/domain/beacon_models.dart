/// Status kesiapan BLE Beacon secara jujur (tidak pernah mengklaim radio BLE
/// aktif selama plugin BLE peripheral native belum terintegrasi).
enum BleReadinessStatus {
  pluginPendingPermissionGranted,
  permissionRequired,
  permanentlyDenied,
  unavailableOnPlatform;

  String get badgeLabel {
    switch (this) {
      case BleReadinessStatus.pluginPendingPermissionGranted:
        return 'IZIN BLE SIAP (MENUNGGU PLUGIN RADIO)';
      case BleReadinessStatus.permissionRequired:
        return 'IZIN BLUETOOTH BELUM AKTIF';
      case BleReadinessStatus.permanentlyDenied:
        return 'IZIN BLUETOOTH DITOLAK PERMANEN';
      case BleReadinessStatus.unavailableOnPlatform:
        return 'BLE TIDAK TERSEDIA DI PLATFORM INI';
    }
  }

  String get detailMessage {
    switch (this) {
      case BleReadinessStatus.pluginPendingPermissionGranted:
        return 'Izin BLE Siap — Transmisi Radio BLE Menunggu Integrasi Plugin Native. '
            'Payload darurat sudah terbentuk dan siap dipancarkan setelah plugin BLE peripheral terpasang.';
      case BleReadinessStatus.permissionRequired:
        return 'Izin Bluetooth (Advertise & Connect) belum diberikan. '
            'Aktifkan izin untuk menyiapkan kesiapan perangkat; transmisi radio BLE tetap menunggu plugin native.';
      case BleReadinessStatus.permanentlyDenied:
        return 'Izin Bluetooth ditolak permanen pada sistem. '
            'Buka Pengaturan Aplikasi untuk mengaktifkan izin Bluetooth.';
      case BleReadinessStatus.unavailableOnPlatform:
        return 'Platform ini tidak mendukung kontrol izin BLE seluler. '
            'Gunakan strobo visual layar dan panggilan suara SOS offline.';
    }
  }
}

/// Ringkasan status izin perangkat yang relevan untuk layar Suar SOS Offline.
class BeaconPermissionSnapshot {
  final bool cameraGranted;
  final bool cameraPermanentlyDenied;
  final bool bluetoothAdvertiseGranted;
  final bool bluetoothConnectGranted;
  final bool bluetoothPermanentlyDenied;
  final bool platformSupported;

  const BeaconPermissionSnapshot({
    this.cameraGranted = false,
    this.cameraPermanentlyDenied = false,
    this.bluetoothAdvertiseGranted = false,
    this.bluetoothConnectGranted = false,
    this.bluetoothPermanentlyDenied = false,
    this.platformSupported = true,
  });

  bool get isBluetoothPermissionGranted =>
      bluetoothAdvertiseGranted && bluetoothConnectGranted;

  BleReadinessStatus get bleReadinessStatus {
    if (!platformSupported) {
      return BleReadinessStatus.unavailableOnPlatform;
    }
    if (bluetoothPermanentlyDenied) {
      return BleReadinessStatus.permanentlyDenied;
    }
    if (isBluetoothPermissionGranted) {
      return BleReadinessStatus.pluginPendingPermissionGranted;
    }
    return BleReadinessStatus.permissionRequired;
  }

  BeaconPermissionSnapshot copyWith({
    bool? cameraGranted,
    bool? cameraPermanentlyDenied,
    bool? bluetoothAdvertiseGranted,
    bool? bluetoothConnectGranted,
    bool? bluetoothPermanentlyDenied,
    bool? platformSupported,
  }) {
    return BeaconPermissionSnapshot(
      cameraGranted: cameraGranted ?? this.cameraGranted,
      cameraPermanentlyDenied:
          cameraPermanentlyDenied ?? this.cameraPermanentlyDenied,
      bluetoothAdvertiseGranted:
          bluetoothAdvertiseGranted ?? this.bluetoothAdvertiseGranted,
      bluetoothConnectGranted:
          bluetoothConnectGranted ?? this.bluetoothConnectGranted,
      bluetoothPermanentlyDenied:
          bluetoothPermanentlyDenied ?? this.bluetoothPermanentlyDenied,
      platformSupported: platformSupported ?? this.platformSupported,
    );
  }
}

/// Payload data SOS darurat ringkas siap dibaca Tim SAR atau disalurkan saat
/// modul pemancar BLE/SMS offline aktif.
class OfflineSosPayload {
  final String beaconId;
  final double latitude;
  final double longitude;
  final bool isFallbackLocation;
  final DateTime generatedAt;
  final String statusText;

  const OfflineSosPayload({
    required this.beaconId,
    required this.latitude,
    required this.longitude,
    required this.isFallbackLocation,
    required this.generatedAt,
    required this.statusText,
  });

  /// Menghasilkan string payload ringkas dan deterministik yang mudah disalin
  /// atau dibaca petugas SAR.
  String toCompactPayloadString() {
    final utc = generatedAt.toUtc();
    final yyyy = utc.year.toString().padLeft(4, '0');
    final mm = utc.month.toString().padLeft(2, '0');
    final dd = utc.day.toString().padLeft(2, '0');
    final hh = utc.hour.toString().padLeft(2, '0');
    final min = utc.minute.toString().padLeft(2, '0');
    final sec = utc.second.toString().padLeft(2, '0');
    final timestamp = '$yyyy-$mm-${dd}T$hh:$min:${sec}Z';

    final latStr = latitude.toStringAsFixed(5);
    final lngStr = longitude.toStringAsFixed(5);
    final source = isFallbackLocation ? 'EST' : 'GPS';
    final cleanStatus = statusText.replaceAll('|', '/').trim();

    return 'SIGAP-SOS|ID:$beaconId|LOC:$latStr,$lngStr|SRC:$source|UTC:$timestamp|MSG:$cleanStatus';
  }
}
