import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xue_hua_gaode_map/xue_hua_gaode_map.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  void setHandler(
    MethodChannel channel,
    Future<Object?>? Function(MethodCall call)? handler,
  ) {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, handler);
  }

  test('LocationResult.fromMap parses success result', () {
    final result = LocationResult.fromMap({
      'latitude': 39.9,
      'longitude': 116.4,
      'accuracy': 20.0,
      'address': '北京市',
      'errorCode': 0,
    });

    expect(result.isSuccess, isTrue);
    expect(result.latitude, 39.9);
    expect(result.longitude, 116.4);
    expect(result.address, '北京市');
  });

  test('LocationResult.fromMap parses failure result', () {
    final result = LocationResult.fromMap({
      'latitude': 0,
      'longitude': 0,
      'errorCode': 12,
      'errorInfo': '缺少定位权限',
    });

    expect(result.isSuccess, isFalse);
    expect(result.errorCode, 12);
  });

  test('LocationResult.throwIfFailed throws GaodeException', () {
    final result = LocationResult.fromMap({
      'latitude': 0,
      'longitude': 0,
      'errorCode': 12,
      'errorInfo': '缺少定位权限',
    });

    expect(
      () => result.throwIfFailed(),
      throwsA(isA<GaodeException>().having((e) => e.code, 'code', 12)),
    );
  });

  test('LocationOptions defaults serialize as expected', () {
    final map = const LocationOptions().toMap();
    expect(map['onceLocation'], isFalse);
    expect(map['interval'], 2000);
    expect(map['locationMode'], 'highAccuracy');
    expect(map['desiredAccuracy'], 'best');
    expect(map['protocol'], 'http');
    expect(map['geoLanguage'], 'default');
    expect(map['gpsFirst'], isFalse);
    expect(map['sensorEnable'], isTrue);
  });

  test('LocationOptions.toMap serializes extended fields', () {
    const options = LocationOptions(
      gpsFirst: true,
      gpsFirstTimeout: 15000,
      sensorEnable: false,
      locationTimeout: 8,
      reGeocodeTimeout: 6,
    );
    final map = options.toMap();
    expect(map['gpsFirst'], isTrue);
    expect(map['gpsFirstTimeout'], 15000);
    expect(map['sensorEnable'], isFalse);
    expect(map['locationTimeout'], 8);
    expect(map['reGeocodeTimeout'], 6);
  });

  test('LocationOptions.toMap serializes enums', () {
    const options = LocationOptions(
      onceLocation: true,
      needAddress: true,
      locationMode: LocationMode.batterySaving,
      locationPurpose: LocationPurpose.signIn,
      desiredAccuracy: DesiredAccuracy.nearestTenMeters,
      geoLanguage: GeoLanguage.chinese,
      protocol: LocationProtocol.https,
    );

    final map = options.toMap();
    expect(map['onceLocation'], isTrue);
    expect(map['locationMode'], 'batterySaving');
    expect(map['locationPurpose'], 'signIn');
    expect(map['desiredAccuracy'], 'nearestTenMeters');
    expect(map['geoLanguage'], 'chinese');
    expect(map['protocol'], 'https');
  });

  test('LocationOptions.copyWith overrides only given fields', () {
    const base = LocationOptions(interval: 1000, needAddress: true);
    final copy = base.copyWith(interval: 5000);
    expect(copy.interval, 5000);
    expect(copy.needAddress, isTrue);
  });

  test('GeofenceEvent.fromMap parses trigger event', () {
    final event = GeofenceEvent.fromMap({
      'type': 'trigger',
      'status': 1,
      'customId': 'fence-1',
      'fenceId': 'abc',
    });

    expect(event.isTrigger, isTrue);
    expect(event.status, GeofenceTriggerStatus.inside);
    expect(event.customId, 'fence-1');
  });

  test('GeofenceEvent.fromMap parses createFinished event', () {
    final event = GeofenceEvent.fromMap({
      'type': 'createFinished',
      'success': true,
      'errorCode': 0,
      'count': 2,
      'customId': 'office',
    });

    expect(event.isCreateFinished, isTrue);
    expect(event.success, isTrue);
    expect(event.count, 2);
    expect(event.customId, 'office');
  });

  test('geofenceTriggerStatusFromCode maps codes', () {
    expect(geofenceTriggerStatusFromCode(1), GeofenceTriggerStatus.inside);
    expect(geofenceTriggerStatusFromCode(2), GeofenceTriggerStatus.outside);
    expect(geofenceTriggerStatusFromCode(3), GeofenceTriggerStatus.stayed);
    expect(geofenceTriggerStatusFromCode(99), GeofenceTriggerStatus.unknown);
  });

  test('GaodeCoordinate round trip', () {
    const coordinate = GaodeCoordinate(latitude: 31.2, longitude: 121.5);
    final restored = GaodeCoordinate.fromMap(coordinate.toMap());
    expect(restored.latitude, 31.2);
    expect(restored.longitude, 121.5);
  });

  test('PoiSearchResult.fromMap parses pois and paging', () {
    final result = PoiSearchResult.fromMap({
      'pois': [
        {
          'id': 'p1',
          'name': '咖啡馆',
          'latitude': 39.9,
          'longitude': 116.4,
          'distance': 120,
        },
      ],
      'count': 30,
      'pageCount': 2,
    });

    expect(result.pois, hasLength(1));
    expect(result.pois.first.name, '咖啡馆');
    expect(result.pois.first.location?.latitude, 39.9);
    expect(result.pois.first.distance, 120);
    expect(result.count, 30);
    expect(result.pageCount, 2);
  });

  test('Poi.fromMap leaves location null without coordinates', () {
    final poi = Poi.fromMap({'id': 'x', 'name': '某线路'});
    expect(poi.location, isNull);
  });

  test('InputTip.fromMap parses optional location', () {
    final tip = InputTip.fromMap({
      'name': '望京',
      'district': '朝阳区',
      'adCode': '110105',
    });
    expect(tip.name, '望京');
    expect(tip.location, isNull);
  });

  test('GeocodeResult.fromMap parses geocodes', () {
    final result = GeocodeResult.fromMap({
      'geocodes': [
        {
          'formattedAddress': '北京市朝阳区望京',
          'latitude': 40.0,
          'longitude': 116.47,
          'level': '兴趣点',
        },
      ],
    });
    expect(result.geocodes, hasLength(1));
    expect(result.geocodes.first.location.latitude, 40.0);
    expect(result.geocodes.first.level, '兴趣点');
  });

  test('CameraPosition round trip with bearing and tilt', () {
    const camera = CameraPosition(
      target: GaodeCoordinate(latitude: 39.9, longitude: 116.4),
      zoom: 17,
      bearing: 45,
      tilt: 30,
    );
    final restored = CameraPosition.fromMap(camera.toMap());
    expect(restored.zoom, 17);
    expect(restored.bearing, 45);
    expect(restored.tilt, 30);
  });

  test('GaodeMapEvent.fromMap parses tap event', () {
    final event = GaodeMapEvent.fromMap({
      'type': 'tap',
      'coordinate': {'latitude': 39.9, 'longitude': 116.4},
    });
    expect(event, isA<GaodeMapTapEvent>());
    expect((event as GaodeMapTapEvent).coordinate.latitude, 39.9);
  });

  test('LatLngBounds round trip', () {
    const bounds = LatLngBounds(
      southwest: GaodeCoordinate(latitude: 39.8, longitude: 116.3),
      northeast: GaodeCoordinate(latitude: 40.0, longitude: 116.5),
    );
    final restored = LatLngBounds.fromMap(bounds.toMap());
    expect(restored.southwest.latitude, 39.8);
    expect(restored.northeast.longitude, 116.5);
  });

  test('GaodeMapPolyline.toMap serializes points', () {
    const polyline = GaodeMapPolyline(
      id: 'line1',
      points: [
        GaodeCoordinate(latitude: 39.9, longitude: 116.4),
        GaodeCoordinate(latitude: 40.0, longitude: 116.5),
      ],
      color: 0xFF0000FF,
    );
    final map = polyline.toMap();
    expect(map['id'], 'line1');
    expect((map['points'] as List).length, 2);
  });

  test('OfflineMapCity.fromMap parses status', () {
    final city = OfflineMapCity.fromMap({
      'name': '北京市',
      'cityCode': '110000',
      'status': 'downloading',
      'completePercent': 42,
    });
    expect(city.name, '北京市');
    expect(city.status, OfflineMapDownloadStatus.downloading);
    expect(city.completePercent, 42);
  });

  test('CameraPosition round trip', () {
    const camera = CameraPosition(
      target: GaodeCoordinate(latitude: 39.9, longitude: 116.4),
      zoom: 17,
    );
    final restored = CameraPosition.fromMap(camera.toMap());
    expect(restored.zoom, 17);
    expect(restored.target.longitude, 116.4);
  });

  test('GaodeMapMarker.toMap serializes nested position', () {
    const marker = GaodeMapMarker(
      id: 'm1',
      position: GaodeCoordinate(latitude: 39.9, longitude: 116.4),
      title: 'Tiananmen',
      infoWindowEnabled: false,
    );
    final map = marker.toMap();
    expect(map['id'], 'm1');
    expect((map['position'] as Map)['latitude'], 39.9);
    expect(map['title'], 'Tiananmen');
    expect(map['infoWindowEnabled'], false);
  });

  test('GaodeMapEvent.fromMap parses infoWindowTap', () {
    final event = GaodeMapEvent.fromMap({
      'type': 'infoWindowTap',
      'id': 'marker_1',
    });
    expect(event, isA<GaodeMapInfoWindowTapEvent>());
    expect((event as GaodeMapInfoWindowTapEvent).id, 'marker_1');
  });

  test('GaodeMapOptions.toMap serializes map type wire value', () {
    const options = GaodeMapOptions(mapType: GaodeMapType.satellite);
    expect(options.toMap()['mapType'], 'satellite');
  });

  test('GaodeSdk.setApiKey rejects empty key', () {
    expect(() => GaodeSdk.setApiKey(''), throwsA(isA<GaodeException>()));
  });

  test('invokeGaodeMethod maps PlatformException to GaodeException', () async {
    const channel = MethodChannel('xue_hua_gaode_map');
    setHandler(channel, (MethodCall call) async {
      throw PlatformException(
        code: 'PRIVACY_NOT_CONFIGURED',
        message: 'privacy',
      );
    });

    final client = LocationClient();
    expect(() => client.start(), throwsA(isA<GaodeException>()));

    setHandler(channel, null);
  });

  test(
    'LocationClient.dispose stops before destroying native client',
    () async {
      const channel = MethodChannel('xue_hua_gaode_map');
      final calls = <String>[];
      setHandler(channel, (MethodCall call) async {
        calls.add(call.method);
        return null;
      });

      final client = LocationClient();
      await client.dispose();

      expect(calls, ['location#stop', 'location#destroy']);

      setHandler(channel, null);
    },
  );

  test('LocationClient concurrent dispose is idempotent', () async {
    const channel = MethodChannel('xue_hua_gaode_map');
    setHandler(channel, (MethodCall call) async => null);

    final client = LocationClient();
    await Future.wait([client.dispose(), client.dispose()]);

    setHandler(channel, null);
  });

  test('GeofenceClient.dispose removes fences then destroys', () async {
    const channel = MethodChannel('xue_hua_gaode_map');
    final calls = <String>[];
    setHandler(channel, (MethodCall call) async {
      calls.add(call.method);
      return null;
    });

    final client = GeofenceClient();
    await client.dispose();

    expect(calls, ['geofence#removeAll', 'geofence#destroy']);

    setHandler(channel, null);
  });

  test('invokeGaodeMethod preserves string platform code', () async {
    const channel = MethodChannel('xue_hua_gaode_map');
    setHandler(channel, (MethodCall call) async {
      throw PlatformException(
        code: 'PRIVACY_NOT_CONFIGURED',
        message: 'privacy',
      );
    });

    final client = LocationClient();
    try {
      await client.start();
      fail('Expected GaodeException');
    } on GaodeException catch (e) {
      expect(e.platformCode, 'PRIVACY_NOT_CONFIGURED');
      expect(e.code, isNull);
    }

    setHandler(channel, null);
  });

  test('GeofenceClient concurrent dispose is idempotent', () async {
    const channel = MethodChannel('xue_hua_gaode_map');
    setHandler(channel, (MethodCall call) async => null);

    final client = GeofenceClient();
    await Future.wait([client.dispose(), client.dispose()]);

    setHandler(channel, null);
  });

  test('LocationClient throws after dispose', () async {
    const channel = MethodChannel('xue_hua_gaode_map');
    setHandler(channel, (MethodCall call) async => null);

    final client = LocationClient();
    await client.dispose();

    expect(() => client.getLocation(), throwsA(isA<StateError>()));

    setHandler(channel, null);
  });

  test('SearchClient rejects empty keyword and address', () async {
    const search = SearchClient();
    expect(
      () => search.searchPoiKeyword(keyword: ''),
      throwsA(isA<GaodeException>()),
    );
    expect(() => search.inputTips(keyword: ''), throwsA(isA<GaodeException>()));
    expect(() => search.geocode(address: ''), throwsA(isA<GaodeException>()));
  });

  test('GaodeMapEvent.fromMap parses camera and marker drag events', () {
    final move = GaodeMapEvent.fromMap({
      'type': 'cameraMove',
      'position': {
        'target': {'latitude': 39.9, 'longitude': 116.4},
        'zoom': 15,
        'bearing': 0,
        'tilt': 0,
      },
    });
    expect(move, isA<GaodeMapCameraMoveEvent>());

    final drag = GaodeMapEvent.fromMap({
      'type': 'markerDrag',
      'id': 'm1',
      'position': {'latitude': 39.9, 'longitude': 116.4},
    });
    expect(drag, isA<GaodeMapMarkerDragEvent>());
    expect(
      (drag as GaodeMapMarkerDragEvent).phase,
      GaodeMapMarkerDragPhase.move,
    );
  });

  test('GaodeMapEvent.fromMap returns unknown event for malformed payload', () {
    final event = GaodeMapEvent.fromMap({
      'type': 'tap',
      'coordinate': 'invalid',
    });
    expect(event, isA<GaodeMapUnknownEvent>());
    expect((event as GaodeMapUnknownEvent).type, 'tap');
  });

  test('overlay models serialize expected wire maps', () {
    const coord = GaodeCoordinate(latitude: 39.9, longitude: 116.4);
    const circle = GaodeMapCircle(
      id: 'c1',
      center: coord,
      radius: 500,
      fillColor: 0x330000FF,
    );
    expect(circle.toMap()['radius'], 500);

    const polygon = GaodeMapPolygon(
      id: 'p1',
      points: [coord, GaodeCoordinate(latitude: 40, longitude: 116.5)],
      fillColor: 0x330000FF,
    );
    expect((polygon.toMap()['points'] as List).length, 2);

    const heatmap = GaodeMapHeatmap(
      id: 'h1',
      points: [GaodeHeatmapWeightedPoint(coordinate: coord, intensity: 2)],
      opacity: 0.5,
    );
    final heatPoint = heatmap.toMap()['points'] as List;
    expect(heatPoint.first['latitude'], 39.9);
    expect(heatPoint.first['intensity'], 2);

    const tile = GaodeMapTileOverlay(
      id: 't1',
      urlTemplate: 'https://example.com/{x}/{y}/{z}',
      tileSize: 512,
    );
    expect(tile.toMap()['tileSize'], 512);
  });

  test('GaodeMapOptions.toMap serializes region limits and gestures', () {
    const options = GaodeMapOptions(
      scrollGesturesEnabled: false,
      terrainEnabled: true,
      regionLimits: LatLngBounds(
        southwest: GaodeCoordinate(latitude: 39.8, longitude: 116.3),
        northeast: GaodeCoordinate(latitude: 40.0, longitude: 116.5),
      ),
    );
    final map = options.toMap();
    expect(map['scrollGesturesEnabled'], isFalse);
    expect(map['terrainEnabled'], isTrue);
    expect(map['regionLimits'], isNotNull);
  });

  test('OfflineMapClient routes methods through offline map channel', () async {
    const channel = MethodChannel('xue_hua_gaode_map');
    final calls = <String>[];
    setHandler(channel, (MethodCall call) async {
      calls.add(call.method);
      if (call.method == 'offlineMap#getCityList') {
        return [
          {'name': '北京市', 'cityCode': '110000', 'status': 'finished'},
        ];
      }
      return null;
    });

    final client = OfflineMapClient();
    final cities = await client.getCityList();
    await client.downloadByCityCode('110000');
    await client.dispose();

    expect(cities, hasLength(1));
    expect(cities.first.cityCode, '110000');
    expect(
      calls,
      containsAll(['offlineMap#getCityList', 'offlineMap#downloadByCityCode', 'offlineMap#destroy']),
    );

    setHandler(channel, null);
  });

  test('OfflineMapClient throws after dispose', () async {
    const channel = MethodChannel('xue_hua_gaode_map');
    setHandler(channel, (MethodCall call) async => null);

    final client = OfflineMapClient();
    await client.dispose();

    expect(() => client.getCityList(), throwsA(isA<StateError>()));

    setHandler(channel, null);
  });

  test('LocationOptions.toMap serializes locationPurpose none', () {
    const options = LocationOptions(locationPurpose: LocationPurpose.none);
    expect(options.toMap()['locationPurpose'], 'none');
  });

  test('GaodeMapController routes my-location calls through per-view channel', () async {
    const channel = MethodChannel('xue_hua_gaode_map/map_8');
    final calls = <String>[];
    setHandler(channel, (MethodCall call) async {
      calls.add(call.method);
      if (call.method == 'map#getMyLocation') {
        return {'latitude': 39.9, 'longitude': 116.4, 'accuracy': 10.0};
      }
      return null;
    });

    final controller = GaodeMapController.init(8);
    await controller.setMyLocationStyle(
      const GaodeMyLocationStyle(type: GaodeMyLocationType.follow),
    );
    await controller.moveToMyLocation();
    final fix = await controller.getMyLocation();

    expect(
      calls,
      containsAll([
        'map#setMyLocationStyle',
        'map#moveToMyLocation',
        'map#getMyLocation',
      ]),
    );
    expect(fix?.latitude, 39.9);
    expect(fix?.longitude, 116.4);

    setHandler(channel, null);
  });

  test('GaodeMapController routes marker calls through per-view channel', () async {
    const channel = MethodChannel('xue_hua_gaode_map/map_7');
    String? method;
    setHandler(channel, (MethodCall call) async {
      method = call.method;
      return null;
    });

    final controller = GaodeMapController.init(7);
    await controller.addMarker(
      const GaodeMapMarker(
        id: 'm1',
        position: GaodeCoordinate(latitude: 39.9, longitude: 116.4),
      ),
    );

    expect(method, 'map#addMarker');

    setHandler(channel, null);
  });

  test('OfflineMapProgressEvent.fromMap parses paused status', () {
    final event = OfflineMapProgressEvent.fromMap({
      'cityCode': '110000',
      'cityName': '北京市',
      'status': 'paused',
      'completePercent': 10,
    });
    expect(event.status, OfflineMapDownloadStatus.paused);
    expect(event.completePercent, 10);
  });

  test('GaodeMyLocationStyle.toMap serializes tracking and colors', () {
    const style = GaodeMyLocationStyle(
      type: GaodeMyLocationType.follow,
      trackingMode: GaodeUserTrackingMode.followWithHeading,
      interval: 2000,
      strokeColor: 0xFF0000FF,
      fillColor: 0x330000FF,
    );
    final map = style.toMap();
    expect(map['type'], 'follow');
    expect(map['trackingMode'], 'followWithHeading');
    expect(map['interval'], 2000);
    expect(map['strokeColor'], 0xFF0000FF);
  });

  test('GaodeMapEvent.fromMap parses myLocationChange', () {
    final event = GaodeMapEvent.fromMap({
      'type': 'myLocationChange',
      'coordinate': {'latitude': 39.9, 'longitude': 116.4},
      'accuracy': 12.5,
      'bearing': 90.0,
    });
    expect(event, isA<GaodeMapMyLocationChangeEvent>());
    final loc = event as GaodeMapMyLocationChangeEvent;
    expect(loc.coordinate.latitude, 39.9);
    expect(loc.accuracy, 12.5);
    expect(loc.bearing, 90.0);
  });

  test('GaodeMapEvent.fromMap parses userTrackingModeChange', () {
    final event = GaodeMapEvent.fromMap({
      'type': 'userTrackingModeChange',
      'mode': 'follow',
    });
    expect(event, isA<GaodeMapUserTrackingModeChangeEvent>());
    expect(
      (event as GaodeMapUserTrackingModeChangeEvent).mode,
      GaodeUserTrackingMode.follow,
    );
  });
}
