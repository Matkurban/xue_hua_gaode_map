/// Download status of an offline map city package.
enum OfflineMapDownloadStatus {
  unknown,
  waiting,
  downloading,
  paused,
  finished,
  error,
  cancelled,
}

OfflineMapDownloadStatus _offlineMapDownloadStatusFromWire(String? value) {
  switch (value) {
    case 'waiting':
      return OfflineMapDownloadStatus.waiting;
    case 'downloading':
      return OfflineMapDownloadStatus.downloading;
    case 'paused':
      return OfflineMapDownloadStatus.paused;
    case 'finished':
      return OfflineMapDownloadStatus.finished;
    case 'error':
      return OfflineMapDownloadStatus.error;
    case 'cancelled':
      return OfflineMapDownloadStatus.cancelled;
    default:
      return OfflineMapDownloadStatus.unknown;
  }
}

/// A city or province entry in the offline map catalog.
class OfflineMapCity {
  const OfflineMapCity({
    required this.name,
    required this.cityCode,
    this.provinceName = '',
    this.isProvince = false,
    this.downloaded = false,
    this.completePercent = 0,
    this.status = OfflineMapDownloadStatus.unknown,
  });

  final String name;
  final String cityCode;
  final String provinceName;
  final bool isProvince;
  final bool downloaded;
  final int completePercent;
  final OfflineMapDownloadStatus status;

  factory OfflineMapCity.fromMap(Map<dynamic, dynamic> map) {
    return OfflineMapCity(
      name: map['name'] as String? ?? '',
      cityCode: map['cityCode'] as String? ?? '',
      provinceName: map['provinceName'] as String? ?? '',
      isProvince: map['isProvince'] as bool? ?? false,
      downloaded: map['downloaded'] as bool? ?? false,
      completePercent: (map['completePercent'] as num?)?.toInt() ?? 0,
      status: _offlineMapDownloadStatusFromWire(map['status'] as String?),
    );
  }
}

/// Progress event for an offline map download task.
class OfflineMapProgressEvent {
  const OfflineMapProgressEvent({
    required this.cityCode,
    required this.cityName,
    required this.status,
    this.completePercent = 0,
    this.errorInfo,
  });

  final String cityCode;
  final String cityName;
  final OfflineMapDownloadStatus status;
  final int completePercent;
  final String? errorInfo;

  factory OfflineMapProgressEvent.fromMap(Map<dynamic, dynamic> map) {
    return OfflineMapProgressEvent(
      cityCode: map['cityCode'] as String? ?? '',
      cityName: map['cityName'] as String? ?? '',
      status: _offlineMapDownloadStatusFromWire(map['status'] as String?),
      completePercent: (map['completePercent'] as num?)?.toInt() ?? 0,
      errorInfo: map['errorInfo'] as String?,
    );
  }
}
