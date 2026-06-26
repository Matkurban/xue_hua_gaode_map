import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xue_hua_gaode_map/xue_hua_gaode_map.dart';

void main() {
  runApp(const GaodeMapExampleApp());
}

class GaodeMapExampleApp extends StatelessWidget {
  const GaodeMapExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gaode Location Demo',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  bool _privacyConfigured = false;
  String _permissionStatus = 'unknown';
  String _log = '';

  @override
  void initState() {
    super.initState();
    _refreshPermissionStatus();
  }

  Future<void> _refreshPermissionStatus() async {
    final status = await Permission.locationWhenInUse.status;
    setState(() {
      _permissionStatus = status.toString();
    });
  }

  void _appendLog(String message) {
    setState(() {
      _log = '$message\n$_log';
    });
  }

  Future<void> _configurePrivacy() async {
    await GaodeSdk.updatePrivacyShow(hasContains: true, hasShow: true);
    await GaodeSdk.updatePrivacyAgree(hasAgree: true);
    setState(() => _privacyConfigured = true);
    _appendLog('Privacy compliance configured');
  }

  Future<void> _requestPermission() async {
    final status = await Permission.locationWhenInUse.request();
    setState(() => _permissionStatus = status.toString());
    _appendLog('Permission status: $status');
  }

  Future<void> _requestAlwaysPermission() async {
    final status = await Permission.locationAlways.request();
    setState(() => _permissionStatus = status.toString());
    _appendLog('Always permission status: $status');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gaode Location Demo'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Init'),
              Tab(text: 'Location'),
              Tab(text: 'Geofence'),
              Tab(text: 'Map'),
              Tab(text: 'Search'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _InitTab(
              privacyConfigured: _privacyConfigured,
              permissionStatus: _permissionStatus,
              onConfigurePrivacy: _configurePrivacy,
              onRequestPermission: _requestPermission,
              onRequestAlwaysPermission: _requestAlwaysPermission,
              onRefreshPermission: _refreshPermissionStatus,
              onLog: _appendLog,
            ),
            LocationTab(enabled: _privacyConfigured, onLog: _appendLog),
            GeofenceTab(enabled: _privacyConfigured, onLog: _appendLog),
            MapTab(enabled: _privacyConfigured, onLog: _appendLog),
            SearchTab(enabled: _privacyConfigured, onLog: _appendLog),
          ],
        ),
        bottomNavigationBar: Container(
          color: Colors.grey.shade100,
          height: 160,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Text(_log.isEmpty ? 'Logs appear here' : _log),
          ),
        ),
      ),
    );
  }
}

class _InitTab extends StatefulWidget {
  const _InitTab({
    required this.privacyConfigured,
    required this.permissionStatus,
    required this.onConfigurePrivacy,
    required this.onRequestPermission,
    required this.onRequestAlwaysPermission,
    required this.onRefreshPermission,
    required this.onLog,
  });

  final bool privacyConfigured;
  final String permissionStatus;
  final Future<void> Function() onConfigurePrivacy;
  final Future<void> Function() onRequestPermission;
  final Future<void> Function() onRequestAlwaysPermission;
  final Future<void> Function() onRefreshPermission;
  final void Function(String message) onLog;

  @override
  State<_InitTab> createState() => _InitTabState();
}

class _InitTabState extends State<_InitTab> {
  final _apiKeyController = TextEditingController();

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _setApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      widget.onLog('API key is empty');
      return;
    }
    try {
      await GaodeSdk.setApiKey(apiKey);
      widget.onLog('API key set at runtime');
    } catch (e) {
      widget.onLog('setApiKey failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Privacy configured: ${widget.privacyConfigured}'),
          Text('Permission: ${widget.permissionStatus}'),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              labelText: 'Amap API Key (optional runtime override)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _setApiKey,
            child: const Text('Set API key at runtime'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: widget.onConfigurePrivacy,
            child: const Text('Configure privacy compliance'),
          ),
          FilledButton(
            onPressed: widget.onRequestPermission,
            child: const Text('Request when-in-use permission'),
          ),
          FilledButton(
            onPressed: widget.onRequestAlwaysPermission,
            child: const Text('Request always permission (geofence)'),
          ),
          OutlinedButton(
            onPressed: widget.onRefreshPermission,
            child: const Text('Refresh permission status'),
          ),
          const SizedBox(height: 16),
          const Text(
            'You can also configure your Amap API Key in AndroidManifest.xml and Info.plist.',
          ),
        ],
      ),
    );
  }
}

class LocationTab extends StatefulWidget {
  const LocationTab({required this.enabled, required this.onLog, super.key});

  final bool enabled;
  final void Function(String message) onLog;

  @override
  State<LocationTab> createState() => _LocationTabState();
}

class _LocationTabState extends State<LocationTab> {
  late final LocationClient _client;
  StreamSubscription<LocationResult>? _subscription;

