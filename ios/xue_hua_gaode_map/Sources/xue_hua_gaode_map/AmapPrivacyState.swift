import Foundation

enum AmapPrivacyState {
    private(set) static var privacyAgreed = false
    
    static func setPrivacyAgreed(_ agreed: Bool) {
        privacyAgreed = agreed
    }
    
    static func privacyError() -> NSError {
        NSError(
            domain: "GaodePrivacy",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "Gaode privacy compliance must be configured before using location or geofence APIs. " +
                "Call GaodeSdk.updatePrivacyShow and GaodeSdk.updatePrivacyAgree first.",
            ]
        )
    }
}
