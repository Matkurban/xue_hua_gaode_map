import Flutter
import MAMapKit

final class OfflineMapHandler {
    private var eventSink: FlutterEventSink?

    func setEventSink(_ sink: FlutterEventSink?) {
        eventSink = sink
    }

    func getCityList(result: @escaping FlutterResult) {
        guard requirePrivacy(result: result) else { return }
        guard let offlineMap = MAOfflineMap.shared() else {
            result([])
            return
        }
        var cities: [[String: Any?]] = []
        for province in offlineMap.provinces {
            cities.append(cityMap(province, isProvince: true))
            for case let city as MAOfflineItem in province.cities {
                cities.append(cityMap(city, isProvince: false, provinceName: province.name))
            }
        }
        result(cities)
    }

    func downloadByCityCode(_ cityCode: String, result: @escaping FlutterResult) {
        guard requirePrivacy(result: result) else { return }
        guard let item = findItem(cityCode: cityCode) else {
            result(FlutterError(code: "NOT_FOUND", message: "city not found", details: nil))
            return
        }
        download(item: item)
        result(nil)
    }

    func downloadByCityName(_ cityName: String, result: @escaping FlutterResult) {
        guard requirePrivacy(result: result) else { return }
        guard let item = findItem(cityName: cityName) else {
            result(FlutterError(code: "NOT_FOUND", message: "city not found", details: nil))
            return
        }
        download(item: item)
        result(nil)
    }

    func pause(cityCode: String, result: @escaping FlutterResult) {
        guard requirePrivacy(result: result) else { return }
        guard let item = findItem(cityCode: cityCode) else {
            result(FlutterError(code: "NOT_FOUND", message: "city not found", details: nil))
            return
        }
        MAOfflineMap.shared()?.pause(item)
        result(nil)
    }

    func resume(cityCode: String, result: @escaping FlutterResult) {
        downloadByCityCode(cityCode, result: result)
    }

    func remove(cityCode: String, result: @escaping FlutterResult) {
        guard requirePrivacy(result: result) else { return }
        guard let item = findItem(cityCode: cityCode) else {
            result(FlutterError(code: "NOT_FOUND", message: "city not found", details: nil))
            return
        }
        MAOfflineMap.shared()?.delete(item)
        result(nil)
    }

    func getDownloadStatus(cityCode: String, result: @escaping FlutterResult) {
        guard requirePrivacy(result: result) else { return }
        guard let item = findItem(cityCode: cityCode) else {
            result(nil)
            return
        }
        result(cityMap(item, isProvince: false))
    }

    func destroy() {
        eventSink = nil
    }

    private func download(item: MAOfflineItem) {
        MAOfflineMap.shared()?.downloadItem(
            item,
            shouldContinueWhenAppEntersBackground: true,
            downloadBlock: { [weak self] downloadItem, status, info in
            guard let self, let downloadItem else { return }
            DispatchQueue.main.async {
                self.eventSink?([
                    "cityCode": downloadItem.adcode,
                    "cityName": downloadItem.name,
                    "status": self.statusWire(status),
                    "completePercent": self.completePercent(status: status, info: info),
                    "errorInfo": self.errorInfo(status: status, info: info),
                ])
            }
        })
    }

    private func offlineMap() -> MAOfflineMap? {
        MAOfflineMap.shared()
    }

    private func findItem(cityCode: String) -> MAOfflineItem? {
        guard let offlineMap = offlineMap() else { return nil }
        for province in offlineMap.provinces {
            if province.adcode == cityCode { return province }
            for case let city as MAOfflineItem in province.cities {
                if city.adcode == cityCode { return city }
            }
        }
        for municipality in offlineMap.municipalities {
            if municipality.adcode == cityCode { return municipality }
        }
        for city in offlineMap.cities {
            if city.adcode == cityCode { return city }
        }
        return nil
    }

    private func findItem(cityName: String) -> MAOfflineItem? {
        guard let offlineMap = offlineMap() else { return nil }
        for province in offlineMap.provinces {
            if province.name == cityName { return province }
            for case let city as MAOfflineItem in province.cities {
                if city.name == cityName { return city }
            }
        }
        for municipality in offlineMap.municipalities {
            if municipality.name == cityName { return municipality }
        }
        for city in offlineMap.cities {
            if city.name == cityName { return city }
        }
        return nil
    }

    private func cityMap(_ item: MAOfflineItem, isProvince: Bool, provinceName: String = "") -> [String: Any?] {
        [
            "name": item.name,
            "cityCode": item.adcode,
            "provinceName": provinceName,
            "isProvince": isProvince,
            "downloaded": item.itemStatus == .installed,
            "completePercent": completePercent(item: item),
            "status": statusWire(item.itemStatus),
        ]
    }

    private func completePercent(item: MAOfflineItem) -> Int {
        guard item.size > 0 else { return item.itemStatus == .installed ? 100 : 0 }
        return Int((Double(item.downloadedSize) / Double(item.size)) * 100.0)
    }

    private func completePercent(status: MAOfflineMapDownloadStatus, info: Any?) -> Int {
        guard status == .progress,
              let dict = info as? [String: Any],
              let received = dict[MAOfflineMapDownloadReceivedSizeKey] as? NSNumber,
              let expected = dict[MAOfflineMapDownloadExpectedSizeKey] as? NSNumber,
              expected.intValue > 0 else {
            return status == .finished || status == .completed ? 100 : 0
        }
        return Int((Double(received.intValue) / Double(expected.intValue)) * 100.0)
    }

    private func errorInfo(status: MAOfflineMapDownloadStatus, info: Any?) -> String? {
        guard status == .error else { return nil }
        return (info as? NSError)?.localizedDescription
    }

    private func statusWire(_ status: MAOfflineMapDownloadStatus) -> String {
        switch status {
        case .waiting: return "waiting"
        case .start, .progress, .unzip: return "downloading"
        case .completed, .finished: return "finished"
        case .error: return "error"
        case .cancelled: return "cancelled"
        @unknown default: return "unknown"
        }
    }

    private func statusWire(_ status: MAOfflineItemStatus) -> String {
        switch status {
        case .installed: return "finished"
        case .cached: return "downloading"
        case .expired: return "error"
        case .none: return "unknown"
        @unknown default: return "unknown"
        }
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
}
