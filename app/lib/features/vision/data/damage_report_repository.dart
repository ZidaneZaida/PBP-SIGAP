import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sigap/core/network/api_client.dart';
import 'package:sigap/core/network/api_config.dart';
import 'package:sigap/core/network/token_manager.dart';
import '../domain/models/damage_models.dart';
import 'damage_report_local_store.dart';

/// Exception saat penyimpanan lokal laporan gagal.
class DamageStorageException implements Exception {
  final String message;
  const DamageStorageException(this.message);

  @override
  String toString() => message;
}

/// Exception saat mengambil riwayat laporan dari server gagal.
///
/// Dipisahkan dari [DamageStorageException] agar UI dapat membedakan masalah
/// jaringan/sesi (riwayat lokal tetap tampil) dari kerusakan penyimpanan.
class DamageSyncException implements Exception {
  final String message;
  final bool needsLogin;

  const DamageSyncException(this.message, {this.needsLogin = false});

  @override
  String toString() => message;
}

/// Hasil pengecekan & upaya sinkronisasi antrean laporan lokal.
class VisionSyncCheckResult {
  final bool hasInternet;
  final bool backendEndpointAvailable;
  final int pendingCount;
  final int syncedCount;
  final int skippedNoLocationCount;
  final String message;

  const VisionSyncCheckResult({
    required this.hasInternet,
    required this.backendEndpointAvailable,
    required this.pendingCount,
    this.syncedCount = 0,
    this.skippedNoLocationCount = 0,
    required this.message,
  });
}

/// Signature fungsi pengirim sinkronisasi laporan ke backend (dapat diinjeksi saat test).
typedef DamageReportSyncUploader = Future<void> Function(
  DamageScanReport report,
  Map<String, dynamic> payload,
);

/// Repository penyimpanan lokal laporan SIGAP-Vision berbasis SQLite (`sqflite`)
/// dengan salinan berkas foto persisten serta listener auto-sync berbasis
/// `connectivity_plus`.
///
/// Prinsip kejujuran sinkronisasi:
/// - Laporan baru selalu disimpan lokal dengan status `pendingSync` (bukan `synced`).
/// - Status hanya berubah menjadi `synced` (dengan `syncedAt` terisi) setelah
///   server mengembalikan respons HTTP sukses (2xx) pada `POST /api/damage-reports/`.
class DamageReportRepository {
  static const String storageKey =
      SqfliteDamageReportStore.legacySharedPrefsKey;
  static const String _imagesDirName = 'sigap_vision_reports';

  static final DamageReportRepository instance = DamageReportRepository();

  /// Notifier reaktif agar Beranda, Hub SIGAP-Vision, dan Riwayat selalu sinkron.
  final ValueNotifier<List<DamageScanReport>> reportsNotifier =
      ValueNotifier<List<DamageScanReport>>(<DamageScanReport>[]);

  final Future<Directory?> Function()? directoryProvider;
  final Future<bool> Function()? internetChecker;
  final bool simulateStorageFailure;
  final DamageReportLocalStore _store;
  final Stream<List<ConnectivityResult>>? connectivityStream;
  final Future<List<ConnectivityResult>> Function()? connectivityChecker;
  final Future<String?> Function()? accessTokenProvider;
  final DamageReportSyncUploader? syncUploader;
  final bool autoStartOnUse;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  DamageReportRepository({
    this.directoryProvider,
    this.internetChecker,
    this.simulateStorageFailure = false,
    DamageReportLocalStore? localStore,
    this.connectivityStream,
    this.connectivityChecker,
    this.accessTokenProvider,
    this.syncUploader,
    this.autoStartOnUse = true,
  }) : _store = localStore ?? ResilientDamageReportStore();

  /// Menandakan apakah proses sinkronisasi sedang berlangsung.
  bool get isSyncing => _isSyncing;

  /// Menandakan apakah listener auto-sync konektivitas sedang aktif.
  bool get isAutoSyncActive => _connectivitySubscription != null;

