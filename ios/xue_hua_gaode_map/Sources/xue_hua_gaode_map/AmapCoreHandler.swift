import AMapFoundationKit
import AMapLocationKit
import AMapSearchKit
import MAMapKit

enum AmapCoreHandler {
    static func updatePrivacyShow(hasContains: Bool, hasShow: Bool) {
        let showStatus: AMapPrivacyShowStatus = hasShow ? .didShow : .notShow
        let containStatus: AMapPrivacyInfoStatus = hasContains ? .didContain : .notContain
        AMapLocationManager.updatePrivacyShow(showStatus, privacyInfo: containStatus)
        AMapSearchAPI.updatePrivacyShow(showStatus, privacyInfo: containStatus)
        MAMapView.updatePrivacyShow(showStatus, privacyInfo: containStatus)
    }
    
    static func updatePrivacyAgree(hasAgree: Bool) {
        let agreeStatus: AMapPrivacyAgreeStatus = hasAgree ? .didAgree : .notAgree
        AMapLocationManager.updatePrivacyAgree(agreeStatus)
        AMapSearchAPI.updatePrivacyAgree(agreeStatus)
        MAMapView.updatePrivacyAgree(agreeStatus)
        AmapPrivacyState.setPrivacyAgreed(hasAgree)
    }
    
    static func setApiKey(_ apiKey: String) {
        AMapServices.shared().apiKey = apiKey
    }

    /// Reads `AMapApiKey` from the host app's `Info.plist` and applies it.
    ///
    /// Unlike Android (which auto-reads the manifest meta-data), the AMap iOS
    /// SDK never reads the key from `Info.plist`. Doing it here mirrors the
    /// documented setup and prevents a nil-key native crash on first use.
    static func applyApiKeyFromBundleIfAvailable() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "AMapApiKey") as? String,
              !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        AMapServices.shared().apiKey = apiKey
    }

    static var isApiKeyConfigured: Bool {
        guard let apiKey = AMapServices.shared().apiKey else { return false }
        return !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    static func setRegionLanguage(_ language: String) {
        switch language {
        case "english":
            AMapServices.shared().regionLanguageType = .en
        case "chinese":
            AMapServices.shared().regionLanguageType = .zhHans
        default:
            AMapServices.shared().regionLanguageType = .zhHans
        }
    }
}
