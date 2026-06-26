import Flutter
import UIKit

public class XueHuaGaodeMapPlugin: NSObject, FlutterPlugin {
    private let searchClientManager = SearchClientManager()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        AmapCoreHandler.applyApiKeyFromBundleIfAvailable()
        let instance = XueHuaGaodeMapPlugin()
        let channel = FlutterMethodChannel(name: "xue_hua_gaode_map", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        let locationEvents = FlutterEventChannel(
            name: "xue_hua_gaode_map/location",
            binaryMessenger: registrar.messenger()
        )
        locationEvents.setStreamHandler(LocationStreamHandler())
        
        let geofenceEvents = FlutterEventChannel(
            name: "xue_hua_gaode_map/geofence",
            binaryMessenger: registrar.messenger()
        )
        geofenceEvents.setStreamHandler(GeofenceStreamHandler())
        
        let mapFactory = GaodeMapViewFactory(messenger: registrar.messenger())
        registrar.register(mapFactory, withId: "xue_hua_gaode_map/map")
    }
    
    public func detach(from registrar: FlutterPluginRegistrar) {
        LocationClientRegistry.shared.destroyAll()
        GeofenceClientRegistry.shared.destroyAll()
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "updatePrivacyShow":
            let args = call.arguments as? [String: Any]
            let hasContains = args?["hasContains"] as? Bool ?? false
            let hasShow = args?["hasShow"] as? Bool ?? false
            AmapCoreHandler.updatePrivacyShow(hasContains: hasContains, hasShow: hasShow)
            result(nil)
        case "updatePrivacyAgree":
            let args = call.arguments as? [String: Any]
            let hasAgree = args?["hasAgree"] as? Bool ?? false
            AmapCoreHandler.updatePrivacyAgree(hasAgree: hasAgree)
            result(nil)
        case "setApiKey":
            guard let apiKey = (call.arguments as? [String: Any])?["apiKey"] as? String, !apiKey.isEmpty else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "apiKey is required", details: nil))
                return
            }
            AmapCoreHandler.setApiKey(apiKey)
            result(nil)
        case "setRegionLanguage":
            let language = (call.arguments as? [String: Any])?["language"] as? String ?? "default"
            AmapCoreHandler.setRegionLanguage(language)
            result(nil)
        case "updateCountryCode":
            // iOS uses region settings via AMapServices; country code is Android-only.
            result(nil)
        case "location#setOptions":
            handleLocationSetOptions(call, result: result)
        case "location#start":
            handleLocationStart(call, result: result)
        case "location#stop":
            handleLocationStop(call, result: result)
        case "location#getOnce":
            handleLocationGetOnce(call, result: result)
        case "location#destroy":
            handleLocationDestroy(call, result: result)
        case "location#reverseGeocode":
            handleLocationReverseGeocode(call, result: result)
        case "geofence#setActiveActions":
            handleGeofenceSetActiveActions(call, result: result)
        case "geofence#addCircle":
            handleGeofenceAddCircle(call, result: result)
        case "geofence#addPolygon":
            handleGeofenceAddPolygon(call, result: result)
        case "geofence#addPoiKeyword":
            handleGeofenceAddPoiKeyword(call, result: result)
        case "geofence#addPoiAround":
            handleGeofenceAddPoiAround(call, result: result)
        case "geofence#addDistrict":
            handleGeofenceAddDistrict(call, result: result)
        case "geofence#remove":
            handleGeofenceRemove(call, result: result)
        case "geofence#removeAll":
            handleGeofenceRemoveAll(call, result: result)
        case "geofence#pause":
            handleGeofencePause(call, result: result)
        case "geofence#resume":
            handleGeofenceResume(call, result: result)
        case "geofence#destroy":
            handleGeofenceDestroy(call, result: result)
        case "search#poiKeyword":
            handleSearchPoiKeyword(call, result: result)
        case "search#poiAround":
            handleSearchPoiAround(call, result: result)
        case "search#inputTips":
            handleSearchInputTips(call, result: result)
        case "search#geocode":
            handleSearchGeocode(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleSearchPoiKeyword(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard requirePrivacy(result: result), requireApiKey(result: result),
              let args = call.arguments as? [String: Any],
              let keyword = args["keyword"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "keyword required", details: nil))
            return
        }
        searchClientManager.poiKeyword(
            keyword: keyword,
            city: args["city"] as? String ?? "",
            type: args["type"] as? String ?? "",
            page: args["page"] as? Int ?? 1,
            pageSize: args["pageSize"] as? Int ?? 20,
            result: result
        )
    }
    
    private func handleSearchPoiAround(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard requirePrivacy(result: result), requireApiKey(result: result),
              let args = call.arguments as? [String: Any],
              let latitude = args["latitude"] as? Double,
              let longitude = args["longitude"] as? Double else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "latitude and longitude required", details: nil))
            return
        }
        searchClientManager.poiAround(
            latitude: latitude,
            longitude: longitude,
            keyword: args["keyword"] as? String ?? "",
            type: args["type"] as? String ?? "",
            radius: args["radius"] as? Int ?? 3000,
            page: args["page"] as? Int ?? 1,
            pageSize: args["pageSize"] as? Int ?? 20,
            result: result
        )
    }
    
    private func handleSearchInputTips(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard requirePrivacy(result: result), requireApiKey(result: result),
              let args = call.arguments as? [String: Any],
              let keyword = args["keyword"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "keyword required", details: nil))
            return
        }
        searchClientManager.inputTips(
            keyword: keyword,
            city: args["city"] as? String ?? "",
            result: result
        )
    }
    
    private func handleSearchGeocode(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard requirePrivacy(result: result), requireApiKey(result: result),
              let args = call.arguments as? [String: Any],
              let address = args["address"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "address required", details: nil))
            return
        }
        searchClientManager.geocode(
            address: address,
            city: args["city"] as? String ?? "",
            result: result
        )
    }
    
    private func clientId(from call: FlutterMethodCall) -> String? {
        (call.arguments as? [String: Any])?["clientId"] as? String
    }
    
    private func requirePrivacy(result: @escaping FlutterResult) -> Bool {
        guard AmapPrivacyState.privacyAgreed else {
            result(FlutterError(
                code: "PRIVACY_NOT_CONFIGURED",
                message: AmapPrivacyState.privacyError().localizedDescription,
                details: nil
            ))
            return false
        }
        return true
    }

    private func requireApiKey(result: @escaping FlutterResult) -> Bool {
        guard AmapCoreHandler.isApiKeyConfigured else {
            result(FlutterError(
                code: "API_KEY_NOT_CONFIGURED",
                message: "Amap API key is not configured. Set AMapApiKey in Info.plist or call GaodeSdk.setApiKey(...).",
                details: nil
            ))
            return false
        }
        return true
    }
    
    private func handleLocationSetOptions(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let clientId = clientId(from: call) else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "clientId required", details: nil))
            return
        }
        let options = (call.arguments as? [String: Any])?["options"] as? [String: Any] ?? [:]
        LocationClientRegistry.shared.getOrCreate(clientId: clientId).setOptions(options, result: result)
    }
    
    private func handleLocationStart(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let clientId = clientId(from: call) else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "clientId required", details: nil))
            return
        }
        LocationClientRegistry.shared.getOrCreate(clientId: clientId).start(result: result)
    }
    
    private func handleLocationStop(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let clientId = clientId(from: call) else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "clientId required", details: nil))
            return
        }
        LocationClientRegistry.shared.getOrCreate(clientId: clientId).stop()
        result(nil)
    }
    
    private func handleLocationGetOnce(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let clientId = clientId(from: call) else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "clientId required", details: nil))
            return
        }
        LocationClientRegistry.shared.getOrCreate(clientId: clientId).getOnce(result: result)
    }
    
    private func handleLocationDestroy(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let clientId = clientId(from: call) else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "clientId required", details: nil))
            return
        }
        LocationClientRegistry.shared.destroy(clientId: clientId)
        result(nil)
    }
    
    private func handleLocationReverseGeocode(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let clientId = clientId(from: call),
              let args = call.arguments as? [String: Any],
              let latitude = args["latitude"] as? Double,
              let longitude = args["longitude"] as? Double else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "clientId, latitude, longitude required", details: nil))
            return
        }
        LocationClientRegistry.shared.getOrCreate(clientId: clientId)
            .reverseGeocode(latitude: latitude, longitude: longitude, result: result)
    }
    
    private func handleGeofenceSetActiveActions(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard requirePrivacy(result: result), requireApiKey(result: result),
              let clientId = clientId(from: call) else { return }
        let actions = (call.arguments as? [String: Any])?["actions"] as? [String] ?? ["enter"]
        let allowsBackground =
        (call.arguments as? [String: Any])?["allowsBackgroundLocationUpdates"] as? Bool ?? false
        GeofenceClientRegistry.shared.getOrCreate(clientId: clientId)
            .setActiveActions(actions, allowsBackgroundUpdates: allowsBackground)
        result(nil)
    }
    
    private func handleGeofenceAddCircle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard requirePrivacy(result: result), requireApiKey(result: result),
              let clientId = clientId(from: call),
              let args = call.arguments as? [String: Any],
              let latitude = args["latitude"] as? Double,
              let longitude = args["longitude"] as? Double,
              let radius = args["radius"] as? Double,
              let customId = args["customId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "invalid circle args", details: nil))
            return
        }
        GeofenceClientRegistry.shared.getOrCreate(clientId: clientId)
            .addCircle(latitude: latitude, longitude: longitude, radius: radius, customId: customId)
        result(nil)
    }
    
    private func handleGeofenceAddPolygon(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard requirePrivacy(result: result), requireApiKey(result: result),
              let clientId = clientId(from: call),
              let args = call.arguments as? [String: Any],
              let points = args["points"] as? [[String: Any]],
              let customId = args["customId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "invalid polygon args", details: nil))
            return
        }
        if let validationError = GeofenceClientRegistry.shared
            .getOrCreate(clientId: clientId)
            .addPolygon(points: points, customId: customId) {
            result(FlutterError(code: "INVALID_ARGUMENT", message: validationError, details: nil))
            return
        }
        result(nil)
    }
    
    private func handleGeofenceAddPoiKeyword(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard requirePrivacy(result: result), requireApiKey(result: result),
              let clientId = clientId(from: call),
              let args = call.arguments as? [String: Any],
              let keyword = args["keyword"] as? String,
              let customId = args["customId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "invalid poi keyword args", details: nil))
            return
        }
        let poiType = args["poiType"] as? String ?? ""
        let city = args["city"] as? String ?? ""
        let size = args["size"] as? Int ?? 1
        GeofenceClientRegistry.shared.getOrCreate(clientId: clientId)
            .addPoiKeyword(keyword: keyword, poiType: poiType, city: city, size: size, customId: customId)
        result(nil)
    }
    
    private func handleGeofenceAddPoiAround(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard requirePrivacy(result: result), requireApiKey(result: result),
              let clientId = clientId(from: call),
              let args = call.arguments as? [String: Any],
              let keyword = args["keyword"] as? String,
              let latitude = args["latitude"] as? Double,
              let longitude = args["longitude"] as? Double,
              let customId = args["customId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "invalid poi around args", details: nil))
            return
        }
        let poiType = args["poiType"] as? String ?? ""
        let aroundRadius = args["aroundRadius"] as? Double ?? 3000
        let size = args["size"] as? Int ?? 10
        GeofenceClientRegistry.shared.getOrCreate(clientId: clientId).addPoiAround(
            keyword: keyword,
            poiType: poiType,
            latitude: latitude,
            longitude: longitude,
            aroundRadius: aroundRadius,
            size: size,
            customId: customId
        )
        result(nil)
    }
    
    private func handleGeofenceAddDistrict(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard requirePrivacy(result: result), requireApiKey(result: result),
              let clientId = clientId(from: call),
              let args = call.arguments as? [String: Any],
              let keyword = args["keyword"] as? String,
              let customId = args["customId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "invalid district args", details: nil))
            return
        }
        GeofenceClientRegistry.shared.getOrCreate(clientId: clientId).addDistrict(keyword: keyword, customId: customId)
        result(nil)
    }
    
    private func handleGeofenceRemove(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard requirePrivacy(result: result),
              let clientId = clientId(from: call) else { return }
        let customId = (call.arguments as? [String: Any])?["customId"] as? String
        GeofenceClientRegistry.shared.getOrCreate(clientId: clientId).remove(customId: customId)
        result(nil)
    }
    
    private func handleGeofenceRemoveAll(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard requirePrivacy(result: result),
              let clientId = clientId(from: call) else { return }
        GeofenceClientRegistry.shared.getOrCreate(clientId: clientId).removeAll()
        result(nil)
    }
    
    private func handleGeofencePause(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard requirePrivacy(result: result),
              let clientId = clientId(from: call) else { return }
        GeofenceClientRegistry.shared.getOrCreate(clientId: clientId).pause()
        result(nil)
    }
    
    private func handleGeofenceResume(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard requirePrivacy(result: result),
              let clientId = clientId(from: call) else { return }
        GeofenceClientRegistry.shared.getOrCreate(clientId: clientId).resume()
        result(nil)
    }
    
    private func handleGeofenceDestroy(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let clientId = clientId(from: call) else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "clientId required", details: nil))
            return
        }
        GeofenceClientRegistry.shared.destroy(clientId: clientId)
        result(nil)
    }
}

private final class LocationStreamHandler: NSObject, FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        guard let clientId = arguments as? String else { return nil }
        LocationClientRegistry.shared.getOrCreate(clientId: clientId).setEventSink(events)
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        guard let clientId = arguments as? String else { return nil }
        LocationClientRegistry.shared.get(clientId: clientId)?.setEventSink(nil)
        return nil
    }
}

private final class GeofenceStreamHandler: NSObject, FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        guard let clientId = arguments as? String else { return nil }
        GeofenceClientRegistry.shared.getOrCreate(clientId: clientId).setEventSink(events)
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        guard let clientId = arguments as? String else { return nil }
        GeofenceClientRegistry.shared.get(clientId: clientId)?.setEventSink(nil)
        return nil
    }
}
