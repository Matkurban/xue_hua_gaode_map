import '../core/gaode_exception.dart';

class LocationResult {
  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.bearing,
    this.speed,
    this.address,
    this.country,
    this.province,
    this.city,
    this.district,
    this.street,
    this.streetNumber,
    this.cityCode,
    this.adCode,
    this.poiName,
    this.aoiName,
    this.buildingId,
    this.floor,
    this.locationType,
    this.locationDetail,
    this.gpsAccuracyStatus,
    this.timestamp,
    this.errorCode = 0,
    this.errorInfo,
  });

  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? bearing;
  final double? speed;
  final String? address;
  final String? country;
  final String? province;
  final String? city;
  final String? district;
  final String? street;
  final String? streetNumber;
  final String? cityCode;
  final String? adCode;
  final String? poiName;
  final String? aoiName;
  final String? buildingId;
  final String? floor;
  final int? locationType;
  final String? locationDetail;
  final int? gpsAccuracyStatus;
  final int? timestamp;
  final int errorCode;
  final String? errorInfo;

  bool get isSuccess => errorCode == 0;

  factory LocationResult.fromMap(Map<dynamic, dynamic> map) {
    return LocationResult(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble(),
      bearing: (map['bearing'] as num?)?.toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      address: map['address'] as String?,
      country: map['country'] as String?,
      province: map['province'] as String?,
      city: map['city'] as String?,
      district: map['district'] as String?,
      street: map['street'] as String?,
      streetNumber: map['streetNumber'] as String?,
      cityCode: map['cityCode'] as String?,
      adCode: map['adCode'] as String?,
      poiName: map['poiName'] as String?,
      aoiName: map['aoiName'] as String?,
      buildingId: map['buildingId'] as String?,
      floor: map['floor'] as String?,
      locationType: (map['locationType'] as num?)?.toInt(),
      locationDetail: map['locationDetail'] as String?,
      gpsAccuracyStatus: (map['gpsAccuracyStatus'] as num?)?.toInt(),
      timestamp: (map['timestamp'] as num?)?.toInt(),
      errorCode: (map['errorCode'] as num?)?.toInt() ?? 0,
      errorInfo: map['errorInfo'] as String?,
    );
  }

  void throwIfFailed() {
    if (!isSuccess) {
      throw GaodeException(errorInfo ?? 'Location failed', code: errorCode);
    }
  }
}
