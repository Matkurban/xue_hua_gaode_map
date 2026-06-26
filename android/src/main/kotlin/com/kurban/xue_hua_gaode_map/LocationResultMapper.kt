package com.kurban.xue_hua_gaode_map

import com.amap.api.location.AMapLocation

object LocationResultMapper {
    fun toMap(location: AMapLocation): Map<String, Any?> = mapOf(
        "latitude" to location.latitude,
        "longitude" to location.longitude,
        "accuracy" to location.accuracy,
        "altitude" to location.altitude,
        "bearing" to location.bearing,
        "speed" to location.speed,
        "address" to location.address,
        "country" to location.country,
        "province" to location.province,
        "city" to location.city,
        "district" to location.district,
        "street" to location.street,
        "streetNumber" to location.streetNum,
        "cityCode" to location.cityCode,
        "adCode" to location.adCode,
        "poiName" to location.poiName,
        "aoiName" to location.aoiName,
        "buildingId" to location.buildingId,
        "floor" to location.floor,
        "locationType" to location.locationType,
        "locationDetail" to location.locationDetail,
        "gpsAccuracyStatus" to location.gpsAccuracyStatus,
        "timestamp" to location.time,
        "errorCode" to location.errorCode,
        "errorInfo" to location.errorInfo,
    )
}
