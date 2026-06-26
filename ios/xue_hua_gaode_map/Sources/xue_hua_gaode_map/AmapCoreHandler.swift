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
