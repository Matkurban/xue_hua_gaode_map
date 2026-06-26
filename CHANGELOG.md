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
