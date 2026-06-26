import AMapLocationKit
import CoreLocation
import Flutter

final class GeofenceClientManager: NSObject, AMapGeoFenceManagerDelegate {
    let clientId: String
    private var manager: AMapGeoFenceManager?
    private var eventSink: FlutterEventSink?
    private var allowsBackgroundLocationUpdates = false
    
    init(clientId: String) {
        self.clientId = clientId
        super.init()
    }
    
    func setEventSink(_ sink: FlutterEventSink?) {
        eventSink = sink
    }
    
    func setActiveActions(_ actions: [String], allowsBackgroundUpdates: Bool = false) {
        guard ensurePrivacy() else { return }
        allowsBackgroundLocationUpdates = allowsBackgroundUpdates
        manager?.allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates
        var activeAction: AMapGeoFenceActiveAction = []
        if actions.contains("enter") {
            activeAction.insert(.inside)
        }
        if actions.contains("exit") {
            activeAction.insert(.outside)
        }
        if actions.contains("stayed") {
            activeAction.insert(.stayed)
        }
        if activeAction.isEmpty {
            activeAction = .inside
        }
        ensureManager().activeAction = activeAction
    }
    
    func addCircle(latitude: Double, longitude: Double, radius: Double, customId: String) {
        guard ensurePrivacy() else { return }
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        ensureManager().addCircleRegionForMonitoring(
            withCenter: center,
            radius: radius,
            customID: customId
        )
    }
    
    func addPolygon(points: [[String: Any]], customId: String) -> String? {
        guard ensurePrivacy() else { return nil }
        if let validationError = Self.validatePolygonPoints(points) {
            return validationError
        }
        var coordinates = points.compactMap { point -> CLLocationCoordinate2D? in
            guard let lat = point["latitude"] as? NSNumber,
                  let lng = point["longitude"] as? NSNumber else {
                return nil
            }
            return CLLocationCoordinate2D(latitude: lat.doubleValue, longitude: lng.doubleValue)
        }
        ensureManager().addPolygonRegionForMonitoring(
            withCoordinates: &coordinates,
            count: coordinates.count,
            customID: customId
        )
        return nil
    }
    
    private static func validatePolygonPoints(_ points: [[String: Any]]) -> String? {
        guard points.count >= 3 else {
            return "Polygon requires at least 3 points"
        }
        for (index, point) in points.enumerated() {
            guard point["latitude"] is NSNumber else {
                return "Point \(index) missing latitude"
            }
            guard point["longitude"] is NSNumber else {
                return "Point \(index) missing longitude"
            }
        }
        return nil
    }
    
    func addPoiKeyword(keyword: String, poiType: String, city: String, size: Int, customId: String) {
        guard ensurePrivacy() else { return }
        ensureManager().addKeywordPOIRegionForMonitoring(
            withKeyword: keyword,
            poiType: poiType,
            city: city,
            size: size,
            customID: customId
        )
    }
    
    func addPoiAround(
        keyword: String,
        poiType: String,
        latitude: Double,
        longitude: Double,
        aroundRadius: Double,
        size: Int,
        customId: String
    ) {
        guard ensurePrivacy() else { return }
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        ensureManager().addAroundPOIRegionForMonitoring(
            withLocationPoint: center,
            aroundRadius: Int(aroundRadius),
            keyword: keyword,
            poiType: poiType,
            size: size,
            customID: customId
        )
    }
    
    func addDistrict(keyword: String, customId: String) {
        guard ensurePrivacy() else { return }
        ensureManager().addDistrictRegionForMonitoring(
            withDistrictName: keyword,
            customID: customId
        )
    }
    
    func remove(customId: String?) {
        guard ensurePrivacy() else { return }
        if let customId = customId {
            ensureManager().removeGeoFenceRegions(withCustomID: customId)
        } else {
            ensureManager().removeAllGeoFenceRegions()
        }
    }
    
    func removeAll() {
        guard ensurePrivacy() else { return }
        ensureManager().removeAllGeoFenceRegions()
    }
    
