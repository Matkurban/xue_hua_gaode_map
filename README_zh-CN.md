# xue_hua_gaode_map

[English](README.md) | 中文

高德地图 Flutter 插件，封装高德移动端 SDK：定位（单次/连续定位、逆地理编码）、地理围栏、
2D/3D 地图 `PlatformView`，以及搜索服务（POI 搜索、输入提示、地理编码），在 Android 与
iOS 两端提供一致的 Dart API。

## 目录

- [功能](#功能)
- [SDK 版本](#sdk-版本)
- [安装](#安装)
- [平台配置](#平台配置)
  - [Android](#android-配置)
  - [iOS](#ios-配置)
- [权限](#权限)
- [隐私合规（必须）](#隐私合规必须)
- [核心 API：`GaodeSdk`](#核心-apigaodesdk)
- [功能：定位](#功能定位)
- [功能：地理围栏](#功能地理围栏)
- [功能：地图](#功能地图)
- [功能：搜索](#功能搜索)
- [错误处理](#错误处理)
- [平台差异](#平台差异)
- [参考文档](#参考文档)

## 功能

| 模块 | 类 | 作用 |
|------|----|------|
| 核心 | `GaodeSdk` | 隐私合规、ApiKey、逆地理语言、Android 区域码 |
| 定位 | `LocationClient` | 单次定位、连续定位流、逆地理编码 |
| 地理围栏 | `GeofenceClient` | 圆形/多边形/POI/行政区划围栏及事件流 |
| 地图 | `GaodeMapView` / `GaodeMapController` | 原生地图 `PlatformView`：地图类型、定位蓝点、手势开关、相机移动、Marker |
| 搜索 | `SearchClient` | POI 关键字搜索、POI 周边搜索、输入提示（autocomplete）、地理编码（地址→坐标） |

## SDK 版本

插件**不** pin 高德 SDK 版本，始终使用官方最新版：

- **Android：** `com.amap.api:3dmap-location-search`（`latest.integration`）——合包内含
  地图 + 定位/围栏 + 搜索。
- **iOS：** `pod 'AMapLocation'` + `pod 'AMapSearch'` + `pod 'AMap3DMap'`。

> **为什么用 3D 地图合包？** Android 在 Maven 上仅提供包含「地图 + 定位 + 搜索」的 3D
> 合包；独立的 `map2d` / `search` / `location` 包会在 `com.amap.apis.utils.core` 上产生
> 重复类，无法共存。iOS 选用模块化的 `AMap3DMap`（`AMap2DMap` 的 `MAMapKit.framework`
> 非模块化，Swift 无法 `import`）。两端 Dart API 与行为一致。
>
> 隐私合规**一次性**配置即可覆盖定位、地图、搜索三类 SDK（插件内部会同时调用各 SDK 的
> `updatePrivacyShow` / `updatePrivacyAgree`）。

升级 SDK 后请查阅
[Android 更新日志](https://developer.amap.com/api/android-location-sdk/changelog) 与
[iOS 更新日志](https://lbs.amap.com/api/ios-location-sdk/changelog)。

## 安装

在宿主 App 的 `pubspec.yaml` 中添加依赖。推荐使用 `permission_handler` 申请运行时定位
权限（本插件不会替你申请）：

```yaml
dependencies:
  xue_hua_gaode_map: ^1.0.0
  permission_handler: ^11.3.1
```

然后执行：

```bash
flutter pub get
```

## 平台配置

### Android 配置

1. **API Key** —— 在宿主 `AndroidManifest.xml` 的 `<application>` 节点内：

```xml
<meta-data
    android:name="com.amap.api.v2.apikey"
    android:value="YOUR_AMAP_KEY" />
```

也可在运行时调用 `GaodeSdk.setApiKey('YOUR_AMAP_KEY')`。

2. **权限** —— 插件的 Manifest 已将基础定位权限
   （`ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`）合并到你的 App。

3. **ProGuard / R8** —— 插件已内置高德 keep 规则，Release 构建通常无需额外配置。

### iOS 配置

高德 SDK 仅通过 CocoaPods 分发，需在宿主工程的 `pubspec.yaml` 中关闭 Swift Package
Manager：

```yaml
flutter:
  config:
    enable-swift-package-manager: false
```

在 `ios/Podfile` 中以静态方式链接高德 Framework：

```ruby
use_frameworks! :linkage => :static
```

然后安装 Pod：

```bash
cd ios && pod repo update && pod install
```

1. **API Key** —— 在 `Info.plist` 中：

```xml
<key>AMapApiKey</key>
<string>YOUR_AMAP_KEY</string>
```

插件会在启动时自动从 `Info.plist` 读取 `AMapApiKey` 并设置到 `AMapServices`。也可运行时调用
`GaodeSdk.setApiKey('YOUR_AMAP_KEY')`（运行时设置优先于 `Info.plist`）。

> **注意：** 若未配置 Key（既未在 `Info.plist` 中配置，也未调用 `setApiKey`），定位、地理围栏、
> 搜索等接口会返回 `API_KEY_NOT_CONFIGURED` 错误，而不会直接闪退。

> **模拟器限制：** 高德 SDK 不支持 Apple Silicon（arm64）模拟器，请在**真机**上测试
> 定位相关功能。

## 权限

本插件不会自行申请权限，权限流程由宿主 App 负责（例如使用 `permission_handler`）。下表说明
各权限对应的能力。

| 能力 | Android | iOS |
|------|---------|-----|
| 前台定位（单次/连续） | `ACCESS_FINE_LOCATION` 或 `ACCESS_COARSE_LOCATION` | “使用期间”授权 |
| 后台定位 / 后台围栏 | 前台定位权限 + 前台服务 | “始终”授权 + Background Modes → Location updates |

### iOS `Info.plist` 用途描述

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>需要定位以提供位置服务</string>

<!-- 仅后台定位 / 后台围栏监测时需要 -->
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>需要在后台监测地理围栏</string>
```

### iOS `permission_handler` 宏

使用 `permission_handler` 时，需在宿主 `ios/Podfile` 的 `post_install` 中启用定位宏：

```ruby
config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_LOCATION=1'
config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_LOCATION_WHENINUSE=1'
# 后台围栏还需添加：
config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PERMISSION_LOCATION_ALWAYS=1'
```

### iOS 后台围栏

后台围栏监测除“始终”权限外，还需：

1. 在 Xcode 开启 **Background Modes → Location updates**。
2. 在 `GeofenceClient.setActiveActions` 中传入 `allowsBackgroundLocationUpdates: true`。

### 运行时申请权限（示例）

```dart
import 'package:permission_handler/permission_handler.dart';

// 前台
await Permission.locationWhenInUse.request();

// 后台 / 围栏（iOS：在“使用期间”之后再申请“始终”）
await Permission.locationAlways.request();
```

## 隐私合规（必须）

依据高德合规要求，在调用**任何**定位、围栏、地图、搜索 API 之前，**必须**先声明隐私
合规。一对调用即可覆盖全部 SDK：

```dart
await GaodeSdk.updatePrivacyShow(hasContains: true, hasShow: true);
await GaodeSdk.updatePrivacyAgree(hasAgree: true);
```

| 方法 | 参数 | 效果 |
|------|------|------|
| `updatePrivacyShow` | `hasContains` —— 隐私政策包含高德条款；`hasShow` —— 已向用户展示该政策 | 记录已展示合规说明 |
| `updatePrivacyAgree` | `hasAgree` —— 用户已同意 | 记录用户同意；未同意则 SDK 拒绝工作 |

未配置时，原生调用会优雅失败（Android 返回 `PRIVACY_NOT_CONFIGURED` 错误而非崩溃）。详见
[高德合规方案](https://lbs.amap.com/compliance-center/check-and-reference/sdkhgsy)。

## 核心 API：`GaodeSdk`

`GaodeSdk` 是用于一次性配置的静态工具类。

| 方法 | 平台 | 说明 |
|------|------|------|
| `updatePrivacyShow({hasContains, hasShow})` | Android、iOS | 隐私合规（见上） |
| `updatePrivacyAgree({hasAgree})` | Android、iOS | 隐私同意（见上） |
| `setApiKey(String apiKey)` | Android、iOS | 运行时设置 ApiKey；为空抛出 `GaodeException` |
| `setRegionLanguage(GeoLanguage language)` | **仅 iOS** | 逆地理编码输出语言（`AMapServices.regionLanguageType`） |
| `updateCountryCode(String countryCode)` | **仅 Android**（V11.2+） | 海外部署的区域选择；iOS 上为空操作 |

```dart
await GaodeSdk.setApiKey('YOUR_AMAP_KEY');
await GaodeSdk.setRegionLanguage(GeoLanguage.english); // iOS
await GaodeSdk.updateCountryCode('US');                // Android
```

### 通用类型

- **`GaodeCoordinate({required latitude, required longitude})`** —— 经纬度坐标，所有需要
  坐标的地方都用它。
- **`GeoLanguage`** —— `defaultLanguage`、`chinese`、`english`。
- **`GaodeException`** —— 失败时抛出；包含 `message`、`code`（int，平台码为数字时解析得到）
  以及 `platformCode`（原始平台错误字符串）。

## 功能：定位

`LocationClient` 提供单次定位、连续定位流以及独立的逆地理编码。每个实例都有独立的
`clientId`，因此可以同时运行多个互不干扰的客户端。

### 生命周期

| 方法 | 说明 |
|------|------|
| `setOptions(LocationOptions)` | 将配置下发到原生定位器 |
| `getLocation()` | 单次定位，返回 `LocationResult`（失败时抛异常） |
| `start()` | 开始连续定位；通过 `locationStream` 监听 |
| `locationStream` | 广播 `Stream<LocationResult>`；某次更新失败时发出错误 |
| `stop()` | 停止连续定位（dispose 之后调用也安全） |
| `reverseGeocode(GaodeCoordinate)` | 无需完整定位即可将坐标解析为地址 |
| `dispose()` | 停止、释放原生资源并关闭流（幂等） |

```dart
final client = LocationClient();
await client.setOptions(const LocationOptions(needAddress: true));

// 单次定位
final result = await client.getLocation();
print('${result.latitude}, ${result.longitude} —— ${result.address}');

// 连续定位
final sub = client.locationStream.listen((loc) {
  print('更新：${loc.latitude}, ${loc.longitude}');
}, onError: (e) => print('定位错误：$e'));
await client.start();

// …稍后
await sub.cancel();

// 对任意坐标做逆地理编码
final geo = await client.reverseGeocode(
  const GaodeCoordinate(latitude: 39.9, longitude: 116.4),
);
print(geo.address);

await client.dispose();
```

**效果：** `getLocation()` 返回一次尽力而为的定位结果后即完成。`start()` 让定位器持续
运行，并在每次更新（约每 `interval` 毫秒）向 `locationStream` 推送新的 `LocationResult`。
用完务必 `dispose()`，避免泄漏原生定位器。

### `LocationOptions`

所有字段均可选且带有合理默认值。

| 字段 | 默认值 | 效果 |
|------|--------|------|
| `onceLocation` | `false` | 单次定位模式（`getLocation` / `start` 会自动管理） |
| `onceLocationLatest` | `false` | 单次模式下立即返回最近一次缓存定位 |
| `interval` | `2000` | 连续定位间隔（毫秒） |
| `needAddress` | `false` | 结果中是否包含逆地理编码地址字段 |
| `locationMode` | `LocationMode.highAccuracy` | Android 定位策略（见下） |
| `locationPurpose` | `LocationPurpose.none` | 场景提示（`signIn`、`transport`、`sport`）用于优化 |
| `desiredAccuracy` | `DesiredAccuracy.best` | iOS 期望精度等级（见下） |
| `distanceFilter` | `-1` | iOS 触发新更新的最小移动距离（米）；`-1` 表示不过滤 |
| `pausesLocationUpdatesAutomatically` | `false` | iOS：允许系统为省电暂停更新 |
| `allowsBackgroundUpdates` | `false` | iOS：允许后台定位更新 |
| `mockEnable` | `false` | 是否允许模拟定位 |
| `locationCacheEnable` | `true` | 是否允许返回缓存结果 |
| `wifiActiveScan` | `false` | 主动扫描 Wi-Fi 提升精度（更耗电） |
| `httpTimeout` | `30000` | 网络超时（毫秒） |
| `geoLanguage` | `GeoLanguage.defaultLanguage` | 逆地理字段语言 |
| `protocol` | `LocationProtocol.http` | SDK 网络请求使用 `http` 或 `https` |

枚举：

- **`LocationMode`**（Android）—— `highAccuracy`（GPS + 网络）、`batterySaving`
  （仅网络）、`deviceSensors`（仅 GPS）。
- **`LocationPurpose`** —— `none`、`signIn`、`transport`、`sport`。
- **`DesiredAccuracy`**（iOS）—— `best`、`bestForNavigation`、`nearestTenMeters`、
  `kilometer`、`threeKilometers`。
- **`LocationProtocol`** —— `http`、`https`。

`LocationOptions` 不可变，使用 `copyWith(...)` 派生修改后的副本。

### `LocationResult`

由 `getLocation`、`reverseGeocode` 与 `locationStream` 返回。关键字段：

- 位置：`latitude`、`longitude`、`accuracy`、`altitude`、`bearing`、`speed`。
- 地址（`needAddress` 为 true 时）：`address`、`country`、`province`、`city`、
  `district`、`street`、`streetNumber`、`cityCode`、`adCode`、`poiName`、`aoiName`。
- 室内：`buildingId`、`floor`。
- 诊断：`locationType`、`locationDetail`、`gpsAccuracyStatus`、`timestamp`。
- 状态：`errorCode`（`0` 表示成功）、`errorInfo`，以及 `isSuccess` getter。
  当 `errorCode != 0` 时，`throwIfFailed()` 会抛出 `GaodeException`。

## 功能：地理围栏

`GeofenceClient` 监测圆形、多边形、POI 及行政区划区域。添加围栏会立即返回；**创建结果**
通过 `geofenceStream` 的 `createFinished` 事件异步通知，**触发**事件则在设备穿越围栏边界
时发出。

### API

| 方法 | 说明 |
|------|------|
| `setActiveActions(Set<GeofenceAction>, {allowsBackgroundLocationUpdates})` | 选择哪些状态变化触发事件；可选启用 iOS 后台监测 |
| `addCircle({center, radius, customId})` | 添加圆形围栏（半径单位米） |
| `addPolygon({points, customId})` | 用坐标列表添加多边形围栏 |
| `addPoiByKeyword({keyword, poiType, city, size, customId})` | 通过 POI 关键字搜索创建围栏 |
| `addPoiAround({keyword, center, poiType, aroundRadius, size, customId})` | 通过中心点周边 POI 创建围栏 |
| `addDistrict({keyword, customId})` | 添加行政区划围栏 |
| `remove({customId})` / `removeAll()` | 移除指定围栏或全部围栏 |
| `pause()` / `resume()` | 暂停或恢复监测 |
| `geofenceStream` | 广播 `Stream<GeofenceEvent>`，包含创建/触发事件 |
| `dispose()` | 移除全部围栏并释放原生资源（幂等） |

```dart
final geofence = GeofenceClient();

// 进入 + 离开；在 iOS 上启用后台监测
await geofence.setActiveActions(
  {GeofenceAction.enter, GeofenceAction.exit},
  allowsBackgroundLocationUpdates: true,
);

geofence.geofenceStream.listen((event) {
  if (event.isCreateFinished) {
    print('创建 "${event.customId}"：success=${event.success}, '
        'count=${event.count}, error=${event.errorCode}');
  } else if (event.isTrigger) {
    print('触发 "${event.customId}"：${event.status}');
  }
});

await geofence.addCircle(
  center: const GaodeCoordinate(latitude: 39.9, longitude: 116.4),
  radius: 500,
  customId: 'office',
);

// …稍后
await geofence.dispose();
```

### 事件与枚举类型

- **`GeofenceAction`** —— `enter`、`exit`、`stayed`。将关心的集合传给 `setActiveActions`。
- **`GeofenceEvent`** —— 用 `isTrigger` / `isCreateFinished` 区分事件类型。
  - `createFinished` 时：`success`（bool）、`count`（创建的区域数）、`errorCode`、
    `customId`。
  - `trigger` 时：`status`（`GeofenceTriggerStatus`）、`customId`、`fenceId`。
- **`GeofenceTriggerStatus`** —— `unknown`、`inside`、`outside`、`stayed`。

**效果：** 添加围栏的调用是“即发即忘”的；围栏是否真正注册成功，只能通过其
`createFinished` 事件得知。每当设备穿越某个已启用动作的监测边界时，就会发出触发事件。
配置后台监测后，App 处于后台时仍会持续触发。

> **Android 后台限制：** 触发事件通过运行时注册的 `BroadcastReceiver` 投递（绑定到当前
> 进程）。App 退到后台、进程仍存活时可正常收到围栏事件；但一旦**进程被系统杀死**，事件流
> 会停止，重新进入 App 后才会恢复。如需进程被杀后仍接收围栏事件，需在宿主侧自行实现静态
> 注册的 `BroadcastReceiver` 或前台服务。iOS 的围栏监测由系统在后台维持（需“始终”权限与
> Background Modes → Location updates）。

## 功能：地图

`GaodeMapView` 以 `PlatformView` 形式嵌入原生高德地图。**挂载前必须先完成隐私合规配置。**
该视图仅支持 Android 与 iOS。

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
  ),
  onMapCreated: (c) => controller = c,
);
```

构造参数：

- `options` —— 初始 `GaodeMapOptions`（见下）。
- `onMapCreated` —— 平台视图创建完成后回调，返回 `GaodeMapController`。
- `gestureRecognizers` —— 需要与平台视图争夺手势的识别器（地图位于可滚动组件内时有用）。

### `GaodeMapOptions`

| 字段 | 默认值 | 效果 |
|------|--------|------|
| `initialCamera` | 北京 | 初始 `CameraPosition` |
| `mapType` | `GaodeMapType.normal` | 视觉样式 |
| `myLocationEnabled` | `false` | 显示定位蓝点（需定位权限） |
| `zoomGesturesEnabled` | `true` | 允许双指缩放 |
| `scrollGesturesEnabled` | `true` | 允许拖动 |
| `rotateGesturesEnabled` | `true` | 允许旋转 |
| `tiltGesturesEnabled` | `true` | 允许俯仰 |

- **`GaodeMapType`** —— `normal`（白天矢量）、`satellite`（卫星影像）、`night`
  （夜间矢量）。
- **`CameraPosition({required target, zoom = 16})`** —— `target` 为中心坐标；`zoom`
  大致取值 3（世界）至 19（街道）。

### `GaodeMapController`

由 `onMapCreated` 获取，所有方法返回 `Future`。

| 方法 | 效果 |
|------|------|
| `moveCamera(CameraPosition)` | 重新定位 / 缩放相机 |
| `setMapType(GaodeMapType)` | 切换视觉样式 |
| `setMyLocationEnabled(bool)` | 切换定位蓝点 |
| `addMarker(GaodeMapMarker)` | 添加或按 `id` 替换 Marker |
| `removeMarker(String id)` | 按 id 移除 Marker |
| `clearMarkers()` | 移除全部 Marker |

```dart
await controller?.moveCamera(
  const CameraPosition(
    target: GaodeCoordinate(latitude: 39.9, longitude: 116.4),
    zoom: 17,
  ),
);
await controller?.setMapType(GaodeMapType.satellite);
await controller?.addMarker(
  const GaodeMapMarker(
    id: 'm1',
    position: GaodeCoordinate(latitude: 39.9, longitude: 116.4),
    title: '天安门',
    snippet: '北京',
  ),
);
```

- **`GaodeMapMarker({required id, required position, title, snippet})`** —— `id` 唯一
  （用相同 id 再次添加会替换 Marker）；`title` / `snippet` 用于点击 Marker 时弹出的
  信息窗。

## 功能：搜索

`SearchClient` 封装高德搜索 SDK。它是 `const` 类，无需管理生命周期；调用前需先完成隐私
合规。

| 方法 | 说明 |
|------|------|
| `searchPoiKeyword({keyword, city, type, page, pageSize})` | POI 关键字搜索，可按城市限定 |
| `searchPoiAround({center, keyword, type, radius, page, pageSize})` | 中心点 `radius` 米范围内的 POI |
| `inputTips({keyword, city})` | 对部分关键字给出输入提示 |
| `geocode({address, city})` | 地理编码：将地址字符串解析为坐标 |

```dart
const search = SearchClient();

// POI 关键字搜索（page 从 1 开始；pageSize 被 SDK 限制为最大 25）
final poi = await search.searchPoiKeyword(keyword: '咖啡', city: '北京');
for (final p in poi.pois) {
  print('${p.name} @ ${p.location?.latitude}, ${p.location?.longitude}');
}
print('总数=${poi.count}, 页数=${poi.pageCount}');

// 周边 POI
final around = await search.searchPoiAround(
  center: const GaodeCoordinate(latitude: 39.9, longitude: 116.4),
  keyword: '咖啡',
  radius: 2000,
);

// 输入提示（autocomplete）
final tips = await search.inputTips(keyword: '咖啡', city: '北京');

// 地理编码（地址 → 坐标）
final geo = await search.geocode(address: '北京市朝阳区望京', city: '北京');
print(geo.geocodes.first.location);
```

当必填的 keyword / address 为空时，`searchPoiKeyword`、`inputTips` 与 `geocode` 会抛出
`GaodeException`。

### 结果模型

- **`PoiSearchResult`** —— `pois`（当前页）、`count`（跨页总数）、`pageCount`。
- **`Poi`** —— `id`、`name`、`address`、`location`、`tel`、`distance`（米，仅周边搜索）、
  `type`、`province`、`city`、`district`、`adCode`。
- **`InputTip`** —— `name`、`district`、`adCode`、`location`（非点位提示如公交线路时可能为
  null）、`address`、`poiId`。
- **`GeocodeResult`** —— `geocodes`；每个 `Geocode` 含 `formattedAddress`、`location`、
  `province`、`city`、`district`、`adCode`、`level`。

## 错误处理

所有原生调用统一经过一个 helper，把 `PlatformException` 映射为 `GaodeException`：

```dart
try {
  final result = await client.getLocation();
  print(result.address);
} on GaodeException catch (e) {
  print('失败（${e.code} / ${e.platformCode}）：${e.message}');
}
```

`LocationResult` 与流错误也会暴露失败信息：检查 `isSuccess` / `errorCode` / `errorInfo`，
或调用 `throwIfFailed()`。客户端 dispose 之后再调用其方法会抛出 `StateError`。

## 平台差异

| API | Android | iOS |
|-----|---------|-----|
| `GaodeSdk.setRegionLanguage` | 通过定位选项传递 | 支持 |
| `GaodeSdk.updateCountryCode` | 支持 | 空操作 |
| `LocationClient.reverseGeocode` | `getReGeoLocation` | AMapSearch 坐标逆地理 |
| `GeofenceClient.setActiveActions(allowsBackgroundLocationUpdates:)` | 忽略 | 控制后台围栏监测 |

## 参考文档

- [Android 获取定位数据](https://lbs.amap.com/api/android-location-sdk/guide/android-location/getlocation)
- [iOS 权限配置](https://lbs.amap.com/api/ios-location-sdk/guide/create-project/permission-description)
- [Android 地理围栏](https://lbs.amap.com/api/android-location-sdk/guide/additional-func/local-geofence)
- [Android 显示地图](https://lbs.amap.com/api/android-sdk/guide/create-map/show-map)
- [iOS 显示地图](https://lbs.amap.com/api/ios-sdk/guide/create-map/show-map)
- [Android 获取 POI 数据](https://lbs.amap.com/api/android-sdk/guide/map-data/poi)
- [高德合规方案](https://lbs.amap.com/compliance-center/check-and-reference/sdkhgsy)