  /// Membangun payload JSON sesuai kontrak Django `POST /api/damage-reports/`
  /// (Revisi Zidan Bagian 4 & 5).
  ///
  /// `client_report_id` ikut dikirim agar retry antrean offline bersifat
  /// idempoten di server: laporan yang sudah diterima tidak dibuat ganda.
  ///
  /// Mengembalikan `null` bila laporan tidak memiliki koordinat GPS valid agar
  /// aplikasi tidak pernah mengirim koordinat fiktif ke server.
  static Map<String, dynamic>? buildSyncPayload(DamageScanReport report) {
    final loc = report.location;
    if (loc == null) return null;

    return {
      'client_report_id': report.id,
      'latitude': loc.latitude,
      'longitude': loc.longitude,
      'damage_level': report.result.category.apiDamageLevel,
      'confidence_score': report.result.confidenceScore ?? 0.0,
      'description': report.result.summary,
    };
  }

  /// Mengaktifkan listener perubahan konektivitas (`connectivity_plus` v7)
  /// secara idempoten. Aman dipanggil berulang dan tidak melempar error pada
  /// lingkungan pengujian tanpa plugin native.
  void startAutoSync() {
    if (_connectivitySubscription != null) return;

    try {
      final stream =
          connectivityStream ?? Connectivity().onConnectivityChanged;
      _connectivitySubscription = stream.listen(
        (results) {
          final isOnline = results.any((r) => r != ConnectivityResult.none);
          if (isOnline && !_isSyncing) {
            unawaited(_handleConnectivityRestored());
          }
        },
        onError: (_) {
          // Tangani MissingPluginException / PlatformException secara aman
          _connectivitySubscription = null;
        },
        cancelOnError: true,
      );
    } on MissingPluginException {
      _connectivitySubscription = null;
    } on PlatformException {
      _connectivitySubscription = null;
    } catch (_) {
      _connectivitySubscription = null;
    }
  }

  /// Menghentikan listener auto-sync konektivitas secara bersih.
  Future<void> stopAutoSync() async {
    final sub = _connectivitySubscription;
    _connectivitySubscription = null;
    if (sub != null) {
      try {
        await sub.cancel();
      } catch (_) {
        // Abaikan error pembatalan stream
      }
    }
  }

  Future<void> _handleConnectivityRestored() async {
    if (_isSyncing || simulateStorageFailure) return;
    try {
      final reports = await _store.getAll();
      final hasPending =
          reports.any((r) => r.syncStatus == DamageSyncStatus.pendingSync);
      if (!hasPending) return;
      await checkAndAttemptSync();
    } catch (_) {
      // Kegagalan auto-sync latar belakang tidak boleh memutus alur UI
    }
  }

  /// Memuat seluruh laporan yang tersimpan secara lokal (terbaru di atas).
  Future<List<DamageScanReport>> loadReports() async {
    if (simulateStorageFailure) {
      throw const DamageStorageException(
        'Gagal membaca penyimpanan lokal perangkat. Silakan coba muat ulang.',
      );
    }

    if (autoStartOnUse) {
      startAutoSync();
    }

    try {
      final reports = await _store.getAll();
      reportsNotifier.value = List.unmodifiable(reports);
      return reports;
    } catch (_) {
      throw const DamageStorageException(
        'Data riwayat pemindaian gagal dibaca dari penyimpanan lokal.',
      );
    }
  }

  /// Menyimpan laporan baru ke SQLite lokal & menyalin foto agar persisten.
  Future<DamageScanReport> saveReport(DamageScanReport report) async {
    if (simulateStorageFailure) {
      throw const DamageStorageException(
        'Gagal menyimpan laporan ke penyimpanan lokal. Periksa ruang penyimpanan perangkat Anda.',
      );
    }

    if (autoStartOnUse) {
      startAutoSync();
    }

    try {
      final persistedPath = await _persistPhotoCopy(
        sourcePath: report.imagePath,
        reportId: report.id,
      );

      // Pastikan status TIDAK pernah ditandai "synced" sebelum backend sungguhan berhasil
      final safeSyncStatus = report.syncStatus == DamageSyncStatus.synced
          ? DamageSyncStatus.pendingSync
          : report.syncStatus;

      final savedReport = report.copyWith(
        imagePath: persistedPath,
        syncStatus: safeSyncStatus,
        clearSyncedAt: safeSyncStatus != DamageSyncStatus.synced,
      );

      await _store.upsert(savedReport);
      final updated = await _store.getAll();
      reportsNotifier.value = List.unmodifiable(updated);
      return savedReport;
    } catch (e) {
      if (e is DamageStorageException) rethrow;
      throw const DamageStorageException(
        'Terjadi kendala saat menyimpan laporan ke perangkat. Silakan coba lagi.',
      );
    }
  }