    func pause() {
        guard ensurePrivacy() else { return }
        guard let regions = manager?.geoFenceRegions(withCustomID: nil) as? [AMapGeoFenceRegion] else {
            return
        }
        let customIds = Set(regions.compactMap { $0.customID })
        for customId in customIds {
            _ = manager?.pauseGeoFenceRegions(withCustomID: customId)
        }
    }
    
    func resume() {
        guard ensurePrivacy() else { return }
        guard let regions = manager?.geoFenceRegions(withCustomID: nil) as? [AMapGeoFenceRegion] else {
            return
        }
        let customIds = Set(regions.compactMap { $0.customID })
        for customId in customIds {
            _ = manager?.startGeoFenceRegions(withCustomID: customId)
        }
    }
    
    func destroy() {
        eventSink = nil
        manager?.removeAllGeoFenceRegions()
        manager?.delegate = nil
        manager = nil
    }
    
    func amapGeoFenceManager(
        _ manager: AMapGeoFenceManager!,
        didAddRegionForMonitoringFinished regions: [AMapGeoFenceRegion]!,
        customID customId: String!,
        error: Error!
    ) {
        let event: [String: Any?] = [
            "type": "createFinished",
            "success": error == nil,
            "errorCode": (error as NSError?)?.code ?? 0,
            "customId": customId,
            "count": regions?.count ?? 0,
        ]
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(event)
        }
    }
    
    func amapGeoFenceManager(
        _ manager: AMapGeoFenceManager!,
        didGeoFencesStatusChangedFor region: AMapGeoFenceRegion!,
        customID customId: String!,
        error: Error!
    ) {
        let status: Int
        switch region.fenceStatus {
        case .inside:
            status = 1
        case .outside:
            status = 2
        case .stayed:
            status = 3
        default:
            status = 0
        }
        let event: [String: Any?] = [
            "type": "trigger",
            "status": status,
            "customId": customId,
            "fenceId": region.identifier,
            "errorCode": (error as NSError?)?.code ?? 0,
        ]
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(event)
        }
    }
    
    func amapGeoFenceManager(
        _ manager: AMapGeoFenceManager!,
        doRequireLocationAuth locationManager: CLLocationManager!
    ) {
        if allowsBackgroundLocationUpdates {
            locationManager.requestAlwaysAuthorization()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func amapLocationManager(
        _ manager: AMapGeoFenceManager!,
        doRequireTemporaryFullAccuracyAuth locationManager: CLLocationManager!,
        completion: ((Error?) -> Void)!
    ) {
        if #available(iOS 14.0, *) {
            locationManager.requestTemporaryFullAccuracyAuthorization(
                withPurposeKey: "GaodeLocationPurpose"
            ) { error in
                completion?(error)
            }
        } else {
            completion?(nil)
        }
    }
    
    @discardableResult
    private func ensurePrivacy() -> Bool {
        AmapPrivacyState.privacyAgreed
    }
    
    private func ensureManager() -> AMapGeoFenceManager {
        if manager == nil {
            manager = AMapGeoFenceManager()
            manager?.delegate = self
            manager?.allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates
        }
        return manager!
    }
}

final class GeofenceClientRegistry {
    static let shared = GeofenceClientRegistry()
    private var clients: [String: GeofenceClientManager] = [:]
    private let lock = NSLock()
    
    func getOrCreate(clientId: String) -> GeofenceClientManager {
        lock.lock()
        defer { lock.unlock() }
        if let existing = clients[clientId] {
            return existing
        }
        let client = GeofenceClientManager(clientId: clientId)
        clients[clientId] = client
        return client
    }
    
    func remove(clientId: String) {
        lock.lock()
        defer { lock.unlock() }
        clients.removeValue(forKey: clientId)
    }
    
    func get(clientId: String) -> GeofenceClientManager? {
        lock.lock()
        defer { lock.unlock() }
        return clients[clientId]
    }
    
    func destroy(clientId: String) {
        lock.lock()
        let client = clients.removeValue(forKey: clientId)
        lock.unlock()
        client?.destroy()
    }
    
    func destroyAll() {
        lock.lock()
        let allClients = Array(clients.values)
        clients.removeAll()
        lock.unlock()
        allClients.forEach { $0.destroy() }
    }
}
