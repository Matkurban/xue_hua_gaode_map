package com.kurban.xue_hua_gaode_map

import android.content.Context
import com.amap.api.location.AMapLocationClient
import com.amap.api.maps.MapsInitializer
import com.amap.api.services.core.ServiceSettings

object AmapCoreHandler {
    fun updatePrivacyShow(context: Context, hasContains: Boolean, hasShow: Boolean) {
        AMapLocationClient.updatePrivacyShow(context, hasContains, hasShow)
        MapsInitializer.updatePrivacyShow(context, hasContains, hasShow)
        ServiceSettings.updatePrivacyShow(context, hasContains, hasShow)
    }

    fun updatePrivacyAgree(context: Context, hasAgree: Boolean) {
        AMapLocationClient.updatePrivacyAgree(context, hasAgree)
        MapsInitializer.updatePrivacyAgree(context, hasAgree)
        ServiceSettings.updatePrivacyAgree(context, hasAgree)
        AmapPrivacyState.privacyAgreed = hasAgree
    }

    fun setApiKey(apiKey: String) {
        AMapLocationClient.setApiKey(apiKey)
        MapsInitializer.setApiKey(apiKey)
        ServiceSettings.getInstance().setApiKey(apiKey)
    }

    fun updateCountryCode(countryCode: String) {
        AMapLocationClient.updateCountryCode(countryCode)
    }
}
