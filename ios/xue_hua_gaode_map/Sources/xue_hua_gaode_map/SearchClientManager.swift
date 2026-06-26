import AMapFoundationKit
import AMapSearchKit
import Flutter

/// Wraps the Amap Search SDK on iOS: POI keyword/around, input tips and
/// forward geocoding. Each request uses a dedicated handler that is retained
/// until its callback fires.
final class SearchClientManager: NSObject {
    private var handlers = Set<SearchRequestHandler>()
    private let lock = NSLock()
    
    func poiKeyword(
        keyword: String,
        city: String,
        type: String,
        page: Int,
        pageSize: Int,
        result: @escaping FlutterResult
    ) {
        let request = AMapPOIKeywordsSearchRequest()
        request.keywords = keyword
        request.city = city
        request.types = type
        request.page = page
        request.offset = pageSize
        runHandler(result: result) { $0.aMapPOIKeywordsSearch(request) }
    }
    
    func poiAround(
        latitude: Double,
        longitude: Double,
        keyword: String,
        type: String,
        radius: Int,
        page: Int,
        pageSize: Int,
        result: @escaping FlutterResult
    ) {
        let request = AMapPOIAroundSearchRequest()
        request.location = AMapGeoPoint.location(
            withLatitude: CGFloat(latitude),
            longitude: CGFloat(longitude)
        )
        request.keywords = keyword
        request.types = type
        request.radius = radius
        request.page = page
        request.offset = pageSize
        runHandler(result: result) { $0.aMapPOIAroundSearch(request) }
    }
    
    func inputTips(keyword: String, city: String, result: @escaping FlutterResult) {
        let request = AMapInputTipsSearchRequest()
        request.keywords = keyword
        request.city = city
        runHandler(result: result) { $0.aMapInputTipsSearch(request) }
    }
    
    func geocode(address: String, city: String, result: @escaping FlutterResult) {
        let request = AMapGeocodeSearchRequest()
        request.address = address
        request.city = city
        runHandler(result: result) { $0.aMapGeocodeSearch(request) }
    }
    
    private func runHandler(
        result: @escaping FlutterResult,
        action: @escaping (AMapSearchAPI) -> Void
    ) {
        let handler = SearchRequestHandler(result: result) { [weak self] handler in
            guard let self = self else { return }
            self.lock.lock()
            self.handlers.remove(handler)
            self.lock.unlock()
        }
        lock.lock()
        handlers.insert(handler)
        lock.unlock()
        handler.start(action)
    }
}

/// Handles a single search request and releases itself when finished.
private final class SearchRequestHandler: NSObject, AMapSearchDelegate {
    private var searchAPI: AMapSearchAPI?
    private var result: FlutterResult?
    private let onFinished: (SearchRequestHandler) -> Void
    
    init(result: @escaping FlutterResult, onFinished: @escaping (SearchRequestHandler) -> Void) {
        self.result = result
        self.onFinished = onFinished
        super.init()
    }
    
    func start(_ action: (AMapSearchAPI) -> Void) {
        let api = AMapSearchAPI()
        api?.delegate = self
        searchAPI = api
        if let api = api {
            action(api)
        } else {
            finish(FlutterError(code: "SEARCH_ERROR", message: "Failed to create AMapSearchAPI", details: nil))
        }
    }
    
    private func finish(_ value: Any?) {
        guard let callback = result else { return }
        result = nil
        searchAPI?.delegate = nil
        searchAPI = nil
        DispatchQueue.main.async { callback(value) }
        onFinished(self)
    }
    
    func aMapSearchRequest(_ request: Any!, didFailWithError error: Error!) {
        let nsError = error as NSError?
        finish(FlutterError(
            code: "SEARCH_ERROR",
            message: nsError?.localizedDescription ?? "Search failed",
            details: nsError?.code
        ))
    }
    
    func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        let pois = response?.pois ?? []
        let count = Int(response?.count ?? 0)
        let pageSize = max(Int(request?.offset ?? 0), 1)
        finish([
            "pois": pois.map { Self.poiToMap($0) },
            "count": count,
            "pageCount": (count + pageSize - 1) / pageSize,
        ])
    }
    
    func onInputTipsSearchDone(_ request: AMapInputTipsSearchRequest!, response: AMapInputTipsSearchResponse!) {
        let tips = response?.tips ?? []
        finish(tips.map { Self.tipToMap($0) })
    }
    
    func onGeocodeSearchDone(_ request: AMapGeocodeSearchRequest!, response: AMapGeocodeSearchResponse!) {
        let geocodes = response?.geocodes ?? []
        finish(["geocodes": geocodes.map { Self.geocodeToMap($0) }])
    }
    
    private static func poiToMap(_ poi: AMapPOI) -> [String: Any?] {
        [
            "id": poi.uid,
            "name": poi.name,
            "address": poi.address,
            "latitude": poi.location != nil ? Double(poi.location.latitude) : nil,
            "longitude": poi.location != nil ? Double(poi.location.longitude) : nil,
            "tel": poi.tel,
            "distance": Int(poi.distance),
            "type": poi.type,
            "province": poi.province,
            "city": poi.city,
            "district": poi.district,
            "adCode": poi.adcode,
        ]
    }
    
    private static func tipToMap(_ tip: AMapTip) -> [String: Any?] {
        [
            "name": tip.name,
            "district": tip.district,
            "adCode": tip.adcode,
            "latitude": tip.location != nil ? Double(tip.location.latitude) : nil,
            "longitude": tip.location != nil ? Double(tip.location.longitude) : nil,
            "address": tip.address,
            "poiId": tip.uid,
        ]
    }
    
    private static func geocodeToMap(_ geocode: AMapGeocode) -> [String: Any?] {
        [
            "formattedAddress": geocode.formattedAddress,
            "latitude": geocode.location != nil ? Double(geocode.location.latitude) : nil,
            "longitude": geocode.location != nil ? Double(geocode.location.longitude) : nil,
            "province": geocode.province,
            "city": geocode.city,
            "district": geocode.district,
            "adCode": geocode.adcode,
            "level": geocode.level,
        ]
    }
}
