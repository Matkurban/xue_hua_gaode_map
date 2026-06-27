import Flutter
import MAMapKit
import UIKit
import CoreLocation

private final class GaodePointAnnotation: MAPointAnnotation {
    var markerId: String = ""
    var iconData: Data?
    var anchorU: CGFloat = 0.5
    var anchorV: CGFloat = 1.0
    var rotation: CGFloat = 0
    var markerAlpha: CGFloat = 1
    var isDraggable: Bool = false
    var infoWindowEnabled: Bool = true
}

private final class GaodeIdentifiedOverlay: NSObject {
    let overlayId: String
    init(id: String) { overlayId = id }
}

private struct MapArgumentError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// Hosts an Amap `MAMapView` and exposes control over a per-view channel.
final class GaodeMapPlatformView: NSObject, FlutterPlatformView, MAMapViewDelegate {
    private let mapView: MAMapView
    private let channel: FlutterMethodChannel
    private let eventChannel: FlutterEventChannel
    private var eventSink: FlutterEventSink?
    
    private var markerAnnotations: [String: GaodePointAnnotation] = [:]
    private var polylines: [String: MAPolyline] = [:]
    private var polygons: [String: MAPolygon] = [:]
    private var circles: [String: MACircle] = [:]
    private var arcs: [String: MAArc] = [:]
    private var groundOverlays: [String: MAGroundOverlay] = [:]
    private var heatmaps: [String: MAHeatMapTileOverlay] = [:]
    private var multiPoints: [String: MAMultiPointOverlay] = [:]
    private var tileOverlays: [String: MATileOverlay] = [:]
    
    private var polylineStyles: [String: [String: Any]] = [:]
    private var polygonStyles: [String: [String: Any]] = [:]
    private var circleStyles: [String: [String: Any]] = [:]
    private var arcStyles: [String: [String: Any]] = [:]
    private var multiPointIcons: [String: UIImage] = [:]
    private var groundOverlayAlphas: [String: CGFloat] = [:]
    private var markerIcons: [String: Data] = [:]
    private var myLocationIconConfig: [String: Any]?
    private var myLocationStyleConfig: [String: Any]?
    private var cameraMoving = false
    private var pendingLogoPosition: String?
    