  /// Menghapus laporan berdasarkan [reportId] beserta salinan foto lokalnya.
  Future<void> deleteReport(String reportId) async {
    if (simulateStorageFailure) {
      throw const DamageStorageException(
        'Gagal menghapus laporan dari penyimpanan lokal.',
      );
    }

    try {
      final existing = await _safeReadList();
      DamageScanReport? target;
      for (final item in existing) {
        if (item.id == reportId) {
          target = item;
          break;
        }
      }

      await _store.deleteById(reportId);

      if (target != null) {
        await _cleanupPersistedPhotoIfOwned(target.imagePath);
      }

      final updated = await _store.getAll();
      reportsNotifier.value = List.unmodifiable(updated);
    } catch (e) {
      if (e is DamageStorageException) rethrow;
      throw const DamageStorageException(
        'Laporan gagal dihapus dari penyimpanan lokal. Silakan coba lagi.',
      );
    }
  }

  /// Mengambil riwayat laporan dari server dan menggabungkannya ke cache lokal.
  ///
  /// Aturan penggabungan:
  /// - Laporan lokal yang masih `pendingSync` **menang**, agar tidak ada data
  ///   lokal yang belum terkirim tertimpa status "synced" dari server.
  /// - Laporan server yang belum ada di perangkat disimpan sebagai cermin
  ///   `synced` (hanya metadata + `imageUrl`, tanpa salinan foto lokal).
  ///
  /// Melempar [DamageSyncException] bila sesi tidak ada atau jaringan gagal;
  /// pemanggil tetap dapat menampilkan cache lokal sebagai fallback.
  Future<List<DamageScanReport>> fetchRemoteReports() async {
    final accessToken = accessTokenProvider != null
        ? await accessTokenProvider!()
        : await TokenManager.getAccessToken();

    if (accessToken == null || accessToken.trim().isEmpty) {
      throw const DamageSyncException(
        'Masuk ke akun SIGAP untuk melihat laporan yang sudah tersimpan di server.',
        needsLogin: true,
      );
    }

    if (!await checkInternetAvailability()) {
      throw const DamageSyncException(
        'Tidak ada koneksi internet. Menampilkan riwayat yang tersimpan di perangkat.',
      );
    }

    dynamic response;
    try {
      response = await ApiClient().get(
        ApiConfig.myDamageReports,
        requiresAuth: true,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        throw const DamageSyncException(
          'Sesi login sudah berakhir. Silakan masuk kembali untuk memuat riwayat server.',
          needsLogin: true,
        );
      }
      throw DamageSyncException(
        'Gagal memuat riwayat dari server. ${e.firstErrorMessage}',
      );
    } catch (_) {
      throw const DamageSyncException(
        'Gagal memuat riwayat dari server. Menampilkan data lokal.',
      );
    }

    final rows = _extractReportRows(response);
    return mergeServerReports(rows);
  }

  /// Menggabungkan payload laporan server ke penyimpanan lokal.
  ///
  /// Dipisahkan dari [fetchRemoteReports] agar dapat diuji tanpa jaringan.
  Future<List<DamageScanReport>> mergeServerReports(
    List<Map<String, dynamic>> serverRows,
  ) async {
    final localReports = await _store.getAll();
    final localById = <String, DamageScanReport>{
      for (final report in localReports) report.id: report,
    };

    final merged = <String, DamageScanReport>{
      for (final report in localReports) report.id: report,
    };

    for (final row in serverRows) {
      final remote = DamageScanReport.fromServerJson(row);
      if (remote.id.isEmpty) continue;

      final local = localById[remote.id];
      if (local == null) {
        await _store.upsert(remote);
        merged[remote.id] = remote;
        continue;
      }

      // Status lokal yang belum terkirim tidak boleh ditimpa server.
      if (local.syncStatus == DamageSyncStatus.pendingSync) continue;

      final aligned = remote.copyWith(imagePath: local.imagePath);
      await _store.upsert(aligned);
      merged[remote.id] = aligned;
    }

    final result = merged.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    reportsNotifier.value = List.unmodifiable(result);
    return result;
  }

