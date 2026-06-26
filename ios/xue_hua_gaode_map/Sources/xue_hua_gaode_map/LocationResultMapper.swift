import AMapFoundationKit
import AMapLocationKit
import AMapSearchKit
import CoreLocation

enum LocationResultMapper {
    static func toMap(
        location: CLLocation?,
        reGeocode: AMapLocationReGeocode?,
        error: Error?
    ) -> [String: Any?] {
        if let error = error as NSError? {
            return [
                "errorCode": error.code,
                "errorInfo": error.localizedDescription,
            ]
        }
        guard let location = location else {
            return [
                "errorCode": -1,
                "errorInfo": "Location is nil",
            ]
        }

        var map: [String: Any?] = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "accuracy": location.horizontalAccuracy,
            "altitude": location.altitude,
            "bearing": location.course,
            "speed": location.speed,
            "timestamp": Int(location.timestamp.timeIntervalSince1970 * 1000),
            "locationType": 1,
            "errorCode": 0,
            "errorInfo": "",
        ]

        if let reGeocode = reGeocode {
            map["address"] = reGeocode.formattedAddress
            map["country"] = reGeocode.country
            map["province"] = reGeocode.province
            map["city"] = reGeocode.city
            map["district"] = reGeocode.district
            map["street"] = reGeocode.street
            map["streetNumber"] = reGeocode.number
            map["cityCode"] = reGeocode.citycode
            map["adCode"] = reGeocode.adcode
            map["poiName"] = reGeocode.poiName
            map["aoiName"] = reGeocode.aoiName
        }

        return map
    }

    static func toMap(
        latitude: Double,
        longitude: Double,
        regeocode: AMapReGeocode
    ) -> [String: Any?] {
        var map: [String: Any?] = [
            "latitude": latitude,
            "longitude": longitude,
            "accuracy": 0,
            "locationType": 1,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
            "errorCode": 0,
            "errorInfo": "",
        ]
        map["address"] = regeocode.formattedAddress
        map["country"] = regeocode.addressComponent?.country
        map["province"] = regeocode.addressComponent?.province
        map["city"] = regeocode.addressComponent?.city
        map["district"] = regeocode.addressComponent?.district
        map["street"] = regeocode.addressComponent?.streetNumber?.street
        map["streetNumber"] = regeocode.addressComponent?.streetNumber?.number
        map["cityCode"] = regeocode.addressComponent?.citycode
        map["adCode"] = regeocode.addressComponent?.adcode
        map["poiName"] = regeocode.pois?.first?.name
        map["aoiName"] = regeocode.aois?.first?.name
        return map
    }
}

enum LocationOptionsMapper {
    static func apply(to manager: AMapLocationManager, options: [String: Any]) {
        if options["desiredAccuracy"] == nil, let locationMode = options["locationMode"] as? String {
            switch locationMode {
            case "batterySaving":
                manager.desiredAccuracy = kCLLocationAccuracyKilometer
            case "deviceSensors":
                // Android `deviceSensors` is GPS-only high accuracy; the closest
                // iOS equivalent is best accuracy (not navigation profile).
                manager.desiredAccuracy = kCLLocationAccuracyBest
            default:
                manager.desiredAccuracy = kCLLocationAccuracyBest
            }
        }

        if let desiredAccuracy = options["desiredAccuracy"] as? String {
            switch desiredAccuracy {
            case "bestForNavigation":
                manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            case "nearestTenMeters":
                manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            case "kilometer":
                manager.desiredAccuracy = kCLLocationAccuracyKilometer
            case "threeKilometers":
                manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            default:
                manager.desiredAccuracy = kCLLocationAccuracyBest
            }
        }

        if let distanceFilter = options["distanceFilter"] as? Double, distanceFilter >= 0 {
            manager.distanceFilter = distanceFilter
        }

        if let pauses = options["pausesLocationUpdatesAutomatically"] as? Bool {
            manager.pausesLocationUpdatesAutomatically = pauses
        }

        if let allowsBackground = options["allowsBackgroundUpdates"] as? Bool {
            manager.allowsBackgroundLocationUpdates = allowsBackground
        }

        if let needAddress = options["needAddress"] as? Bool {
            manager.locatingWithReGeocode = needAddress
        }

        // Note: `interval` (continuous-update frequency, ms) has no direct
        // equivalent on AMapLocationManager — iOS delivers continuous updates
        // driven by `distanceFilter` and the system, not a fixed timer. It is
        // intentionally not mapped to `locationTimeout` (a single-fix timeout).

        if let httpTimeout = options["httpTimeout"] as? Int {
            manager.reGeocodeTimeout = max(5, httpTimeout / 1000)
        }

        if let language = options["geoLanguage"] as? String {
            AmapCoreHandler.setRegionLanguage(language)
        }

        if let protocolValue = options["protocol"] as? String {
            AMapServices.shared().enableHTTPS = (protocolValue == "https")
        }
    }
}
