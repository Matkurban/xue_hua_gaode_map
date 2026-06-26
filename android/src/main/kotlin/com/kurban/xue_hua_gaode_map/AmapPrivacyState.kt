package com.kurban.xue_hua_gaode_map

object AmapPrivacyState {
    @Volatile
    var privacyAgreed: Boolean = false

    fun requirePrivacyAgreed() {
        if (!privacyAgreed) {
            throw IllegalStateException(
                "Gaode privacy compliance must be configured before using location or geofence APIs. " +
                        "Call GaodeSdk.updatePrivacyShow and GaodeSdk.updatePrivacyAgree first.",
            )
        }
    }
}