  /// Menormalkan amplop respons `GET /api/damage-reports/my/`.
  ///
  /// Endpoint mengembalikan array, tetapi [ApiClient] dapat mengembalikan peta
  /// berpaginasi bila backend kelak menambahkan pagination.
  static List<Map<String, dynamic>> _extractReportRows(dynamic response) {
    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList();
    }
    if (response is Map<String, dynamic>) {
      final results = response['results'];
      if (results is List) {
        return results.whereType<Map<String, dynamic>>().toList();
      }
    }
    return const [];
  }

  /// Mengecek konektivitas dan mencoba menyinkronkan antrean laporan `pendingSync`
  /// ke `POST /api/damage-reports/` secara jujur.
  ///
  /// - Menggunakan guard `_isSyncing` agar tidak terjadi sinkronisasi paralel/ganda.
  /// - Hanya menandai `synced` + `syncedAt` bila respons server sukses (2xx).
  Future<VisionSyncCheckResult> checkAndAttemptSync() async {
    if (_isSyncing) {
      final currentPending = reportsNotifier.value
          .where((r) => r.syncStatus == DamageSyncStatus.pendingSync)
          .length;
      return VisionSyncCheckResult(
        hasInternet: true,
        backendEndpointAvailable: false,
        pendingCount: currentPending,
        message: 'Proses sinkronisasi laporan sedang berlangsung...',
      );
    }

    _isSyncing = true;
    try {
      final reports = await loadReports();
      final pending = reports
          .where((r) => r.syncStatus == DamageSyncStatus.pendingSync)
          .toList();

      if (pending.isEmpty) {
        return const VisionSyncCheckResult(
          hasInternet: true,
          backendEndpointAvailable: true,
          pendingCount: 0,
          message: 'Tidak ada laporan di antrean sinkronisasi.',
        );
      }

      final online = await checkInternetAvailability();
      if (!online) {
        return VisionSyncCheckResult(
          hasInternet: false,
          backendEndpointAvailable: false,
          pendingCount: pending.length,
          message:
              'Anda sedang offline. ${pending.length} laporan tetap aman tersimpan di antrean SQLite lokal perangkat dan tidak dikirim ke server.',
        );
      }

      final accessToken = accessTokenProvider != null
          ? await accessTokenProvider!()
          : await TokenManager.getAccessToken();

      if (accessToken == null || accessToken.trim().isEmpty) {
        return VisionSyncCheckResult(
          hasInternet: true,
          backendEndpointAvailable: false,
          pendingCount: pending.length,
          message:
              'Login akun SIGAP diperlukan untuk sinkronisasi ke server. ${pending.length} laporan tetap aman tersimpan di antrean SQLite lokal.',
        );
      }

      int syncedCount = 0;
      int skippedNoLocationCount = 0;
      bool backendAvailable = true;
      String? failureReason;

      for (final report in pending) {
        final payload = buildSyncPayload(report);
        if (payload == null) {
          // Jangan mengirim koordinat fiktif untuk laporan tanpa lokasi GPS
          skippedNoLocationCount++;
          continue;
        }

        try {
          if (syncUploader != null) {
            await syncUploader!(report, payload);
          } else {
            await ApiClient().post(
              ApiConfig.damageReports,
              body: payload,
              requiresAuth: true,
            );
          }

          await _store.markSynced(report.id, DateTime.now());
          syncedCount++;
        } on ApiException catch (e) {
          if (e.statusCode == 404) {
            backendAvailable = false;
            failureReason =
                'Endpoint sinkronisasi SIGAP-Vision (${ApiConfig.damageReports}) belum tersedia di backend.';
            break;
          }
          if (e.statusCode == 401 || e.statusCode == 403) {
            backendAvailable = true;
            failureReason =
                'Sesi login tidak valid atau kedaluwarsa. Silakan masuk kembali untuk menyinkronkan laporan.';
            break;
          }
          if (e.statusCode == 503 || e.statusCode == 408 || e.statusCode == 0) {
            backendAvailable = false;
            failureReason =
                'Server backend tidak dapat dijangkau saat ini. Laporan tetap tersimpan aman di antrean SQLite lokal.';
            break;
          }
          failureReason = e.firstErrorMessage;
        } catch (_) {
          backendAvailable = false;
          failureReason =
              'Gagal mengirim laporan ke server. Laporan tetap tersimpan aman di antrean SQLite lokal.';
          break;
        }
      }

      // Refresh notifier agar UI riwayat & Beranda langsung mencerminkan perubahan
      final refreshed = await _store.getAll();
      reportsNotifier.value = List.unmodifiable(refreshed);
      final remainingPending = refreshed
          .where((r) => r.syncStatus == DamageSyncStatus.pendingSync)
          .length;

      if (syncedCount > 0 && remainingPending == 0) {
        return VisionSyncCheckResult(
          hasInternet: true,
          backendEndpointAvailable: true,
          pendingCount: 0,
          syncedCount: syncedCount,
          message:
              '$syncedCount laporan berhasil disinkronkan ke server SIGAP.',
        );
      }

      if (syncedCount > 0 && skippedNoLocationCount > 0 && failureReason == null) {
        return VisionSyncCheckResult(
          hasInternet: true,
          backendEndpointAvailable: true,
          pendingCount: remainingPending,
          syncedCount: syncedCount,
          skippedNoLocationCount: skippedNoLocationCount,
          message:
              '$syncedCount laporan tersinkronisasi. $skippedNoLocationCount laporan tanpa koordinat GPS tetap tersimpan lokal dan tidak dikirim.',
        );
      }

      if (skippedNoLocationCount > 0 &&
          syncedCount == 0 &&
          failureReason == null) {
        return VisionSyncCheckResult(
          hasInternet: true,
          backendEndpointAvailable: true,
          pendingCount: remainingPending,
          skippedNoLocationCount: skippedNoLocationCount,
          message:
              '$skippedNoLocationCount laporan belum memiliki koordinat GPS sehingga tetap disimpan lokal (tidak dikirim dengan lokasi palsu).',
        );
      }

      return VisionSyncCheckResult(
        hasInternet: true,
        backendEndpointAvailable: backendAvailable,
        pendingCount: remainingPending,
        syncedCount: syncedCount,
        skippedNoLocationCount: skippedNoLocationCount,
        message: failureReason ??
            '$remainingPending laporan tetap tersimpan aman di antrean SQLite lokal (status: Menunggu Sinkronisasi).',
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Mengecek apakah perangkat memiliki koneksi internet dasar.
  Future<bool> checkInternetAvailability() async {
    if (internetChecker != null) {
      return internetChecker!();
    }

    // Periksa terlebih dahulu status interface jaringan lewat connectivity_plus v7
    try {
      final results = connectivityChecker != null
          ? await connectivityChecker!()
          : await Connectivity().checkConnectivity();
      final hasTransport = results.any((r) => r != ConnectivityResult.none);
      if (!hasTransport) return false;
    } on MissingPluginException {
      // Lanjutkan ke pengecekan DNS bila plugin tidak tersedia
    } on PlatformException {
      // Lanjutkan ke pengecekan DNS
    } catch (_) {
      // Lanjutkan ke pengecekan DNS
    }

    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<List<DamageScanReport>> _safeReadList() async {
    try {
      return await _store.getAll();
    } catch (_) {
      return const [];
    }
  }

  Future<String> _persistPhotoCopy({
    required String sourcePath,
    required String reportId,
  }) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return sourcePath;
      }

      Directory? baseDir;
      if (directoryProvider != null) {
        baseDir = await directoryProvider!();
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }

      if (baseDir == null) return sourcePath;

      final reportsDir =
          Directory('${baseDir.path}${Platform.pathSeparator}$_imagesDirName');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }

      final extIndex = sourcePath.lastIndexOf('.');
      final ext = (extIndex != -1 && extIndex < sourcePath.length - 1)
          ? sourcePath.substring(extIndex)
          : '.jpg';

      final targetPath =
          '${reportsDir.path}${Platform.pathSeparator}$reportId$ext';
      if (targetPath == sourcePath) return sourcePath;

      final copied = await sourceFile.copy(targetPath);
      return copied.path;
    } catch (_) {
      // Fallback aman (misalnya pada lingkungan pengujian widget)
      return sourcePath;
    }
  }

  Future<void> _cleanupPersistedPhotoIfOwned(String imagePath) async {
    try {
      if (!imagePath.contains(_imagesDirName)) return;
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Abaikan error pembersihan berkas agar penghapusan metadata tetap sukses
    }
  }
}
