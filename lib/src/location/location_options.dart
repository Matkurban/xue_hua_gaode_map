import 'location_enums.dart';

class LocationOptions {
  const LocationOptions({
    this.onceLocation = false,
    this.onceLocationLatest = false,
    this.interval = 2000,
    this.needAddress = false,
    this.locationMode = LocationMode.highAccuracy,
    this.locationPurpose = LocationPurpose.none,
    this.desiredAccuracy = DesiredAccuracy.best,
    this.distanceFilter = -1,
    this.pausesLocationUpdatesAutomatically = false,
    this.allowsBackgroundUpdates = false,
    this.mockEnable = false,
    this.locationCacheEnable = true,
    this.wifiActiveScan = false,
    this.httpTimeout = 30000,
    this.geoLanguage = GeoLanguage.defaultLanguage,
    this.protocol = LocationProtocol.http,
  });

  final bool onceLocation;
  final bool onceLocationLatest;
  final int interval;
  final bool needAddress;
  final LocationMode locationMode;
  final LocationPurpose locationPurpose;
  final DesiredAccuracy desiredAccuracy;
  final double distanceFilter;
  final bool pausesLocationUpdatesAutomatically;
  final bool allowsBackgroundUpdates;
  final bool mockEnable;
  final bool locationCacheEnable;
  final bool wifiActiveScan;
  final int httpTimeout;
  final GeoLanguage geoLanguage;
  final LocationProtocol protocol;

  LocationOptions copyWith({
    bool? onceLocation,
    bool? onceLocationLatest,
    int? interval,
    bool? needAddress,
    LocationMode? locationMode,
    LocationPurpose? locationPurpose,
    DesiredAccuracy? desiredAccuracy,
    double? distanceFilter,
    bool? pausesLocationUpdatesAutomatically,
    bool? allowsBackgroundUpdates,
    bool? mockEnable,
    bool? locationCacheEnable,
    bool? wifiActiveScan,
    int? httpTimeout,
    GeoLanguage? geoLanguage,
    LocationProtocol? protocol,
  }) {
    return LocationOptions(
      onceLocation: onceLocation ?? this.onceLocation,
      onceLocationLatest: onceLocationLatest ?? this.onceLocationLatest,
      interval: interval ?? this.interval,
      needAddress: needAddress ?? this.needAddress,
      locationMode: locationMode ?? this.locationMode,
      locationPurpose: locationPurpose ?? this.locationPurpose,
      desiredAccuracy: desiredAccuracy ?? this.desiredAccuracy,
      distanceFilter: distanceFilter ?? this.distanceFilter,
      pausesLocationUpdatesAutomatically:
          pausesLocationUpdatesAutomatically ??
          this.pausesLocationUpdatesAutomatically,
      allowsBackgroundUpdates:
          allowsBackgroundUpdates ?? this.allowsBackgroundUpdates,
      mockEnable: mockEnable ?? this.mockEnable,
      locationCacheEnable: locationCacheEnable ?? this.locationCacheEnable,
      wifiActiveScan: wifiActiveScan ?? this.wifiActiveScan,
      httpTimeout: httpTimeout ?? this.httpTimeout,
      geoLanguage: geoLanguage ?? this.geoLanguage,
      protocol: protocol ?? this.protocol,
    );
  }

  Map<String, dynamic> toMap() => {
    'onceLocation': onceLocation,
    'onceLocationLatest': onceLocationLatest,
    'interval': interval,
    'needAddress': needAddress,
    'locationMode': _locationModeValue(locationMode),
    'locationPurpose': _locationPurposeValue(locationPurpose),
    'desiredAccuracy': _desiredAccuracyValue(desiredAccuracy),
    'distanceFilter': distanceFilter,
    'pausesLocationUpdatesAutomatically': pausesLocationUpdatesAutomatically,
    'allowsBackgroundUpdates': allowsBackgroundUpdates,
    'mockEnable': mockEnable,
    'locationCacheEnable': locationCacheEnable,
    'wifiActiveScan': wifiActiveScan,
    'httpTimeout': httpTimeout,
    'geoLanguage': _geoLanguageValue(geoLanguage),
    'protocol': protocol == LocationProtocol.https ? 'https' : 'http',
  };

  static String _locationModeValue(LocationMode mode) {
    switch (mode) {
      case LocationMode.batterySaving:
        return 'batterySaving';
      case LocationMode.deviceSensors:
        return 'deviceSensors';
      case LocationMode.highAccuracy:
        return 'highAccuracy';
    }
  }

  static String _locationPurposeValue(LocationPurpose purpose) {
    switch (purpose) {
      case LocationPurpose.signIn:
        return 'signIn';
      case LocationPurpose.transport:
        return 'transport';
      case LocationPurpose.sport:
        return 'sport';
      case LocationPurpose.none:
        return 'none';
    }
  }

  static String _desiredAccuracyValue(DesiredAccuracy accuracy) {
    switch (accuracy) {
      case DesiredAccuracy.bestForNavigation:
        return 'bestForNavigation';
      case DesiredAccuracy.nearestTenMeters:
        return 'nearestTenMeters';
      case DesiredAccuracy.kilometer:
        return 'kilometer';
      case DesiredAccuracy.threeKilometers:
        return 'threeKilometers';
      case DesiredAccuracy.best:
        return 'best';
    }
  }

  static String _geoLanguageValue(GeoLanguage language) {
    switch (language) {
      case GeoLanguage.chinese:
        return 'chinese';
      case GeoLanguage.english:
        return 'english';
      case GeoLanguage.defaultLanguage:
        return 'default';
    }
  }
}
