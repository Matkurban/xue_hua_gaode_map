import 'geofence_action.dart';

/// Geofence event emitted on [GeofenceClient.geofenceStream].
class GeofenceEvent {
  const GeofenceEvent({
    required this.type,
    this.status,
    this.customId,
    this.fenceId,
    this.success,
    this.errorCode,
    this.count,
  });

  final String type;

  /// Trigger status when [isTrigger] is true.
  final GeofenceTriggerStatus? status;
  final String? customId;
  final String? fenceId;

  /// Whether fence creation succeeded when [isCreateFinished] is true.
  final bool? success;

  /// Native error code when [isCreateFinished] reports failure.
  final int? errorCode;

  /// Number of regions created when [isCreateFinished] succeeds.
  final int? count;

  bool get isTrigger => type == 'trigger';
  bool get isCreateFinished => type == 'createFinished';

  factory GeofenceEvent.fromMap(Map<dynamic, dynamic> map) {
    return GeofenceEvent(
      type: map['type'] as String? ?? 'unknown',
      status: map['status'] != null
          ? geofenceTriggerStatusFromCode((map['status'] as num).toInt())
          : null,
      customId: map['customId'] as String?,
      fenceId: map['fenceId'] as String?,
      success: map['success'] as bool?,
      errorCode: (map['errorCode'] as num?)?.toInt(),
      count: (map['count'] as num?)?.toInt(),
    );
  }
}