    init(frame: CGRect, viewId: Int64, args: [String: Any], messenger: FlutterBinaryMessenger) {
        mapView = MAMapView(frame: frame)
        channel = FlutterMethodChannel(
            name: "xue_hua_gaode_map/map_\(viewId)",
            binaryMessenger: messenger
        )
        eventChannel = FlutterEventChannel(
            name: "xue_hua_gaode_map/map_events_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()
        mapView.delegate = self
        applyInitialOptions(args)
        eventChannel.setStreamHandler(self)
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }
    
    deinit {
        channel.setMethodCallHandler(nil)
        eventChannel.setStreamHandler(nil)
        clearAllOverlays()
        mapView.delegate = nil
    }
    
    func view() -> UIView { mapView }
    
    private func emit(_ type: String, payload: [String: Any] = [:]) {
        var event: [String: Any] = ["type": type]
        payload.forEach { event[$0.key] = $0.value }
        eventSink?(event)
    }
    
    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        do {
            switch call.method {
            case "map#getCameraPosition":
                result(cameraMap())
            case "map#moveCamera":
                try applyCamera(args, animated: args["animated"] as? Bool ?? true, duration: 0)
                result(nil)
            case "map#animateCamera":
                let durationMs = args["durationMs"] as? Int ?? 250
                try applyCamera(args, animated: true, duration: Double(durationMs) / 1000.0)
                result(nil)
            case "map#fitBounds":
                try fitBounds(args)
                result(nil)
        case "map#setMapRegionLimits":
            setRegionLimits(args)
            result(nil)
        case "map#zoomIn":
            mapView.setZoomLevel(mapView.zoomLevel + 1, animated: true)
            result(nil)
        case "map#zoomOut":
            mapView.setZoomLevel(mapView.zoomLevel - 1, animated: true)
            result(nil)
        case "map#setMapType":
            mapView.mapType = mapType(from: args["mapType"] as? String)
            result(nil)
        case "map#setTrafficEnabled":
            mapView.isShowTraffic = args["enabled"] as? Bool ?? false
            result(nil)
        case "map#setBuildingsEnabled":
            mapView.isShowsBuildings = args["enabled"] as? Bool ?? true
            result(nil)
        case "map#setMapTextEnabled":
            mapView.isShowsLabels = args["enabled"] as? Bool ?? true
            result(nil)
        case "map#setIndoorEnabled":
            mapView.isShowsIndoorMap = args["enabled"] as? Bool ?? false
            result(nil)
        case "map#setCompassEnabled":
            mapView.showsCompass = args["enabled"] as? Bool ?? true
            result(nil)
        case "map#setScaleEnabled":
            mapView.showsScale = args["enabled"] as? Bool ?? true
            result(nil)
        case "map#setLogoPosition":
            applyLogoPosition(args["position"] as? String)
            result(nil)
        case "map#setMinMaxZoom":
            if let minZoom = args["minZoom"] as? Double { mapView.minZoomLevel = CGFloat(minZoom) }
            if let maxZoom = args["maxZoom"] as? Double { mapView.maxZoomLevel = CGFloat(maxZoom) }
            result(nil)
        case "map#setMyLocationEnabled":
            let enabled = args["enabled"] as? Bool ?? false
            mapView.showsUserLocation = enabled
            if enabled {
                applyMyLocationRepresentation()
                applyUserTrackingMode(from: myLocationStyleConfig)
            }
            result(nil)
        case "map#setMyLocationIcon":
            if let iconMap = args["icon"] as? [String: Any] {
                myLocationIconConfig = iconMap
            } else {
                myLocationIconConfig = nil
            }
            applyMyLocationRepresentation()
            result(nil)
        case "map#setMyLocationStyle":
            myLocationStyleConfig = args["style"] as? [String: Any]
            applyMyLocationRepresentation()
            applyUserTrackingMode(from: myLocationStyleConfig)
            result(nil)
        case "map#getMyLocation":
            result(readMyLocation())
        case "map#moveToMyLocation":
            moveToMyLocation(animated: args["animated"] as? Bool ?? true)
            result(nil)
        case "map#setMyLocationButtonEnabled",
             "map#setZoomControlsEnabled",
             "map#setZoomControlsPosition":
            result(nil)
        case "map#addMarker":
            try addMarker(args)
            result(nil)
        case "map#removeMarker":
            removeMarker(id: args["id"] as? String)
            result(nil)
        case "map#clearMarkers":
            mapView.removeAnnotations(Array(markerAnnotations.values))
            markerAnnotations.removeAll()
            markerIcons.removeAll()
            result(nil)
        case "map#showInfoWindow":
            if let id = args["id"] as? String, let annotation = markerAnnotations[id] {
                mapView.selectAnnotation(annotation, animated: true)
            }
            result(nil)
        case "map#hideInfoWindow":
            if let id = args["id"] as? String, let annotation = markerAnnotations[id] {
                mapView.deselectAnnotation(annotation, animated: true)
            }
            result(nil)
        case "map#addPolyline":
            try addPolyline(args)
            result(nil)
        case "map#removePolyline":
            removeOverlay(from: &polylines, id: args["id"] as? String)
            result(nil)
        case "map#clearPolylines":
            clearOverlayDict(&polylines)
            result(nil)
        case "map#addPolygon":
            try addPolygon(args)
            result(nil)
        case "map#removePolygon":
            removeOverlay(from: &polygons, id: args["id"] as? String)
            result(nil)
        case "map#clearPolygons":
            clearOverlayDict(&polygons)
            result(nil)
        case "map#addCircle":
            try addCircle(args)
            result(nil)
        case "map#removeCircle":
            removeOverlay(from: &circles, id: args["id"] as? String)
            result(nil)
        case "map#clearCircles":
            clearOverlayDict(&circles)
            result(nil)
        case "map#addArc":
            try addArc(args)
            result(nil)
        case "map#removeArc":
            removeOverlay(from: &arcs, id: args["id"] as? String)
            result(nil)
        case "map#clearArcs":
            clearOverlayDict(&arcs)
            result(nil)
        case "map#addGroundOverlay":
            try addGroundOverlay(args)
            result(nil)
        case "map#removeGroundOverlay":
            removeOverlay(from: &groundOverlays, id: args["id"] as? String)
            result(nil)
        case "map#clearGroundOverlays":
            clearOverlayDict(&groundOverlays)
            result(nil)
        case "map#addHeatmap":
            try addHeatmap(args)
            result(nil)
        case "map#removeHeatmap":
            removeOverlay(from: &heatmaps, id: args["id"] as? String)
            result(nil)
        case "map#clearHeatmaps":
            clearOverlayDict(&heatmaps)
            result(nil)
        case "map#addMultiPoint":
            try addMultiPoint(args)
            result(nil)
        case "map#removeMultiPoint":
            removeOverlay(from: &multiPoints, id: args["id"] as? String)
            result(nil)
        case "map#clearMultiPoints":
            clearOverlayDict(&multiPoints)
            result(nil)
        case "map#addTileOverlay":
            try addTileOverlay(args)
            result(nil)
        case "map#removeTileOverlay":
            removeOverlay(from: &tileOverlays, id: args["id"] as? String)
            result(nil)
        case "map#clearTileOverlays":
            clearOverlayDict(&tileOverlays)
            result(nil)
        case "map#clearOverlays":
            clearAllOverlays()
            result(nil)
        case "map#takeSnapshot":
            takeSnapshot(result: result)
        case "map#toScreenLocation":
            guard let coordinate = coordinateFrom(args) else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "coordinate required", details: nil))
                return
            }
            let point = mapView.convert(coordinate, toPointTo: mapView)
            result(["x": Double(point.x), "y": Double(point.y)])
        case "map#fromScreenLocation":
            guard let x = args["x"] as? Double, let y = args["y"] as? Double else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "point required", details: nil))
                return
            }
            let coordinate = mapView.convert(CGPoint(x: x, y: y), toCoordinateFrom: mapView)
            result(coordinateMap(coordinate))
        default:
            result(FlutterMethodNotImplemented)
        }
        } catch let error as MapArgumentError {
            result(FlutterError(code: "INVALID_ARGUMENT", message: error.message, details: nil))
        } catch {
            result(FlutterError(code: "PLATFORM_ERROR", message: error.localizedDescription, details: nil))
        }
    }
    
    // MARK: - Options
    
    private func applyInitialOptions(_ args: [String: Any]) {
        mapView.mapType = mapType(from: args["mapType"] as? String)
        mapView.isShowTraffic = args["trafficEnabled"] as? Bool ?? false
        mapView.isShowsBuildings = args["buildingsEnabled"] as? Bool ?? true
        mapView.isShowsLabels = args["mapTextEnabled"] as? Bool ?? true
        mapView.isShowsIndoorMap = args["indoorEnabled"] as? Bool ?? false
        mapView.isZoomEnabled = args["zoomGesturesEnabled"] as? Bool ?? true
        mapView.isScrollEnabled = args["scrollGesturesEnabled"] as? Bool ?? true
        mapView.isRotateEnabled = args["rotateGesturesEnabled"] as? Bool ?? true
        mapView.isRotateCameraEnabled = args["tiltGesturesEnabled"] as? Bool ?? true
        mapView.showsCompass = args["compassEnabled"] as? Bool ?? true
        mapView.showsScale = args["scaleEnabled"] as? Bool ?? true
        pendingLogoPosition = args["logoPosition"] as? String
        DispatchQueue.main.async { [weak self] in
            self?.applyLogoPosition(self?.pendingLogoPosition)
        }
        if let minZoom = args["minZoom"] as? Double { mapView.minZoomLevel = CGFloat(minZoom) }
        if let maxZoom = args["maxZoom"] as? Double { mapView.maxZoomLevel = CGFloat(maxZoom) }
        if args["myLocationEnabled"] as? Bool == true { mapView.showsUserLocation = true }
        if let iconMap = args["myLocationIcon"] as? [String: Any] {
            myLocationIconConfig = iconMap
        }
        if let styleMap = args["myLocationStyle"] as? [String: Any] {
            myLocationStyleConfig = styleMap
        }
        applyMyLocationRepresentation()
        applyUserTrackingMode(from: myLocationStyleConfig)
        if let limits = args["regionLimits"] as? [String: Any] {
            setRegionLimits(["bounds": limits])
        }
        if let camera = args["initialCamera"] as? [String: Any] {
            try? applyCamera(camera, animated: false, duration: 0)
        }
    }
    
    private func applyLogoPosition(_ value: String?) {
        guard mapView.bounds.width > 0, mapView.bounds.height > 0 else {
            pendingLogoPosition = value
            return
        }
        pendingLogoPosition = nil
        switch value {
        case "centerBottom":
            mapView.logoCenter = CGPoint(x: mapView.bounds.midX, y: mapView.bounds.maxY - 20)
        case "rightBottom":
            mapView.logoCenter = CGPoint(x: mapView.bounds.maxX - 50, y: mapView.bounds.maxY - 20)
        default:
            mapView.logoCenter = CGPoint(x: 50, y: mapView.bounds.maxY - 20)
        }
    }
    
    private func applyMyLocationRepresentation() {
        let representation = MAUserLocationRepresentation()
        let style = myLocationStyleConfig ?? [:]
        if let showsRing = style["showsAccuracyRing"] as? Bool {
            representation.showsAccuracyRing = showsRing
        }
        if let showsHeading = style["showsHeadingIndicator"] as? Bool {
            representation.showsHeadingIndicator = showsHeading
        }
        if let pulse = style["enablePulseAnimation"] as? Bool {
            representation.enablePulseAnnimation = pulse
        }
        if let stroke = style["strokeColor"] as? Int {
            representation.strokeColor = uiColor(from: stroke)
        }
        if let fill = style["fillColor"] as? Int {
            representation.fillColor = uiColor(from: fill)
        }
        if let width = style["strokeWidth"] as? Double {
            representation.lineWidth = CGFloat(width)
        }
        if let dotFill = style["locationDotFillColor"] as? Int {
            representation.locationDotFillColor = uiColor(from: dotFill)
        }
        if let dotBg = style["locationDotBgColor"] as? Int {
            representation.locationDotBgColor = uiColor(from: dotBg)
        }
        if let iconMap = myLocationIconConfig,
           let typedData = iconMap["bytes"] as? FlutterStandardTypedData,
           let image = UIImage(data: typedData.data) {
            representation.image = image
        }
        mapView.update(representation)
    }

    private func applyUserTrackingMode(from style: [String: Any]?) {
        let mode = userTrackingModeValue(from: style)
        mapView.setUserTrackingMode(mode, animated: false)
    }

    private func userTrackingModeValue(from style: [String: Any]?) -> MAUserTrackingMode {
        if let tracking = style?["trackingMode"] as? String {
            switch tracking {
            case "follow":
                return .follow
            case "followWithHeading":
                return .followWithHeading
            default:
                return .none
            }
        }
        switch style?["type"] as? String {
        case "follow", "followNoCenter":
            return .follow
        case "mapRotate", "mapRotateNoCenter", "locationRotate", "locationRotateNoCenter":
            return .followWithHeading
        default:
            return .none
        }
    }

    private func readMyLocation() -> [String: Any]? {
        guard let location = mapView.userLocation.location else { return nil }
        var map: [String: Any] = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "accuracy": location.horizontalAccuracy,
        ]
        if location.course >= 0 { map["bearing"] = location.course }
        if location.speed >= 0 { map["speed"] = location.speed }
        return map
    }

    private func moveToMyLocation(animated: Bool) {
        guard let location = mapView.userLocation.location else {
            mapView.setUserTrackingMode(.follow, animated: animated)
            return
        }
        mapView.setCenter(location.coordinate, animated: animated)
    }

    private func userTrackingModeWireValue(_ mode: MAUserTrackingMode) -> String {
        switch mode {
        case .follow:
            return "follow"
        case .followWithHeading:
            return "followWithHeading"
        default:
            return "none"
        }
    }
    
    // MARK: - Camera
    
    private func cameraMap() -> [String: Any] {
        let center = mapView.centerCoordinate
        return [
            "target": coordinateMap(center),
            "zoom": Double(mapView.zoomLevel),
            "bearing": Double(mapView.rotationDegree),
            "tilt": Double(mapView.cameraDegree),
        ]
    }
    
    private func applyCamera(_ map: [String: Any], animated: Bool, duration: Double = 0) throws {
        guard let target = map["target"] as? [String: Any],
              let lat = target["latitude"] as? Double,
              let lng = target["longitude"] as? Double else {
            throw MapArgumentError(message: "camera target required")
        }
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        let animDuration = animated ? duration : 0
        mapView.setCenter(coordinate, animated: animated)
        if let zoom = map["zoom"] as? Double {
            mapView.setZoomLevel(CGFloat(zoom), animated: animated)
        }
        if let bearing = map["bearing"] as? Double {
            mapView.setRotationDegree(CGFloat(bearing), animated: animated, duration: animDuration)
        }
        if let tilt = map["tilt"] as? Double {
            mapView.setCameraDegree(CGFloat(tilt), animated: animated, duration: animDuration)
        }
    }
    
    private func mapRectForBounds(
        southwest: CLLocationCoordinate2D,
        northeast: CLLocationCoordinate2D
    ) -> MAMapRect {
        let center = CLLocationCoordinate2D(
            latitude: (southwest.latitude + northeast.latitude) / 2,
            longitude: (southwest.longitude + northeast.longitude) / 2
        )
        let span = MACoordinateSpanMake(
            abs(northeast.latitude - southwest.latitude),
            abs(northeast.longitude - southwest.longitude)
        )
        return MAMapRectForCoordinateRegion(MACoordinateRegionMake(center, span))
    }
    
    private func fitBounds(_ args: [String: Any]) throws {
        guard let boundsMap = args["bounds"] as? [String: Any],
              let sw = boundsMap["southwest"] as? [String: Any],
              let ne = boundsMap["northeast"] as? [String: Any],
              let swLat = sw["latitude"] as? Double,
              let swLng = sw["longitude"] as? Double,
              let neLat = ne["latitude"] as? Double,
              let neLng = ne["longitude"] as? Double else {
            throw MapArgumentError(message: "bounds required")
        }
        let paddingMap = args["padding"] as? [String: Any] ?? [:]
        let insets = UIEdgeInsets(
            top: CGFloat(paddingMap["top"] as? Double ?? 0),
            left: CGFloat(paddingMap["left"] as? Double ?? 0),
            bottom: CGFloat(paddingMap["bottom"] as? Double ?? 0),
            right: CGFloat(paddingMap["right"] as? Double ?? 0)
        )
        let mapRect = mapRectForBounds(
            southwest: CLLocationCoordinate2D(latitude: swLat, longitude: swLng),
            northeast: CLLocationCoordinate2D(latitude: neLat, longitude: neLng)
        )
        mapView.setVisibleMapRect(
            mapRect,
            edgePadding: insets,
            animated: args["animated"] as? Bool ?? true
        )
    }
    
    private func setRegionLimits(_ args: [String: Any]) {
        guard let boundsMap = args["bounds"] as? [String: Any],
              let sw = boundsMap["southwest"] as? [String: Any],
              let ne = boundsMap["northeast"] as? [String: Any],
              let swLat = sw["latitude"] as? Double,
              let swLng = sw["longitude"] as? Double,
              let neLat = ne["latitude"] as? Double,
              let neLng = ne["longitude"] as? Double else {
            mapView.limitMapRect = MAMapRectNull
            return
        }
        mapView.limitMapRect = mapRectForBounds(
            southwest: CLLocationCoordinate2D(latitude: swLat, longitude: swLng),
            northeast: CLLocationCoordinate2D(latitude: neLat, longitude: neLng)
        )
    }
    
    // MARK: - Overlays
    
    private func addMarker(_ args: [String: Any]) throws {
        guard let id = args["id"] as? String,
              let position = args["position"] as? [String: Any],
              let lat = position["latitude"] as? Double,
              let lng = position["longitude"] as? Double else {
            throw MapArgumentError(message: "invalid marker arguments")
        }
        removeMarker(id: id)
        let annotation = GaodePointAnnotation()
        annotation.markerId = id
        annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        annotation.title = args["title"] as? String
        annotation.subtitle = args["snippet"] as? String
        annotation.isDraggable = args["draggable"] as? Bool ?? false
        annotation.rotation = CGFloat(args["rotation"] as? Double ?? 0)
        annotation.markerAlpha = CGFloat(args["alpha"] as? Double ?? 1)
        annotation.infoWindowEnabled = args["infoWindowEnabled"] as? Bool ?? true
        if let iconMap = args["icon"] as? [String: Any],
           let typedData = iconMap["bytes"] as? FlutterStandardTypedData {
            annotation.iconData = typedData.data
            annotation.anchorU = CGFloat(iconMap["anchorU"] as? Double ?? 0.5)
            annotation.anchorV = CGFloat(iconMap["anchorV"] as? Double ?? 1.0)
            markerIcons[id] = typedData.data
        }
        markerAnnotations[id] = annotation
        mapView.addAnnotation(annotation)
    }
    
    private func removeMarker(id: String?) {
        guard let id, let annotation = markerAnnotations.removeValue(forKey: id) else { return }
        mapView.removeAnnotation(annotation)
        markerIcons.removeValue(forKey: id)
    }
    
    private func addPolyline(_ args: [String: Any]) throws {
        guard let id = args["id"] as? String,
              let coords = coordinatesList(args["points"]) else {
            throw MapArgumentError(message: "invalid polyline arguments")
        }
        removeOverlay(from: &polylines, id: id)
        polylineStyles[id] = args
        var mutable = coords
        let polyline = MAPolyline(coordinates: &mutable, count: UInt(mutable.count))
        polylines[id] = polyline
        mapView.add(polyline)
    }
    
    private func addPolygon(_ args: [String: Any]) throws {
        guard let id = args["id"] as? String,
              let coords = coordinatesList(args["points"]),
              coords.count >= 3 else {
            throw MapArgumentError(message: "invalid polygon arguments")
        }
        removeOverlay(from: &polygons, id: id)
        polygonStyles[id] = args
        var mutable = coords
        let polygon = MAPolygon(coordinates: &mutable, count: UInt(mutable.count))
        polygons[id] = polygon
        mapView.add(polygon)
    }
    
    private func addCircle(_ args: [String: Any]) throws {
        guard let id = args["id"] as? String,
              let center = coordinateFrom(args["center"] as? [String: Any]),
              let radius = args["radius"] as? Double else {
            throw MapArgumentError(message: "invalid circle arguments")
        }
        removeOverlay(from: &circles, id: id)
        circleStyles[id] = args
        let circle = MACircle(center: center, radius: radius)
        circles[id] = circle
        mapView.add(circle)
    }
    
    private func addArc(_ args: [String: Any]) throws {
        guard let id = args["id"] as? String,
              let start = coordinateFrom(args["start"] as? [String: Any]),
              let passed = coordinateFrom(args["passed"] as? [String: Any]),
              let end = coordinateFrom(args["end"] as? [String: Any]) else {
            throw MapArgumentError(message: "invalid arc arguments")
        }
        removeOverlay(from: &arcs, id: id)
        arcStyles[id] = args
        let arc = MAArc(start: start, passedCoordinate: passed, end: end)
        arcs[id] = arc
        mapView.add(arc)
    }
    
    private func addGroundOverlay(_ args: [String: Any]) throws {
        guard let id = args["id"] as? String,
              let boundsMap = args["bounds"] as? [String: Any],
              let sw = boundsMap["southwest"] as? [String: Any],
              let ne = boundsMap["northeast"] as? [String: Any],
              let swCoord = coordinateFrom(sw),
              let neCoord = coordinateFrom(ne),
              let imageMap = args["image"] as? [String: Any],
              let typedData = imageMap["bytes"] as? FlutterStandardTypedData,
              let image = UIImage(data: typedData.data) else {
            throw MapArgumentError(message: "invalid ground overlay arguments")
        }
        removeOverlay(from: &groundOverlays, id: id)
        let bounds = MACoordinateBoundsMake(neCoord, swCoord)
        guard let overlay = MAGroundOverlay(bounds: bounds, icon: image) else {
            throw MapArgumentError(message: "failed to create ground overlay")
        }
        groundOverlayAlphas[id] = CGFloat(1.0 - (args["transparency"] as? Double ?? 0))
        groundOverlays[id] = overlay
        mapView.add(overlay)
    }
    
    private func addHeatmap(_ args: [String: Any]) throws {
        guard let id = args["id"] as? String,
              let points = args["points"] as? [[String: Any]] else {
            throw MapArgumentError(message: "invalid heatmap arguments")
        }
        removeOverlay(from: &heatmaps, id: id)
        var nodes: [MAHeatMapNode] = []
        for point in points {
            guard let lat = point["latitude"] as? Double,
                  let lng = point["longitude"] as? Double else { continue }
            let intensity = (point["intensity"] as? NSNumber)?.doubleValue ?? 1
            let node = MAHeatMapNode()
            node.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            node.intensity = Float(intensity)
            nodes.append(node)
        }
        guard !nodes.isEmpty else {
            throw MapArgumentError(message: "heatmap points required")
        }
        let overlay = MAHeatMapTileOverlay()
        overlay.data = nodes
        overlay.radius = args["radius"] as? Int ?? 38
        overlay.opacity = args["opacity"] as? Double ?? 0.6
        heatmaps[id] = overlay
        mapView.add(overlay)
    }
    
    private func addMultiPoint(_ args: [String: Any]) throws {
        guard let id = args["id"] as? String,
              let coords = coordinatesList(args["points"]),
              let iconMap = args["icon"] as? [String: Any],
              let typedData = iconMap["bytes"] as? FlutterStandardTypedData,
              let image = UIImage(data: typedData.data) else {
            throw MapArgumentError(message: "invalid multi-point arguments")
        }
        removeOverlay(from: &multiPoints, id: id)
        let items = coords.map { coord -> MAMultiPointItem in
            let item = MAMultiPointItem()
            item.coordinate = coord
            return item
        }
        let overlay = MAMultiPointOverlay(multiPointItems: items)
        multiPointIcons[id] = image
        multiPoints[id] = overlay
        mapView.add(overlay)
    }
    
    private func addTileOverlay(_ args: [String: Any]) throws {
        guard let id = args["id"] as? String,
              let template = args["urlTemplate"] as? String else {
            throw MapArgumentError(message: "invalid tile overlay arguments")
        }
        removeOverlay(from: &tileOverlays, id: id)
        let overlay = MATileOverlay(urlTemplate: template)
        if let tileSize = args["tileSize"] as? Int {
            overlay.tileSize = CGSize(width: tileSize, height: tileSize)
        }
        tileOverlays[id] = overlay
        mapView.add(overlay)
    }
    
    private func removeOverlay<T>(from dict: inout [String: T], id: String?) {
        guard let id, let overlay = dict.removeValue(forKey: id) else { return }
        mapView.remove(overlay as! MAOverlay)
        polylineStyles.removeValue(forKey: id)
        polygonStyles.removeValue(forKey: id)
        circleStyles.removeValue(forKey: id)
        arcStyles.removeValue(forKey: id)
        multiPointIcons.removeValue(forKey: id)
        groundOverlayAlphas.removeValue(forKey: id)
    }
    
    private func applyOverlayRendererStyle(_ renderer: MAOverlayRenderer?, style: [String: Any]) {
        guard let renderer else { return }
        if let visible = style["visible"] as? Bool {
            renderer.alpha = visible ? 1 : 0
        }
        if let zIndex = style["zIndex"] as? Int {
            renderer.zIndex = Int32(zIndex)
        }
    }
    
    private func clearOverlayDict<T>(_ dict: inout [String: T]) {
        dict.keys.forEach { id in
            polylineStyles.removeValue(forKey: id)
            polygonStyles.removeValue(forKey: id)
            circleStyles.removeValue(forKey: id)
            arcStyles.removeValue(forKey: id)
            multiPointIcons.removeValue(forKey: id)
            groundOverlayAlphas.removeValue(forKey: id)
        }
        dict.values.forEach { mapView.remove($0 as! MAOverlay) }
        dict.removeAll()
    }
    
    private func clearAllOverlays() {
        mapView.removeAnnotations(Array(markerAnnotations.values))
        markerAnnotations.removeAll()
        markerIcons.removeAll()
        clearOverlayDict(&polylines)
        clearOverlayDict(&polygons)
        clearOverlayDict(&circles)
        clearOverlayDict(&arcs)
        clearOverlayDict(&groundOverlays)
        clearOverlayDict(&heatmaps)
        clearOverlayDict(&multiPoints)
        clearOverlayDict(&tileOverlays)
    }
    
    private func takeSnapshot(result: @escaping FlutterResult) {
        mapView.takeSnapshot(in: mapView.bounds, withCompletionBlock: { image, _ in
            guard let image, let data = image.pngData() else {
                result(FlutterError(code: "SNAPSHOT_FAILED", message: "snapshot failed", details: nil))
                return
            }
            result(FlutterStandardTypedData(bytes: data))
        })
    }
    
    // MARK: - MAMapViewDelegate
    
    func mapView(_ mapView: MAMapView!, didSingleTappedAt coordinate: CLLocationCoordinate2D) {
        emit("tap", payload: ["coordinate": coordinateMap(coordinate)])
    }
    
    func mapView(_ mapView: MAMapView!, didLongPressedAt coordinate: CLLocationCoordinate2D) {
        emit("longPress", payload: ["coordinate": coordinateMap(coordinate)])
    }
    
    func mapViewRegionChanged(_ mapView: MAMapView!) {
        if !cameraMoving {
            cameraMoving = true
            emit("cameraMoveStart")
        }
        emit("cameraMove", payload: ["position": cameraMap()])
    }
    
    func mapView(_ mapView: MAMapView!, regionWillChangeAnimated animated: Bool) {
        if !cameraMoving {
            cameraMoving = true
            emit("cameraMoveStart")
        }
    }
    
    func mapView(_ mapView: MAMapView!, regionDidChangeAnimated animated: Bool) {
        if cameraMoving {
            emit("cameraMoveEnd", payload: ["position": cameraMap()])
            cameraMoving = false
        }
    }
    
    func mapView(_ mapView: MAMapView!, didSelect view: MAAnnotationView!) {
        guard let annotation = view.annotation as? GaodePointAnnotation else { return }
        emit("markerTap", payload: ["id": annotation.markerId])
    }

    func mapView(_ mapView: MAMapView!, didUpdate userLocation: MAUserLocation!, updatingLocation: Bool) {
        guard updatingLocation, let location = userLocation.location else { return }
        emit(
            "myLocationChange",
            payload: {
                var payload: [String: Any] = [
                    "coordinate": coordinateMap(location.coordinate),
                    "accuracy": location.horizontalAccuracy,
                ]
                if location.course >= 0 { payload["bearing"] = location.course }
                if location.speed >= 0 { payload["speed"] = location.speed }
                return payload
            }()
        )
    }

    func mapView(_ mapView: MAMapView!, didChange mode: MAUserTrackingMode, animated: Bool) {
        emit(
            "userTrackingModeChange",
            payload: ["mode": userTrackingModeWireValue(mode)]
        )
    }
    
    func mapView(_ mapView: MAMapView!, didAnnotationViewTappedCalloutFor view: MAAnnotationView!) {
        guard let annotation = view.annotation as? GaodePointAnnotation else { return }
        emit("infoWindowTap", payload: ["id": annotation.markerId])
    }
    
    func mapView(_ mapView: MAMapView!, annotationView view: MAAnnotationView!, didChange newState: MAAnnotationViewDragState, fromOldState oldState: MAAnnotationViewDragState) {
        guard let annotation = view.annotation as? GaodePointAnnotation else { return }
        let type: String
        switch newState {
        case .starting: type = "markerDragStart"
        case .dragging: type = "markerDrag"
        case .ending, .canceling: type = "markerDragEnd"
        default: return
        }
        emit(type, payload: [
            "id": annotation.markerId,
            "position": coordinateMap(annotation.coordinate),
        ])
    }
    
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
        guard let gaodeAnnotation = annotation as? GaodePointAnnotation else { return nil }
        let identifier = "gaode_marker"
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MAAnnotationView
        if view == nil {
            view = MAAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        } else {
            view?.annotation = annotation
        }
        view?.canShowCallout = gaodeAnnotation.infoWindowEnabled
        view?.isDraggable = gaodeAnnotation.isDraggable
        view?.alpha = gaodeAnnotation.markerAlpha
        if let data = gaodeAnnotation.iconData, let image = UIImage(data: data) {
            view?.image = image
            view?.centerOffset = CGPoint(
                x: (0.5 - gaodeAnnotation.anchorU) * image.size.width,
                y: (0.5 - gaodeAnnotation.anchorV) * image.size.height
            )
        }
        view?.transform = CGAffineTransform(rotationAngle: gaodeAnnotation.rotation * .pi / 180)
        return view
    }
    
    func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
        if let polyline = overlay as? MAPolyline,
           let id = polylines.first(where: { $0.value === polyline })?.key,
           let style = polylineStyles[id] {
            let renderer = MAPolylineRenderer(polyline: polyline)
            renderer?.lineWidth = CGFloat(style["width"] as? Double ?? 10)
            renderer?.strokeColor = uiColor(from: style["color"] as? Int ?? 0xFF0000FF)
            if style["dottedLine"] as? Bool == true {
                renderer?.lineDashType = kMALineDashTypeSquare
            }
            applyOverlayRendererStyle(renderer, style: style)
            return renderer
        }
        if let polygon = overlay as? MAPolygon,
           let id = polygons.first(where: { $0.value === polygon })?.key,
           let style = polygonStyles[id] {
            let renderer = MAPolygonRenderer(polygon: polygon)
            renderer?.fillColor = uiColor(from: style["fillColor"] as? Int ?? 0x330000FF)
            renderer?.strokeColor = uiColor(from: style["strokeColor"] as? Int ?? 0xFF0000FF)
            renderer?.lineWidth = CGFloat(style["strokeWidth"] as? Double ?? 10)
            applyOverlayRendererStyle(renderer, style: style)
            return renderer
        }
        if let circle = overlay as? MACircle,
           let id = circles.first(where: { $0.value === circle })?.key,
           let style = circleStyles[id] {
            let renderer = MACircleRenderer(circle: circle)
            renderer?.fillColor = uiColor(from: style["fillColor"] as? Int ?? 0x330000FF)
            renderer?.strokeColor = uiColor(from: style["strokeColor"] as? Int ?? 0xFF0000FF)
            renderer?.lineWidth = CGFloat(style["strokeWidth"] as? Double ?? 10)
            applyOverlayRendererStyle(renderer, style: style)
            return renderer
        }
        if let arc = overlay as? MAArc,
           let id = arcs.first(where: { $0.value === arc })?.key,
           let style = arcStyles[id] {
            let renderer = MAArcRenderer(arc: arc)
            renderer?.strokeColor = uiColor(from: style["strokeColor"] as? Int ?? 0xFF0000FF)
            renderer?.lineWidth = CGFloat(style["strokeWidth"] as? Double ?? 10)
            applyOverlayRendererStyle(renderer, style: style)
            return renderer
        }
        if let ground = overlay as? MAGroundOverlay {
            let renderer = MAGroundOverlayRenderer(groundOverlay: ground)
            if let id = groundOverlays.first(where: { $0.value === ground })?.key,
               let alpha = groundOverlayAlphas[id] {
                renderer?.alpha = alpha
            }
            return renderer
        }
        if let heat = overlay as? MAHeatMapTileOverlay {
            return MATileOverlayRenderer(tileOverlay: heat)
        }
        if let multi = overlay as? MAMultiPointOverlay {
            let renderer = MAMultiPointOverlayRenderer(multiPointOverlay: multi)
            if let id = multiPoints.first(where: { $0.value === multi })?.key,
               let icon = multiPointIcons[id] {
                renderer?.icon = icon
            }
            return renderer
        }
        if let tile = overlay as? MATileOverlay {
            return MATileOverlayRenderer(tileOverlay: tile)
        }
        return nil
    }
    
    // MARK: - Helpers
    
    private func coordinateMap(_ coordinate: CLLocationCoordinate2D) -> [String: Double] {
        ["latitude": coordinate.latitude, "longitude": coordinate.longitude]
    }
    
    private func coordinateFrom(_ map: [String: Any]?) -> CLLocationCoordinate2D? {
        guard let map,
              let lat = map["latitude"] as? Double,
              let lng = map["longitude"] as? Double else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    private func coordinatesList(_ value: Any?) -> [CLLocationCoordinate2D]? {
        guard let list = value as? [[String: Any]] else { return nil }
        let coords = list.compactMap { coordinateFrom($0) }
        return coords.isEmpty ? nil : coords
    }
    
    private func mapType(from value: String?) -> MAMapType {
        switch value {
        case "satellite": return .satellite
        case "night": return .standardNight
        case "navi": return .standard
        default: return .standard
        }
    }
    
    private func uiColor(from argb: Int) -> UIColor {
        let value = UInt32(bitPattern: Int32(argb))
        let a = CGFloat((value >> 24) & 0xFF) / 255
        let r = CGFloat((value >> 16) & 0xFF) / 255
        let g = CGFloat((value >> 8) & 0xFF) / 255
        let b = CGFloat(value & 0xFF) / 255
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

extension GaodeMapPlatformView: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
