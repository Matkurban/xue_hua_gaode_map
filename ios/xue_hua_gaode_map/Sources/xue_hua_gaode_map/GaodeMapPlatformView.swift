import Flutter
import MAMapKit
import UIKit

/// Hosts an Amap `MAMapView` and exposes control over a per-view channel.
final class GaodeMapPlatformView: NSObject, FlutterPlatformView {
    private let mapView: MAMapView
    private let channel: FlutterMethodChannel
    private var annotations: [String: MAPointAnnotation] = [:]

    init(frame: CGRect, viewId: Int64, args: [String: Any], messenger: FlutterBinaryMessenger) {
        mapView = MAMapView(frame: frame)
        channel = FlutterMethodChannel(
            name: "xue_hua_gaode_map/map_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()
        applyInitialOptions(args)
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }

    deinit {
        channel.setMethodCallHandler(nil)
        mapView.removeAnnotations(Array(annotations.values))
        annotations.removeAll()
        mapView.delegate = nil
    }

    func view() -> UIView {
        mapView
    }

    private func applyInitialOptions(_ args: [String: Any]) {
        mapView.mapType = mapType(from: args["mapType"] as? String)
        mapView.isZoomEnabled = args["zoomGesturesEnabled"] as? Bool ?? true
        mapView.isScrollEnabled = args["scrollGesturesEnabled"] as? Bool ?? true
        mapView.isRotateEnabled = args["rotateGesturesEnabled"] as? Bool ?? true
        mapView.isRotateCameraEnabled = args["tiltGesturesEnabled"] as? Bool ?? true
        if args["myLocationEnabled"] as? Bool == true {
            mapView.showsUserLocation = true
        }
        if let camera = args["initialCamera"] as? [String: Any] {
            applyCamera(camera, animated: false)
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "map#moveCamera":
            applyCamera(args, animated: true)
            result(nil)
        case "map#setMapType":
            mapView.mapType = mapType(from: args["mapType"] as? String)
            result(nil)
        case "map#setMyLocationEnabled":
            mapView.showsUserLocation = args["enabled"] as? Bool ?? false
            result(nil)
        case "map#addMarker":
            addMarker(args)
            result(nil)
        case "map#removeMarker":
            if let id = args["id"] as? String, let annotation = annotations.removeValue(forKey: id) {
                mapView.removeAnnotation(annotation)
            }
            result(nil)
        case "map#clearMarkers":
            mapView.removeAnnotations(Array(annotations.values))
            annotations.removeAll()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func applyCamera(_ map: [String: Any], animated: Bool) {
        guard let target = map["target"] as? [String: Any],
              let lat = target["latitude"] as? Double,
              let lng = target["longitude"] as? Double else {
            return
        }
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        mapView.setCenter(coordinate, animated: animated)
        if let zoom = map["zoom"] as? Double {
            mapView.setZoomLevel(CGFloat(zoom), animated: animated)
        }
    }

    private func addMarker(_ args: [String: Any]) {
        guard let id = args["id"] as? String,
              let position = args["position"] as? [String: Any],
              let lat = position["latitude"] as? Double,
              let lng = position["longitude"] as? Double else {
            return
        }
        if let existing = annotations.removeValue(forKey: id) {
            mapView.removeAnnotation(existing)
        }
        let annotation = MAPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        annotation.title = args["title"] as? String
        annotation.subtitle = args["snippet"] as? String
        annotations[id] = annotation
        mapView.addAnnotation(annotation)
    }

    private func mapType(from value: String?) -> MAMapType {
        switch value {
        case "satellite":
            return .satellite
        case "night":
            return .standardNight
        default:
            return .standard
        }
    }
}