  @override
  void initState() {
    super.initState();
    _client = LocationClient();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    unawaited(_client.dispose());
    super.dispose();
  }

  Future<void> _getOnce() async {
    if (!widget.enabled) return;
    try {
      await _client.setOptions(
        const LocationOptions(needAddress: true, onceLocation: true),
      );
      final result = await _client.getLocation();
      widget.onLog(
        'Once: ${result.latitude}, ${result.longitude} ${result.address ?? ''}',
      );
    } catch (e) {
      widget.onLog('Once failed: $e');
    }
  }

  Future<void> _startContinuous() async {
    if (!widget.enabled) return;
    await _subscription?.cancel();
    await _client.setOptions(
      const LocationOptions(needAddress: true, interval: 3000),
    );
    _subscription = _client.locationStream.listen((result) {
      widget.onLog(
        'Stream: ${result.latitude}, ${result.longitude} acc=${result.accuracy}',
      );
    }, onError: (Object e) => widget.onLog('Stream error: $e'));
    await _client.start();
    widget.onLog('Continuous location started');
  }

  Future<void> _stop() async {
    await _client.stop();
    widget.onLog('Location stopped');
  }

  Future<void> _reverseGeocode() async {
    if (!widget.enabled) return;
    try {
      const coordinate = GaodeCoordinate(
        latitude: 39.909187,
        longitude: 116.397451,
      );
      final result = await _client.reverseGeocode(coordinate);
      widget.onLog('ReGeo: ${result.address ?? result.city ?? 'no address'}');
    } catch (e) {
      widget.onLog('ReGeo failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: _getOnce,
            child: const Text('Get location once'),
          ),
          FilledButton(
            onPressed: _startContinuous,
            child: const Text('Start continuous location'),
          ),
          OutlinedButton(onPressed: _stop, child: const Text('Stop location')),
          OutlinedButton(
            onPressed: _reverseGeocode,
            child: const Text('Reverse geocode (Tiananmen)'),
          ),
        ],
      ),
    );
  }
}

class GeofenceTab extends StatefulWidget {
  const GeofenceTab({required this.enabled, required this.onLog, super.key});

  final bool enabled;
  final void Function(String message) onLog;

  @override
  State<GeofenceTab> createState() => _GeofenceTabState();
}

class _GeofenceTabState extends State<GeofenceTab> {
  late final GeofenceClient _client;
  StreamSubscription<GeofenceEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _client = GeofenceClient();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    unawaited(_client.dispose());
    super.dispose();
  }

  Future<void> _setupGeofence() async {
    if (!widget.enabled) return;
    await _subscription?.cancel();
    await _client.setActiveActions({
      GeofenceAction.enter,
      GeofenceAction.exit,
    }, allowsBackgroundLocationUpdates: true);
    _subscription = _client.geofenceStream.listen((event) {
      if (event.isTrigger) {
        widget.onLog('Geofence trigger: ${event.status} ${event.customId}');
      } else if (event.isCreateFinished) {
        widget.onLog(
          'Geofence created: success=${event.success} count=${event.count}',
        );
      }
    });
    await _client.addCircle(
      center: const GaodeCoordinate(latitude: 39.909187, longitude: 116.397451),
      radius: 500,
      customId: 'demo-circle',
    );
    widget.onLog('Circle geofence added around Tiananmen');
  }

  Future<void> _setupPolygonGeofence() async {
    if (!widget.enabled) return;
    await _subscription?.cancel();
    await _client.setActiveActions({
      GeofenceAction.enter,
      GeofenceAction.exit,
    }, allowsBackgroundLocationUpdates: true);
    _subscription = _client.geofenceStream.listen((event) {
      if (event.isTrigger) {
        widget.onLog('Geofence trigger: ${event.status} ${event.customId}');
      } else if (event.isCreateFinished) {
        widget.onLog(
          'Geofence created: success=${event.success} count=${event.count}',
        );
      }
    });
    const center = GaodeCoordinate(latitude: 39.909187, longitude: 116.397451);
    await _client.addPolygon(
      points: [
        const GaodeCoordinate(latitude: 39.9105, longitude: 116.3960),
        const GaodeCoordinate(latitude: 39.9080, longitude: 116.3960),
        const GaodeCoordinate(latitude: 39.9090, longitude: 116.3990),
        center,
      ],
      customId: 'demo-polygon',
    );
    widget.onLog('Polygon geofence added near Tiananmen');
  }

  Future<void> _clearGeofences() async {
    await _client.removeAll();
    widget.onLog('All geofences removed');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: _setupGeofence,
            child: const Text('Add circle geofence & listen'),
          ),
          FilledButton(
            onPressed: _setupPolygonGeofence,
            child: const Text('Add polygon geofence & listen'),
          ),
          OutlinedButton(
            onPressed: _clearGeofences,
            child: const Text('Remove all geofences'),
          ),
        ],
      ),
    );
  }
}

class MapTab extends StatefulWidget {
  const MapTab({required this.enabled, required this.onLog, super.key});

