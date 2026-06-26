import AMapLocationKit
import CoreLocation
import Flutter

final class LocationClientManager: NSObject, AMapLocationManagerDelegate {
    let clientId: String
    private var manager: AMapLocationManager?
    private var eventSink: FlutterEventSink?
    private var reGeoSearchHandler: ReGeoSearchHandler?
    private var isContinuous = false
    private let operationLock = NSLock()
    
    init(clientId: String) {
        self.clientId = clientId
        super.init()
    }
    
    func setEventSink(_ sink: FlutterEventSink?) {
        eventSink = sink
    }
    
    func start(result: FlutterResult? = nil) {
        guard AmapPrivacyState.privacyAgreed else {
            if let result = result {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "PRIVACY_NOT_CONFIGURED",
                        message: AmapPrivacyState.privacyError().localizedDescription,
                        details: nil
                    ))
                }
            }
            return
        }
        guard ensureApiKey(result: result) else { return }
        isContinuous = true
        ensureManager().startUpdatingLocation()
        result?(nil)
    }
    
    func setOptions(_ options: [String: Any], result: FlutterResult? = nil) {
        guard AmapPrivacyState.privacyAgreed else {
            if let result = result {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "PRIVACY_NOT_CONFIGURED",
                        message: AmapPrivacyState.privacyError().localizedDescription,
                        details: nil
                    ))
                }
            }
            return
        }
        LocationOptionsMapper.apply(to: ensureManager(), options: options)
        result?(nil)
    }
    
    func stop() {
        isContinuous = false
        manager?.stopUpdatingLocation()
    }
    
    func getOnce(result: @escaping FlutterResult) {
        guard ensurePrivacy(result: result) else { return }
        guard ensureApiKey(result: result) else { return }
        if isContinuous {
            DispatchQueue.main.async {
                result(FlutterError(
                    code: "LOCATION_ERROR",
                    message: "Cannot request single location while continuous updates are active",
                    details: nil
                ))
            }
            return
        }
        guard acquireOperationLock(for: result) else { return }
        
        // Single-shot uses ONLY the completion block (not the delegate), so the
        // result is delivered exactly once.
        let manager = ensureManager()
        let started = manager.requestLocation(
            withReGeocode: manager.locatingWithReGeocode
        ) { [weak self] location, reGeocode, error in
            self?.releaseOperationLock()
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    result(FlutterError(
                        code: "LOCATION_ERROR",
                        message: error.localizedDescription,
                        details: error.code
                    ))
                } else {
                    result(LocationResultMapper.toMap(location: location, reGeocode: reGeocode, error: nil))
                }
            }
        }
        if !started {
            releaseOperationLock()
            DispatchQueue.main.async {
                result(FlutterError(
                    code: "LOCATION_ERROR",
                    message: "Unable to start single location request",
                    details: nil
                ))
            }
        }
    }
    
    func reverseGeocode(latitude: Double, longitude: Double, result: @escaping FlutterResult) {
        guard ensurePrivacy(result: result) else { return }
        guard ensureApiKey(result: result) else { return }
        guard acquireOperationLock(for: result) else { return }
        
        if reGeoSearchHandler == nil {
            reGeoSearchHandler = ReGeoSearchHandler()
        }
        let wrappedResult: FlutterResult = { [weak self] value in
            self?.releaseOperationLock()
            result(value)
        }
        reGeoSearchHandler?.reverseGeocode(
            latitude: latitude,
            longitude: longitude,
            result: wrappedResult
        )
    }
    
    func destroy() {
        reGeoSearchHandler?.cancel(with: cancelledError())
        reGeoSearchHandler = nil
        releaseOperationLock()
        eventSink = nil
        manager?.stopUpdatingLocation()
        manager?.delegate = nil
        manager = nil
        isContinuous = false
    }
    
    func amapLocationManager(
        _ manager: AMapLocationManager!,
        didUpdate location: CLLocation!,
        reGeocode: AMapLocationReGeocode!
    ) {
        guard isContinuous else { return }
        let map = LocationResultMapper.toMap(location: location, reGeocode: reGeocode, error: nil)
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(map)
        }
    }
    
    func amapLocationManager(_ manager: AMapLocationManager!, didFailWithError error: Error!) {
        // Single-shot failures are delivered through requestLocation's completion
        // block; this delegate only feeds the continuous update stream.
        guard isContinuous else { return }
        let map = LocationResultMapper.toMap(location: nil, reGeocode: nil, error: error)
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(map)
        }
    }
    
    func amapLocationManager(
        _ manager: AMapLocationManager!,
        doRequireLocationAuth locationManager: CLLocationManager!
    ) {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func amapLocationManager(
        _ manager: AMapLocationManager!,
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
    
    private var operationInFlight = false
    
    @discardableResult
    private func acquireOperationLock(for result: @escaping FlutterResult) -> Bool {
        operationLock.lock()
        if operationInFlight {
            operationLock.unlock()
            DispatchQueue.main.async {
                result(FlutterError(
                    code: "LOCATION_ERROR",
                    message: "Another location operation is in progress",
                    details: nil
                ))
            }
            return false
        }
        operationInFlight = true
        operationLock.unlock()
        return true
    }
    
    private func releaseOperationLock() {
        operationLock.lock()
        operationInFlight = false
        operationLock.unlock()
    }
    
    @discardableResult
    private func ensurePrivacy(result: @escaping FlutterResult) -> Bool {
        guard AmapPrivacyState.privacyAgreed else {
            DispatchQueue.main.async {
                result(FlutterError(
                    code: "PRIVACY_NOT_CONFIGURED",
                    message: AmapPrivacyState.privacyError().localizedDescription,
                    details: nil
                ))
            }
            return false
        }
        return true
    }

    @discardableResult
    private func ensureApiKey(result: FlutterResult?) -> Bool {
        guard AmapCoreHandler.isApiKeyConfigured else {
            if let result = result {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "API_KEY_NOT_CONFIGURED",
                        message: "Amap API key is not configured. Set AMapApiKey in Info.plist or call GaodeSdk.setApiKey(...).",
                        details: nil
                    ))
                }
            }
            return false
        }
        return true
    }
    
    private func cancelledError() -> NSError {
        NSError(
            domain: "GaodeLocation",
            code: -4,
            userInfo: [NSLocalizedDescriptionKey: "Operation cancelled"]
        )
    }
    
    private func ensureManager() -> AMapLocationManager {
        if manager == nil {
            manager = AMapLocationManager()
            manager?.delegate = self
            manager?.desiredAccuracy = kCLLocationAccuracyBest
            manager?.locationTimeout = 10
            manager?.reGeocodeTimeout = 5
        }
        return manager!
    }
}

final class LocationClientRegistry {
    static let shared = LocationClientRegistry()
    private var clients: [String: LocationClientManager] = [:]
    private let lock = NSLock()
    
    func getOrCreate(clientId: String) -> LocationClientManager {
        lock.lock()
        defer { lock.unlock() }
        if let existing = clients[clientId] {
            return existing
        }
        let client = LocationClientManager(clientId: clientId)
        clients[clientId] = client
        return client
    }
    
    func get(clientId: String) -> LocationClientManager? {
        lock.lock()
        defer { lock.unlock() }
        return clients[clientId]
    }
    
    func remove(clientId: String) {
        lock.lock()
        defer { lock.unlock() }
        clients.removeValue(forKey: clientId)
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
        AmapPrivacyState.setPrivacyAgreed(false)
    }
}
