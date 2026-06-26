package com.kurban.xue_hua_gaode_map

import com.amap.api.location.AMapLocationClientOption
import com.amap.api.location.AMapLocationClientOption.AMapLocationMode
import com.amap.api.location.AMapLocationClientOption.AMapLocationPurpose
import com.amap.api.location.AMapLocationClientOption.GeoLanguage

object LocationOptionsMapper {
    @Suppress("UNCHECKED_CAST")
    fun apply(option: AMapLocationClientOption, args: Map<String, Any?>) {
        (args["onceLocation"] as? Boolean)?.let { option.isOnceLocation = it }
        (args["onceLocationLatest"] as? Boolean)?.let { option.isOnceLocationLatest = it }
        (args["interval"] as? Number)?.let { option.interval = it.toLong() }
        (args["needAddress"] as? Boolean)?.let { option.isNeedAddress = it }
        (args["mockEnable"] as? Boolean)?.let { option.isMockEnable = it }
        (args["locationCacheEnable"] as? Boolean)?.let { option.isLocationCacheEnable = it }
        (args["httpTimeout"] as? Number)?.let { option.httpTimeOut = it.toLong() }

        when (args["locationMode"] as? String) {
            "batterySaving" -> option.locationMode = AMapLocationMode.Battery_Saving
            "deviceSensors" -> option.locationMode = AMapLocationMode.Device_Sensors
            else -> option.locationMode = AMapLocationMode.Hight_Accuracy
        }

        when (args["locationPurpose"] as? String) {
            "signIn" -> option.locationPurpose = AMapLocationPurpose.SignIn
            "transport" -> option.locationPurpose = AMapLocationPurpose.Transport
            "sport" -> option.locationPurpose = AMapLocationPurpose.Sport
        }

        when (args["geoLanguage"] as? String) {
            "english" -> option.geoLanguage = GeoLanguage.EN
            "chinese" -> option.geoLanguage = GeoLanguage.ZH
            else -> option.geoLanguage = GeoLanguage.DEFAULT
        }
    }
}