  final bool enabled;
  final void Function(String message) onLog;

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  static const _tiananmen = GaodeCoordinate(
    latitude: 39.909187,
    longitude: 116.397451,
  );

  GaodeMapController? _controller;
  GaodeMapType _mapType = GaodeMapType.normal;
  int _markerSeq = 0;

  void _onMapCreated(GaodeMapController controller) {
    _controller = controller;
    widget.onLog('Map created');
  }

  Future<void> _cycleMapType() async {
    const order = GaodeMapType.values;
    final next = order[(_mapType.index + 1) % order.length];
    setState(() => _mapType = next);
    await _controller?.setMapType(next);
    widget.onLog('Map type: ${next.name}');
  }

  Future<void> _moveToTiananmen() async {
    await _controller?.moveCamera(
      const CameraPosition(target: _tiananmen, zoom: 17),
    );
    widget.onLog('Camera moved to Tiananmen');
  }

  Future<void> _addMarker() async {
    final id = 'marker_${_markerSeq++}';
    await _controller?.addMarker(
      GaodeMapMarker(
        id: id,
        position: _tiananmen,
        title: 'Tiananmen',
        snippet: id,
      ),
    );
    widget.onLog('Marker added: $id');
  }

  Future<void> _clearMarkers() async {
    await _controller?.clearMarkers();
    widget.onLog('Markers cleared');
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Configure privacy compliance first (Init tab).'),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: GaodeMapView(
            options: const GaodeMapOptions(
              initialCamera: CameraPosition(target: _tiananmen, zoom: 16),
              myLocationEnabled: true,
            ),
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
            },
            onMapCreated: _onMapCreated,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilledButton(
                onPressed: _cycleMapType,
                child: const Text('Cycle map type'),
              ),
              FilledButton(
                onPressed: _moveToTiananmen,
                child: const Text('Move camera'),
              ),
              FilledButton(
                onPressed: _addMarker,
                child: const Text('Add marker'),
              ),
              OutlinedButton(
                onPressed: _clearMarkers,
                child: const Text('Clear markers'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SearchTab extends StatefulWidget {
  const SearchTab({required this.enabled, required this.onLog, super.key});

  final bool enabled;
  final void Function(String message) onLog;

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  static const _tiananmen = GaodeCoordinate(
    latitude: 39.909187,
    longitude: 116.397451,
  );

  final _searchClient = const SearchClient();
  final _keywordController = TextEditingController(text: '咖啡');
  final _cityController = TextEditingController(text: '北京');

  @override
  void dispose() {
    _keywordController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _poiKeyword() async {
    if (!widget.enabled) return;
    try {
      final result = await _searchClient.searchPoiKeyword(
        keyword: _keywordController.text.trim(),
        city: _cityController.text.trim(),
      );
      widget.onLog(
        'POI keyword: count=${result.count} first=${result.pois.isEmpty ? '-' : result.pois.first.name}',
      );
    } catch (e) {
      widget.onLog('POI keyword failed: $e');
    }
  }

  Future<void> _poiAround() async {
    if (!widget.enabled) return;
    try {
      final result = await _searchClient.searchPoiAround(
        center: _tiananmen,
        keyword: _keywordController.text.trim(),
        radius: 2000,
      );
      widget.onLog(
        'POI around: count=${result.count} first=${result.pois.isEmpty ? '-' : result.pois.first.name}',
      );
    } catch (e) {
      widget.onLog('POI around failed: $e');
    }
  }

  Future<void> _inputTips() async {
    if (!widget.enabled) return;
    try {
      final tips = await _searchClient.inputTips(
        keyword: _keywordController.text.trim(),
        city: _cityController.text.trim(),
      );
      widget.onLog('Tips: ${tips.take(3).map((t) => t.name).join(', ')}');
    } catch (e) {
      widget.onLog('Input tips failed: $e');
    }
  }

  Future<void> _geocode() async {
    if (!widget.enabled) return;
    try {
      final result = await _searchClient.geocode(
        address: _keywordController.text.trim(),
        city: _cityController.text.trim(),
      );
      final first = result.geocodes.isEmpty ? null : result.geocodes.first;
      widget.onLog(
        'Geocode: ${first == null ? 'no result' : '${first.formattedAddress} (${first.location.latitude}, ${first.location.longitude})'}',
      );
    } catch (e) {
      widget.onLog('Geocode failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _keywordController,
            decoration: const InputDecoration(
              labelText: 'Keyword / address',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: 'City',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _poiKeyword,
            child: const Text('POI keyword search'),
          ),
          FilledButton(
            onPressed: _poiAround,
            child: const Text('POI around (Tiananmen 2km)'),
          ),
          FilledButton(
            onPressed: _inputTips,
            child: const Text('Input tips (autocomplete)'),
          ),
          OutlinedButton(
            onPressed: _geocode,
            child: const Text('Geocode (address -> coordinate)'),
          ),
        ],
      ),
    );
  }
}
