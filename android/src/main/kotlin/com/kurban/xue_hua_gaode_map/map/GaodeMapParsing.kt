package com.kurban.xue_hua_gaode_map.map

import android.graphics.BitmapFactory
import android.graphics.Color
import com.amap.api.maps.model.BitmapDescriptor
import com.amap.api.maps.model.BitmapDescriptorFactory
import com.amap.api.maps.model.LatLng
import io.flutter.plugin.common.MethodCall

internal object GaodeMapParsing {
    fun latLng(map: Map<String, Any?>?): LatLng? {
        if (map == null) return null
        val lat = (map["latitude"] as? Number)?.toDouble() ?: return null
        val lng = (map["longitude"] as? Number)?.toDouble() ?: return null
        return LatLng(lat, lng)
    }

    fun latLngList(list: List<Map<String, Any?>>?): List<LatLng> {
        if (list == null) return emptyList()
        return list.mapNotNull { latLng(it) }
    }

    fun argColor(call: MethodCall, key: String, default: Int): Int {
        val value = call.argument<Number>(key)?.toLong() ?: return default
        return colorFromArgb(value)
    }

    fun colorFromArgb(value: Long): Int {
        val argb = value and 0xFFFFFFFFL
        return Color.argb(
            ((argb shr 24) and 0xFF).toInt(),
            ((argb shr 16) and 0xFF).toInt(),
            ((argb shr 8) and 0xFF).toInt(),
            (argb and 0xFF).toInt(),
        )
    }

    fun bitmapDescriptor(icon: Map<String, Any?>?): BitmapDescriptor? {
        val bytes = icon?.get("bytes") as? ByteArray ?: return null
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return null
        return BitmapDescriptorFactory.fromBitmap(bitmap)
    }

    fun coordinateMap(latLng: LatLng): Map<String, Double> {
        return mapOf("latitude" to latLng.latitude, "longitude" to latLng.longitude)
    }

    fun cameraMap(
        target: LatLng,
        zoom: Float,
        bearing: Float,
        tilt: Float,
    ): Map<String, Any?> {
        return mapOf(
            "target" to coordinateMap(target),
            "zoom" to zoom.toDouble(),
            "bearing" to bearing.toDouble(),
            "tilt" to tilt.toDouble(),
        )
    }
}
