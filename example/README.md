# Gaode Location Example

Demonstrates `xue_hua_gaode_map` integration:

1. **Init** — privacy compliance, when-in-use and always location permission
2. **Location** — single fix, continuous stream, coordinate reverse geocode
3. **Geofence** — circle fence with background monitoring enabled on iOS

## Setup

1. Replace placeholder API keys in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist`
2. iOS `permission_handler` macros in `ios/Podfile`:
   - `PERMISSION_LOCATION=1`
   - `PERMISSION_LOCATION_WHENINUSE=1`
   - `PERMISSION_LOCATION_ALWAYS=1` (background geofence demo)
3. Run `flutter pub get` then `cd ios && pod install`

```bash
flutter run
```

Test on a **physical device** — Amap SDK does not support Apple Silicon simulator arm64.

## Background geofence (iOS)

The Geofence tab calls `setActiveActions(..., allowsBackgroundLocationUpdates: true)`.
Request **always** permission on the Init tab before testing background fence events.
