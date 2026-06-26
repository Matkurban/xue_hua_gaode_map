import AMapFoundationKit
import AMapSearchKit
import CoreLocation
import Flutter

/// Coordinate-based reverse geocoding via AMap Search SDK (iOS location SDK has no coordinate-only regeo API).
final class ReGeoSearchHandler: NSObject, AMapSearchDelegate {
    private var searchAPI: AMapSearchAPI?
    private var pendingResult: FlutterResult?
    private let lock = NSLock()
    
    func reverseGeocode(latitude: Double, longitude: Double, result: @escaping FlutterResult) {
        lock.lock()
        if pendingResult != nil {
            lock.unlock()
            DispatchQueue.main.async {
                result(FlutterError(
                    code: "LOCATION_ERROR",
                    message: "Another location operation is in progress",
                    details: nil
                ))
            }
            return
        }
        pendingResult = result
        lock.unlock()
        
        if searchAPI == nil {
            searchAPI = AMapSearchAPI()
            searchAPI?.delegate = self
        }
        let request = AMapReGeocodeSearchRequest()
        request.location = AMapGeoPoint.location(
            withLatitude: CGFloat(latitude),
            longitude: CGFloat(longitude)
        )
        request.requireExtension = true
        searchAPI?.aMapReGoecodeSearch(request)
    }
    
    func onReGeocodeSearchDone(
        _ request: AMapReGeocodeSearchRequest!,
        response: AMapReGeocodeSearchResponse!
    ) {
        lock.lock()
        guard let callback = pendingResult else {
            lock.unlock()
            return
        }
        pendingResult = nil
        lock.unlock()
        
        guard let regeocode = response.regeocode,
              let location = request.location else {
            DispatchQueue.main.async {
                callback(FlutterError(
                    code: "REGEOCODE_ERROR",
                    message: "Reverse geocode returned no data",
                    details: nil
                ))
            }
            return
        }
        let map = LocationResultMapper.toMap(
            latitude: Double(location.latitude),
            longitude: Double(location.longitude),
            regeocode: regeocode
        )
        DispatchQueue.main.async { callback(map) }
    }
    
    func aMapSearchRequest(_ request: Any!, didFailWithError error: Error!) {
        lock.lock()
        guard let callback = pendingResult else {
            lock.unlock()
            return
        }
        pendingResult = nil
        lock.unlock()
        let nsError = error as NSError?
        DispatchQueue.main.async {
            callback(FlutterError(
                code: "REGEOCODE_ERROR",
                message: nsError?.localizedDescription ?? "Reverse geocode failed",
                details: nsError?.code
            ))
        }
    }
    
    func cancel(with error: Error? = nil) {
        lock.lock()
        let callback = pendingResult
        pendingResult = nil
        lock.unlock()
        if let callback = callback {
            let message = (error as NSError?)?.localizedDescription ?? "Operation cancelled"
            DispatchQueue.main.async {
                callback(FlutterError(code: "LOCATION_ERROR", message: message, details: nil))
            }
        }
    }
}
