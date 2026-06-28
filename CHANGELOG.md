# Changelog

All notable changes to this project are documented in this file.

## 1.1.1

### Fixed

- iOS compile errors against AMap3DMap 11.x: unwrap optional `MATileOverlay(urlTemplate:)`
  and remove invalid `MAOverlayRenderer.zIndex` (not present in the 3D SDK).
- iOS compile errors for optional overlay initializers (`MAPolyline`, `MAPolygon`, etc.).
- iOS SDK compatibility: remove `AMapLocationReGeocode.floor` and offline-map `.pause`
  status cases not present in current AMap SDK versions.

### Changed

- iOS overlay `zIndex` is applied via `MAMapView.insertOverlay(_:at:level:)` insert
  order (ground overlays use `MAOverlayLevelAboveRoads`; others use
  `MAOverlayLevelAboveLabels`), aligning stacking behavior with Android.
- iOS marker `zIndex` is applied on `MAAnnotationView` in `viewFor annotation`.
- iOS tile overlay `visible` alpha is applied in `rendererFor`.

## 1.1.0

### Added

- Full Gaode 3D map Dart API: camera controls (`getCameraPosition`, `animateCamera`,
  `fitBounds`, `setMapRegionLimits`, `zoomIn`/`zoomOut`), display toggles (traffic,
  buildings, indoor, terrain, compass, scale, logo), markers with custom icons and drag
  events, and overlay types (polyline, polygon, circle, arc, ground, heatmap, multi-point,
  tile).
- Per-view `EventChannel` map events including `GaodeMapInfoWindowTapEvent`.
- `OfflineMapClient` for offline city catalog, download management, and progress stream.
- Map tools: `takeSnapshot`, `toScreenLocation`, `fromScreenLocation`.
- Example app map tab demos: traffic, animated camera, overlays, fit bounds, ground
  overlay, heatmap, and offline catalog probe.
- **Location SDK:** `LocationOptions` fields `gpsFirst`, `gpsFirstTimeout`, `sensorEnable`
  (Android), and `locationTimeout` / `reGeocodeTimeout` (iOS). Android now maps `protocol`
  and `wifiActiveScan` (via `setWifiScan`) correctly.
- **Map my-location:** `GaodeMyLocationStyle`, `GaodeMyLocationType`,
  `GaodeUserTrackingMode`, `setMyLocationStyle`, `getMyLocation`, `moveToMyLocation`.
- Map events: `GaodeMapMyLocationChangeEvent`, `GaodeMapUserTrackingModeChangeEvent` (iOS).  

### Fixed

- Wired `GaodeMapMarker.infoWindowEnabled` and native `infoWindowTap` events on Android
  and iOS.
- iOS `animateCamera` bearing/tilt duration; `fitBounds` padding via
  `setVisibleMapRect(_:edgePadding:animated:)`.
- iOS polyline `dottedLine` via `MALineDashType`.
- Android compile issues (`setMapStatusLimits`, logo/zoom position constants, offline map
  `getcompleteCode()`).
- iOS `OfflineMapHandler` and overlay APIs aligned with AMap iOS SDK.
- Android `takeSnapshot` replying twice to Flutter.
- Android map lifecycle registry leak on platform view dispose.
- Android offline map progress events marshalled on the main thread.
- Android clearing map region limits when `setMapRegionLimits(null)` is called.
- Android heatmap `opacity` applied via tile provider transparency.
- iOS search handlers double-replying when privacy or API key checks fail.
- iOS geofence handlers hanging when `clientId` is missing.
- iOS custom marker anchor offset calculation.
- iOS offline map `pause` no longer calls `cancelAll()` when a city is not found.
- iOS overlay `visible` / `zIndex`, tile `tileSize`, initial `regionLimits`, and offline
  `"paused"` status wiring.
- iOS `LocationResult` no longer hard-codes `locationType`; enriches re-geocode fields when
  available.
- Android `moveToMyLocation` restores the configured `myLocationStyle` after a temporary
  one-shot locate when no fix was cached.
- iOS `setMyLocationEnabled(true)` re-applies my-location representation and tracking mode.
- Android `LocationOptions.locationPurpose: none` clears the native scene (sets purpose to
  `null`).  

### Removed

- Reserved `clusterEnabled` / `setClusterEnabled` stub API (not implemented in native SDK
  integration).

### Changed

- **Breaking:** Removed reserved `clusterEnabled` / `setClusterEnabled` stub API.
- Map platform channels now return `INVALID_ARGUMENT` for invalid overlay and camera inputs
  instead of silently succeeding.
- iOS `cameraMove` events are emitted continuously during map movement to match Android.

## 1.0.1

* iOS: fix a hard crash when calling location/geofence/search APIs without a configured API key. The plugin now reads `AMapApiKey` from `Info.plist` at startup (matching Android's manifest auto-read), and unconfigured keys surface as a catchable `API_KEY_NOT_CONFIGURED` error instead of crashing the app.
* Docs: clarify iOS API key setup (Info.plist auto-read, `GaodeSdk.setApiKey` runtime override).

## 1.0.0

* First stable release.
* Core: privacy compliance, runtime API key, reverse-geocode language, Android country code.
* Location: single/continuous positioning, location stream, reverse geocoding.
* Geofence: circle/polygon/POI/district fences with create and trigger events.
* Map: native `PlatformView` with camera, map type, my-location dot, and markers.
* Search: POI keyword/around search, input tips, and forward geocoding.
* Consistent error handling: native failures surface as `GaodeException` on both platforms.
