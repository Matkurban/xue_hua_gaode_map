# xue_hua_gaode_map

English | [中文](README_zh-CN.md)

A Flutter plugin that wraps the Amap (Gaode / 高德) mobile SDKs: location (single &
continuous positioning, reverse geocoding), geofencing, a 2D/3D map `PlatformView`,
and the search service (POI search, input tips, forward geocoding) — all behind a
single, consistent Dart API for both Android and iOS.

## Table of contents

- [Features](#features)
- [SDK versions](#sdk-versions)
- [Installation](#installation)
- [Platform setup](#platform-setup)
  - [Android](#android-setup)
  - [iOS](#ios-setup)
- [Permissions](#permissions)
- [Privacy compliance (mandatory)](#privacy-compliance-mandatory)
- [Core API: `GaodeSdk`](#core-api-gaodesdk)
- [Feature: Location](#feature-location)
- [Feature: Geofencing](#feature-geofencing)
- [Feature: Map](#feature-map)
- [Feature: Search](#feature-search)
- [Error handling](#error-handling)
- [Platform differences](#platform-differences)
- [Reference docs](#reference-docs)

## Features

| Module | Class | What it does |
|--------|-------|--------------|
| Core | `GaodeSdk` | Privacy compliance, API key, reverse-geocode language, Android country code |
| Location | `LocationClient` | Single-shot location, continuous location stream, reverse geocoding |
| Geofencing | `GeofenceClient` | Circle / polygon / POI / district fences plus an event stream |
| Map | `GaodeMapView` / `GaodeMapController` | Native 3D map: layers, camera, markers, overlays, events, snapshot, offline maps |
| Search | `SearchClient` | POI keyword search, POI around search, input tips (autocomplete), forward geocoding (address → coordinate) |

## SDK versions

The plugin does **not** pin a Gaode SDK version; it always pulls the latest official release:

- **Android:** `com.amap.api:3dmap-location-search` (`latest.integration`) — a combined
  bundle that includes map + location/geofence + search.
- **iOS:** `pod 'AMapLocation'` + `pod 'AMapSearch'` + `pod 'AMap3DMap'`.

> **Why the 3D map bundle?** On Android, Maven only ships a combined "map + location +
> search" 3D bundle; the standalone `map2d` / `search` / `location` packages collide on
> `com.amap.apis.utils.core` (duplicate classes) and cannot coexist. On iOS we use the
> modular `AMap3DMap` (`AMap2DMap`'s `MAMapKit.framework` is non-modular and cannot be
> `import`ed from Swift). The Dart API and behavior are identical on both platforms.
>
> A **single** privacy-compliance call covers all three SDK families (location, map,
> search) — internally the plugin forwards `updatePrivacyShow` / `updatePrivacyAgree`
> to each SDK.

After bumping the SDK, review the
[Android changelog](https://developer.amap.com/api/android-location-sdk/changelog) and the
[iOS changelog](https://lbs.amap.com/api/ios-location-sdk/changelog).

## Installation

Add the dependency to your app's `pubspec.yaml`. `permission_handler` is recommended for
requesting runtime location permissions (this plugin does not request them for you):

```yaml
dependencies:
  xue_hua_gaode_map: ^1.0.0
  permission_handler: ^11.3.1
```

Then:

```bash
flutter pub get
```

## Platform setup

### Android setup

1. **API key** — add to the `<application>` block of your host `AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.amap.api.v2.apikey"
    android:value="YOUR_AMAP_KEY" />
```

You can also set it at runtime with `GaodeSdk.setApiKey('YOUR_AMAP_KEY')`.

2. **Permissions** — the plugin's manifest already merges the base location permissions
   (`ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`) into your app.

3. **ProGuard / R8** — the plugin ships Gaode keep-rules; no extra configuration is
   normally required for release builds.

### iOS setup

The Gaode SDK is distributed via CocoaPods only, so disable Swift Package Manager in your
host project's `pubspec.yaml`:

```yaml
flutter:
  config:
    enable-swift-package-manager: false
```

In `ios/Podfile`, link the static Gaode frameworks:

```ruby
use_frameworks! :linkage => :static
```

Then install pods:

```bash
cd ios && pod repo update && pod install
```

1. **API key** — add to `Info.plist`:

```xml
<key>AMapApiKey</key>
<string>YOUR_AMAP_KEY</string>
```

The plugin reads `AMapApiKey` from `Info.plist` automatically at startup and applies it
to `AMapServices`. Alternatively, set it at runtime via
`GaodeSdk.setApiKey('YOUR_AMAP_KEY')` (which takes precedence over the `Info.plist` value).

> **Heads up:** if no key is configured (neither `Info.plist` nor `setApiKey`), location,
> geofence, and search calls fail with an `API_KEY_NOT_CONFIGURED` error instead of crashing
> the app.

> **Simulator limitation:** the Gaode SDK does not support the Apple Silicon (arm64)
> simulator. Test location-related features on a **physical device**.

## Permissions

This plugin never requests permissions itself — the host app owns the permission flow
(e.g. via `permission_handler`). Below is what each permission unlocks.

| Capability | Android | iOS |
|------------|---------|-----|
| Foreground location (single / continuous) | `ACCESS_FINE_LOCATION` or `ACCESS_COARSE_LOCATION` | "When In Use" authorization |
| Background location / background geofencing | foreground permission + foreground service | "Always" authorization + Background Modes → Location updates |

### iOS `Info.plist` usage descriptions

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to provide location services.</string>

<!-- Required only for background location / background geofence monitoring -->
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need to monitor geofences in the background.</string>
```

### iOS `permission_handler` macros

When using `permission_handler`, enable the location macros in the `post_install` block of
your host `ios/Podfile`:

```ruby
config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_LOCATION=1'
config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_LOCATION_WHENINUSE=1'
# For background geofencing, also add:
config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_LOCATION_ALWAYS=1'
```

### iOS background geofencing

For background fence monitoring you must, in addition to "Always" permission:

1. Enable **Background Modes → Location updates** in Xcode.
2. Pass `allowsBackgroundLocationUpdates: true` to `GeofenceClient.setActiveActions`.

### Requesting permission at runtime (example)

```dart
import 'package:permission_handler/permission_handler.dart';

// Foreground
await Permission.locationWhenInUse.request();

// Background / geofencing (iOS: request "Always" after "When In Use")
await Permission.locationAlways.request();
```

## Privacy compliance (mandatory)

Per Gaode's compliance requirements, you **must** declare privacy consent before calling
**any** location, geofence, map, or search API. One pair of calls covers all SDK families:

```dart
await GaodeSdk.updatePrivacyShow(hasContains: true, hasShow: true);
await GaodeSdk.updatePrivacyAgree(hasAgree: true);
```

| Method | Parameters | Effect |
|--------|------------|--------|
| `updatePrivacyShow` | `hasContains` — your privacy policy contains the Gaode terms; `hasShow` — the policy was shown to the user | Records that the compliance notice was presented |
| `updatePrivacyAgree` | `hasAgree` — the user agreed | Records the user's consent; without it the SDK refuses to operate |

If these are not configured, native calls fail gracefully (Android returns a
`PRIVACY_NOT_CONFIGURED` error rather than crashing). See the
[Gaode compliance guide](https://lbs.amap.com/compliance-center/check-and-reference/sdkhgsy).

## Core API: `GaodeSdk`

`GaodeSdk` is a static utility class for one-time configuration.

| Method | Platforms | Description |
|--------|-----------|-------------|
| `updatePrivacyShow({hasContains, hasShow})` | Android, iOS | Privacy compliance (see above) |
| `updatePrivacyAgree({hasAgree})` | Android, iOS | Privacy consent (see above) |
| `setApiKey(String apiKey)` | Android, iOS | Sets the API key at runtime; throws `GaodeException` if empty |
| `setRegionLanguage(GeoLanguage language)` | **iOS only** | Reverse-geocode output language (`AMapServices.regionLanguageType`) |
| `updateCountryCode(String countryCode)` | **Android only** (V11.2+) | Region selection for overseas deployments; no-op on iOS |

```dart
await GaodeSdk.setApiKey('YOUR_AMAP_KEY');
await GaodeSdk.setRegionLanguage(GeoLanguage.english); // iOS
await GaodeSdk.updateCountryCode('US');                // Android
```

### Shared types

- **`GaodeCoordinate({required latitude, required longitude})`** — a lat/lng pair used
  everywhere a coordinate is needed.
- **`GeoLanguage`** — `defaultLanguage`, `chinese`, `english`.
- **`GaodeException`** — thrown on failures; exposes `message`, `code` (int, parsed from
  the platform code when numeric), and `platformCode` (the raw platform error string).

## Feature: Location

`LocationClient` provides single-shot positioning, a continuous location stream, and
standalone reverse geocoding. Each instance has its own `clientId`, so you can run
multiple independent clients.

### Lifecycle

| Method | Description |
|--------|-------------|
| `setOptions(LocationOptions)` | Push configuration to the native locator |
| `getLocation()` | One-shot fix; returns a `LocationResult` (throws on failure) |
| `start()` | Begin continuous updates; listen via `locationStream` |
| `locationStream` | Broadcast `Stream<LocationResult>`; emits an error if an update fails |
| `stop()` | Stop continuous updates (safe to call after dispose) |
| `reverseGeocode(GaodeCoordinate)` | Resolve a coordinate to an address without a full fix |
| `dispose()` | Stop, release native resources, and close the stream (idempotent) |

```dart
final client = LocationClient();
await client.setOptions(const LocationOptions(needAddress: true));

// Single-shot
final result = await client.getLocation();
print('${result.latitude}, ${result.longitude} — ${result.address}');

// Continuous
final sub = client.locationStream.listen((loc) {
  print('update: ${loc.latitude}, ${loc.longitude}');
}, onError: (e) => print('location error: $e'));
await client.start();

// ... later
await sub.cancel();

// Reverse geocode any coordinate
final geo = await client.reverseGeocode(
  const GaodeCoordinate(latitude: 39.9, longitude: 116.4),
);
print(geo.address);

await client.dispose();
```

**Effect:** `getLocation()` returns a single best-effort fix and completes. `start()` keeps
the locator running and pushes a new `LocationResult` to `locationStream` on every update
(roughly every `interval` ms). Always `dispose()` when done to avoid leaking the native
locator.

### `LocationOptions`

All fields are optional and have sensible defaults.

| Field | Default | Effect |
|-------|---------|--------|
| `onceLocation` | `false` | Single-fix mode (managed automatically by `getLocation` / `start`) |
| `onceLocationLatest` | `false` | Return the latest cached fix immediately in once mode |
| `interval` | `2000` | Continuous update interval in milliseconds |
| `needAddress` | `false` | Include reverse-geocoded address fields in the result |
| `locationMode` | `LocationMode.highAccuracy` | Android positioning strategy (see below) |
| `locationPurpose` | `LocationPurpose.none` | Scenario hint (`signIn`, `transport`, `sport`) for tuning |
| `desiredAccuracy` | `DesiredAccuracy.best` | iOS desired accuracy class (see below) |
| `distanceFilter` | `-1` | iOS minimum movement (meters) before a new update; `-1` = no filter |
| `pausesLocationUpdatesAutomatically` | `false` | iOS: allow the system to pause updates to save power |
| `allowsBackgroundUpdates` | `false` | iOS: allow location updates while backgrounded |
| `mockEnable` | `false` | Allow mock/simulated locations |
| `locationCacheEnable` | `true` | Allow returning cached results |
| `wifiActiveScan` | `false` | Actively scan Wi-Fi for better accuracy (more power) |
| `httpTimeout` | `30000` | Network timeout in milliseconds |
| `geoLanguage` | `GeoLanguage.defaultLanguage` | Language of reverse-geocoded fields |
| `protocol` | `LocationProtocol.http` | `http` or `https` for SDK network calls |

Enums:

- **`LocationMode`** (Android) — `highAccuracy` (GPS + network), `batterySaving`
  (network only), `deviceSensors` (GPS only).
- **`LocationPurpose`** — `none`, `signIn`, `transport`, `sport`.
- **`DesiredAccuracy`** (iOS) — `best`, `bestForNavigation`, `nearestTenMeters`,
  `kilometer`, `threeKilometers`.
- **`LocationProtocol`** — `http`, `https`.

`LocationOptions` is immutable; use `copyWith(...)` to derive a modified copy.

### `LocationResult`

Returned by `getLocation`, `reverseGeocode`, and `locationStream`. Key fields:

- Position: `latitude`, `longitude`, `accuracy`, `altitude`, `bearing`, `speed`.
- Address (when `needAddress` is true): `address`, `country`, `province`, `city`,
  `district`, `street`, `streetNumber`, `cityCode`, `adCode`, `poiName`, `aoiName`.
- Indoor: `buildingId`, `floor`.
- Diagnostics: `locationType`, `locationDetail`, `gpsAccuracyStatus`, `timestamp`.
- Status: `errorCode` (`0` = success), `errorInfo`, and the `isSuccess` getter.
  `throwIfFailed()` throws a `GaodeException` when `errorCode != 0`.

## Feature: Geofencing

`GeofenceClient` monitors circular, polygon, POI, and administrative-district regions.
Adding a fence returns immediately; the **creation result** arrives asynchronously via the
`geofenceStream` as a `createFinished` event, and **trigger** events arrive as the device
crosses fence boundaries.

### API

| Method | Description |
|--------|-------------|
| `setActiveActions(Set<GeofenceAction>, {allowsBackgroundLocationUpdates})` | Choose which transitions emit events; opt into iOS background monitoring |
| `addCircle({center, radius, customId})` | Add a circular fence (radius in meters) |
| `addPolygon({points, customId})` | Add a polygon fence from a list of coordinates |
| `addPoiByKeyword({keyword, poiType, city, size, customId})` | Build fences from a POI keyword search |
| `addPoiAround({keyword, center, poiType, aroundRadius, size, customId})` | Build fences from POIs near a center |
| `addDistrict({keyword, customId})` | Add a fence for an administrative district |
| `remove({customId})` / `removeAll()` | Remove a specific fence or all fences |
| `pause()` / `resume()` | Pause or resume monitoring |
| `geofenceStream` | Broadcast `Stream<GeofenceEvent>` of create/trigger events |
| `dispose()` | Remove all fences and release native resources (idempotent) |

```dart
final geofence = GeofenceClient();

// Enter + exit transitions; enable background monitoring on iOS
await geofence.setActiveActions(
  {GeofenceAction.enter, GeofenceAction.exit},
  allowsBackgroundLocationUpdates: true,
);

geofence.geofenceStream.listen((event) {
  if (event.isCreateFinished) {
    print('created "${event.customId}": success=${event.success}, '
        'count=${event.count}, error=${event.errorCode}');
  } else if (event.isTrigger) {
    print('trigger "${event.customId}": ${event.status}');
  }
});

await geofence.addCircle(
  center: const GaodeCoordinate(latitude: 39.9, longitude: 116.4),
  radius: 500,
  customId: 'office',
);

// ... later
await geofence.dispose();
```

### Event & enum types

- **`GeofenceAction`** — `enter`, `exit`, `stayed`. Pass the set you care about to
  `setActiveActions`.
- **`GeofenceEvent`** — `isTrigger` / `isCreateFinished` discriminate the event type.
  - On `createFinished`: `success` (bool), `count` (regions created), `errorCode`,
    `customId`.
  - On `trigger`: `status` (a `GeofenceTriggerStatus`), `customId`, `fenceId`.
- **`GeofenceTriggerStatus`** — `unknown`, `inside`, `outside`, `stayed`.

**Effect:** add-fence calls are fire-and-forget; you learn whether a fence was actually
registered only from its `createFinished` event. Trigger events fire whenever the device
crosses a monitored boundary for an enabled action. With background monitoring configured,
triggers continue to fire while the app is backgrounded.

> **Android background limitation:** trigger events are delivered through a runtime-registered
> `BroadcastReceiver` bound to the current process. Events arrive while the app is backgrounded
> as long as the process is alive, but once the **process is killed by the system** the stream
> stops until the app is reopened. To keep receiving fence events after process death, implement
> a statically-registered `BroadcastReceiver` or a foreground service in the host app. On iOS the
> system maintains geofence monitoring in the background (requires "Always" permission and
> Background Modes -> Location updates).

## Feature: Map

`GaodeMapView` embeds a native Gaode 3D map as a `PlatformView`. **Privacy compliance must be
configured before the widget mounts.** The view is supported on Android and iOS only.

### `GaodeMapView`

```dart
GaodeMapController? controller;

GaodeMapView(
  options: const GaodeMapOptions(
    initialCamera: CameraPosition(
      target: GaodeCoordinate(latitude: 39.909187, longitude: 116.397451),
      zoom: 16,
    ),
    mapType: GaodeMapType.normal,
    myLocationEnabled: true,
    trafficEnabled: false,
    buildingsEnabled: true,
  ),
  onMapCreated: (c) {
    controller = c;
    c.events.listen((event) {
      if (event is GaodeMapTapEvent) {
        print('tapped ${event.coordinate}');
      }
    });
  },
);
```

### `GaodeMapOptions`

| Field | Default | Effect |
|-------|---------|--------|
| `initialCamera` | Beijing | Starting `CameraPosition` (target, zoom, bearing, tilt) |
| `mapType` | `normal` | `normal`, `satellite`, `night`, `navi`, `bus` (bus: Android only) |
| `myLocationEnabled` | `false` | Show the my-location dot |
| `myLocationIcon` | `null` | Custom PNG icon for the my-location dot |
| `myLocationButtonEnabled` | `false` | Native locate button (**Android only**) |
| `zoomControlsEnabled` | `false` | Native +/- buttons (**Android only**) |
| `zoomControlsPosition` | `rightBottom` | Zoom button preset position (**Android only**) |
| `zoomGesturesEnabled` | `true` | Pinch zoom |
| `scrollGesturesEnabled` | `true` | Pan |
| `rotateGesturesEnabled` | `true` | Rotation |
| `tiltGesturesEnabled` | `true` | Tilt |
| `trafficEnabled` | `false` | Real-time traffic layer |
| `buildingsEnabled` | `true` | 3D buildings |
| `mapTextEnabled` | `true` | Map labels |
| `indoorEnabled` | `false` | Indoor maps |
| `terrainEnabled` | `false` | 3D terrain (**Android only**; set before MapView creation) |
| `compassEnabled` | `true` | Compass widget |
| `scaleEnabled` | `true` | Scale bar |
| `logoPosition` | `leftBottom` | Logo watermark position |
| `minZoom` / `maxZoom` | `null` | Zoom level limits |
| `regionLimits` | `null` | Geographic bounds the map cannot pan outside |

### `GaodeMapController`

Obtained from `onMapCreated`. Commands return `Future`; events are available via `events`.

**Camera**

| Method | Effect |
|--------|--------|
| `getCameraPosition()` | Read current camera (target, zoom, bearing, tilt) |
| `moveCamera(position, {animated})` | Jump or animate camera |
| `animateCamera(position, {durationMs})` | Animated camera move |
| `fitBounds(bounds, padding, {animated})` | Fit geographic bounds |
| `setMapRegionLimits(bounds?)` | Restrict pannable region |
| `zoomIn()` / `zoomOut()` | Step zoom level |

**Display**

| Method | Effect |
|--------|--------|
| `setMapType` | Switch visual style |
| `setTrafficEnabled` | Toggle traffic layer |
| `setBuildingsEnabled` | Toggle 3D buildings |
| `setMapTextEnabled` | Toggle map labels |
| `setIndoorEnabled` | Toggle indoor maps |
| `setCompassEnabled` / `setScaleEnabled` | Toggle UI widgets |
| `setLogoPosition` | Move logo watermark |
| `setMinMaxZoom` | Set zoom limits |
| `setMyLocationEnabled` / `setMyLocationIcon` | Location dot |
| `setMyLocationButtonEnabled` | Locate button (Android only) |
| `setZoomControlsEnabled` / `setZoomControlsPosition` | Zoom buttons (Android only) |

**Markers**

| Method | Effect |
|--------|--------|
| `addMarker(GaodeMapMarker)` | Add or replace marker by `id` |
| `removeMarker(id)` / `clearMarkers()` | Remove markers |
| `showInfoWindow(id)` / `hideInfoWindow(id)` | Control callout |

`GaodeMapMarker` supports `icon` (`GaodeMapImage`), `rotation`, `alpha`, `draggable`,
`visible`, `flat`, `zIndex`, `infoWindowEnabled`, plus `title` / `snippet`.

**Overlays**

| Type | add / remove / clear |
|------|---------------------|
| `GaodeMapPolyline` | `addPolyline` / `removePolyline` / `clearPolylines` |
| `GaodeMapPolygon` | `addPolygon` / `removePolygon` / `clearPolygons` |
| `GaodeMapCircle` | `addCircle` / `removeCircle` / `clearCircles` |
| `GaodeMapArc` | `addArc` / `removeArc` / `clearArcs` |
| `GaodeMapGroundOverlay` | `addGroundOverlay` / `removeGroundOverlay` / `clearGroundOverlays` |
| `GaodeMapHeatmap` | `addHeatmap` / `removeHeatmap` / `clearHeatmaps` |
| `GaodeMapMultiPoint` | `addMultiPoint` / `removeMultiPoint` / `clearMultiPoints` |
| `GaodeMapTileOverlay` | `addTileOverlay` / `removeTileOverlay` / `clearTileOverlays` |

`clearOverlays()` removes every overlay type at once. Colors are Flutter-style ARGB ints
(e.g. `0xFF2196F3`). Tile overlays use URL templates with `{x}`, `{y}`, `{z}` placeholders.

**Tools**

| Method | Effect |
|--------|--------|
| `takeSnapshot()` | PNG screenshot bytes |
| `toScreenLocation(coordinate)` | Lat/lng → screen point |
| `fromScreenLocation(point)` | Screen point → lat/lng |

**Events** (`controller.events`)

`GaodeMapTapEvent`, `GaodeMapLongPressEvent`, `GaodeMapCameraMoveStartEvent`,
`GaodeMapCameraMoveEvent`, `GaodeMapCameraMoveEndEvent`, `GaodeMapMarkerTapEvent`,
`GaodeMapMarkerDragEvent`, `GaodeMapInfoWindowTapEvent`.

### Offline maps: `OfflineMapClient`

```dart
final offline = OfflineMapClient();
await offline.setStoragePath('/path/to/offline'); // Android only

offline.progressStream.listen((e) {
  print('${e.cityName}: ${e.status} ${e.completePercent}%');
});

final cities = await offline.getCityList();
await offline.downloadByCityCode('110000');
```

| Method | Description |
|--------|-------------|
| `setStoragePath` | Android offline storage directory |
| `getCityList()` | Downloadable city catalog |
| `downloadByCityCode` / `downloadByCityName` | Start download |
| `pause` / `resume` / `remove` | Manage tasks |
| `getDownloadStatus(cityCode)` | Query status |
| `progressStream` | Download progress events |
| `dispose()` | Release native resources |

## Feature: Search

`SearchClient` wraps the Amap Search SDK. It is a `const` class with no lifecycle to
manage; privacy compliance must be configured first.

| Method | Description |
|--------|-------------|
| `searchPoiKeyword({keyword, city, type, page, pageSize})` | Keyword POI search, optionally scoped to a city |
| `searchPoiAround({center, keyword, type, radius, page, pageSize})` | POIs within `radius` meters of a center |
| `inputTips({keyword, city})` | Autocomplete suggestions for a partial keyword |
| `geocode({address, city})` | Forward geocode: resolve an address string to coordinates |

```dart
const search = SearchClient();

// Keyword POI search (page is 1-based; pageSize capped at 25 by the SDK)
final poi = await search.searchPoiKeyword(keyword: 'coffee', city: 'Beijing');
for (final p in poi.pois) {
  print('${p.name} @ ${p.location?.latitude}, ${p.location?.longitude}');
}
print('total=${poi.count}, pages=${poi.pageCount}');

// POI around a coordinate
final around = await search.searchPoiAround(
  center: const GaodeCoordinate(latitude: 39.9, longitude: 116.4),
  keyword: 'coffee',
  radius: 2000,
);

// Input tips (autocomplete)
final tips = await search.inputTips(keyword: 'coff', city: 'Beijing');

// Forward geocode (address → coordinate)
final geo = await search.geocode(address: 'Wangjing, Chaoyang, Beijing', city: 'Beijing');
print(geo.geocodes.first.location);
```

`searchPoiKeyword`, `inputTips`, and `geocode` throw a `GaodeException` if the required
keyword / address is empty.

### Result models

- **`PoiSearchResult`** — `pois` (this page), `count` (total across pages), `pageCount`.
- **`Poi`** — `id`, `name`, `address`, `location`, `tel`, `distance` (meters, around
  search only), `type`, `province`, `city`, `district`, `adCode`.
- **`InputTip`** — `name`, `district`, `adCode`, `location` (may be null for non-point
  tips like bus lines), `address`, `poiId`.
- **`GeocodeResult`** — `geocodes`; each `Geocode` has `formattedAddress`, `location`,
  `province`, `city`, `district`, `adCode`, `level`.

## Error handling

All native calls funnel through a single helper that maps `PlatformException` to
`GaodeException`:

```dart
try {
  final result = await client.getLocation();
  print(result.address);
} on GaodeException catch (e) {
  print('failed (${e.code} / ${e.platformCode}): ${e.message}');
}
```

`LocationResult` and stream errors also surface failures: check `isSuccess` /
`errorCode` / `errorInfo`, or call `throwIfFailed()`. After a client is disposed, further
calls throw a `StateError`.

## Platform differences

| API | Android | iOS |
|-----|---------|-----|
| `GaodeSdk.setRegionLanguage` | Passed through location options | Supported |
| `GaodeSdk.updateCountryCode` | Supported | No-op |
| `LocationClient.reverseGeocode` | `getReGeoLocation` | AMapSearch coordinate-based reverse geocode |
| `GeofenceClient.setActiveActions(allowsBackgroundLocationUpdates:)` | Ignored | Controls background fence monitoring |
| `GaodeMapOptions.myLocationIcon` | Supported | Supported |
| `GaodeMapOptions.myLocationButtonEnabled` | Native locate button | Not available (no-op) |
| `GaodeMapOptions.zoomControlsEnabled` / `zoomControlsPosition` | Native +/- buttons (preset positions only) | Not available (no-op) |
| `GaodeMapOptions.terrainEnabled` | Supported (before MapView creation) | Not available |
| `GaodeMapType.bus` | Supported | Falls back to standard |
| `OfflineMapClient.setStoragePath` | Required for Android offline storage | No-op |

Native SDKs do **not** support custom icons or arbitrary positions for the locate / zoom
buttons. Only the my-location **dot** and **markers** can use custom PNG icons via `GaodeMapImage`.

## Reference docs

- [Android: get location data](https://lbs.amap.com/api/android-location-sdk/guide/android-location/getlocation)
- [iOS: permission configuration](https://lbs.amap.com/api/ios-location-sdk/guide/create-project/permission-description)
- [Android: local geofencing](https://lbs.amap.com/api/android-location-sdk/guide/additional-func/local-geofence)
- [Android: show a map](https://lbs.amap.com/api/android-sdk/guide/create-map/show-map)
- [Android: my-location dot](https://lbs.amap.com/api/android-sdk/guide/create-map/mylocation)
- [iOS: my-location dot](https://lbs.amap.com/api/ios-sdk/guide/create-map/location-map)
- [Android: map controls](https://lbs.amap.com/api/android-sdk/guide/interaction-with-map/control-interaction)
- [iOS: show a map](https://lbs.amap.com/api/ios-sdk/guide/create-map/show-map)
- [Android: POI data](https://lbs.amap.com/api/android-sdk/guide/map-data/poi)
- [Gaode compliance guide](https://lbs.amap.com/compliance-center/check-and-reference/sdkhgsy)
