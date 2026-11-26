import 'package:sigap/core/network/api_client.dart';
import 'package:sigap/core/network/api_config.dart';
import 'package:sigap/features/vision/data/damage_report_repository.dart';
import 'package:sigap/features/vision/domain/models/damage_models.dart';
import '../domain/damage_heatmap_point.dart';

/// Signature fungsi pengambil data mentah heatmap dari backend (dapat di-mock).
typedef RemoteHeatmapFetcher = Future<List<Map<String, dynamic>>> Function();

/// Abstraksi layanan pemuatan layer Heatmap Sebaran Kerusakan SIGAP-Vision.
abstract class DamageHeatmapService {
  Future<DamageHeatmapLoadResult> loadHeatmapPoints();
}

/// Implementasi default [DamageHeatmapService] yang menggabungkan laporan lokal
/// berkoordinat GPS dari [DamageReportRepository] dan data agregat server dari
/// `GET /api/damage-reports/heatmap/` tanpa membuat titik fiktif saat offline.
class DefaultDamageHeatmapService implements DamageHeatmapService {
  final DamageReportRepository _repository;
  final RemoteHeatmapFetcher _remoteFetcher;

  DefaultDamageHeatmapService({
    DamageReportRepository? repository,
    RemoteHeatmapFetcher? remoteFetcher,
  })  : _repository = repository ?? DamageReportRepository.instance,
        _remoteFetcher = remoteFetcher ?? _defaultRemoteFetcher;

  static Future<List<Map<String, dynamic>>> _defaultRemoteFetcher() async {
    final response = await ApiClient().get(
      ApiConfig.damageReportsHeatmap,
      requiresAuth: false,
    );
    return _extractJsonList(response);
  }

  static List<Map<String, dynamic>> _extractJsonList(dynamic payload) {
    if (payload is List) {
      return payload.whereType<Map<String, dynamic>>().toList();
    }
    if (payload is Map<String, dynamic>) {
      for (final key in const ['results', 'points', 'data']) {
        final candidate = payload[key];
        if (candidate is List) {
          return candidate.whereType<Map<String, dynamic>>().toList();
        }
      }
    }
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<DamageHeatmapLoadResult> loadHeatmapPoints() async {
    // 1. Muat laporan lokal berkoordinat GPS dari SQLite / ValueNotifier
    List<DamageScanReport> localReports;
    try {
      localReports = await _repository.loadReports();
    } catch (_) {
      localReports = _repository.reportsNotifier.value;
    }

    final localPoints = <DamageHeatmapPoint>[];
    for (final report in localReports) {
      final point = DamageHeatmapPoint.fromLocalReport(report);
      if (point != null) {
        localPoints.add(point);
      }
    }

    // 2. Muat data heatmap publik dari backend secara aman (tidak crash saat offline/404)
    final serverPoints = <DamageHeatmapPoint>[];
    bool serverAvailable = false;
    String? serverUnavailableReason;

    try {
      final rawList = await _remoteFetcher();
      serverAvailable = true;
      for (final item in rawList) {
        final parsed = DamageHeatmapPoint.fromServerJson(item);
        if (parsed != null) {
          serverPoints.add(parsed);
        }
      }
    } on ApiException catch (e) {
      serverAvailable = false;
      if (e.statusCode == 404) {
        serverUnavailableReason = 'endpoint heatmap backend belum aktif';
      } else {
        serverUnavailableReason = 'server heatmap sedang tidak terjangkau';
      }
    } catch (_) {
      serverAvailable = false;
      serverUnavailableReason = 'server heatmap tidak terjangkau (mode offline)';
    }

    // 3. Gabungkan server + lokal dengan deduplikasi berdasarkan ID
    //    (titik server diprioritaskan agar laporan yang sudah sinkron tidak ganda)
    final mergedById = <String, DamageHeatmapPoint>{};
    var mergedServerCount = 0;
    var mergedLocalCount = 0;

    for (final pt in serverPoints) {
      if (!mergedById.containsKey(pt.id)) {
        mergedById[pt.id] = pt;
        mergedServerCount += 1;
      }
    }
    for (final pt in localPoints) {
      if (!mergedById.containsKey(pt.id)) {
        mergedById[pt.id] = pt;
        mergedLocalCount += 1;
      }
    }

    final mergedPoints = mergedById.values.toList()
      ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));

    // 4. Susun pesan status yang jujur dan informatif
    final String statusMessage;
    if (mergedPoints.isEmpty) {
      if (serverAvailable) {
        statusMessage =
            'Belum ada titik kerusakan berkoordinat GPS tercatat di server maupun perangkat Anda.';
      } else {
        statusMessage =
            'Belum ada titik kerusakan tercatat (${serverUnavailableReason ?? 'mode offline lokal'}).';
      }
    } else if (serverAvailable) {
      statusMessage =
          'Menampilkan ${mergedPoints.length} titik kerusakan ($mergedServerCount server, $mergedLocalCount lokal).';
    } else {
      statusMessage =
          'Mode Lokal: $mergedLocalCount titik kerusakan dari perangkat Anda (${serverUnavailableReason ?? 'server offline'}).';
    }

    return DamageHeatmapLoadResult(
      points: mergedPoints,
      serverCount: mergedServerCount,
      localCount: mergedLocalCount,
      serverAvailable: serverAvailable,
      statusMessage: statusMessage,
    );
  }
}
