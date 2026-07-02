#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint xue_hua_gaode_map.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'xue_hua_gaode_map'
  s.version          = '1.0.0'
  s.summary          = 'Flutter plugin for Amap (Gaode): location, geofencing, map and search.'
  s.description      = <<-DESC
Flutter plugin wrapping the Gaode (Amap) mobile SDK: location (single/continuous,
reverse geocoding), geofencing, 2D/3D map PlatformView, and search (POI, input
tips, geocoding), with a consistent Dart API across Android and iOS.
                       DESC
  s.homepage         = 'https://github.com/kurban/xue_hua_gaode_map'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'kurban' => '3496354336@qq.com' }
  s.source           = { :path => '.' }
  s.source_files = 'xue_hua_gaode_map/Sources/xue_hua_gaode_map/**/*'
  s.dependency 'Flutter'
  s.dependency 'AMapLocation'
  s.dependency 'AMapSearch'
  s.dependency 'AMap3DMap'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.static_framework = true

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'xue_hua_gaode_map_privacy' => ['xue_hua_gaode_map/Sources/xue_hua_gaode_map/PrivacyInfo.xcprivacy']}
  s.resource_bundles = {'xue_hua_gaode_map_privacy' => ['xue_hua_gaode_map/Sources/xue_hua_gaode_map/PrivacyInfo.xcprivacy']}
end
