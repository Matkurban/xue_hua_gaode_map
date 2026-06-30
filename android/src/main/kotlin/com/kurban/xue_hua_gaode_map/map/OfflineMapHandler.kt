package com.kurban.xue_hua_gaode_map.map

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.amap.api.maps.MapsInitializer
import com.amap.api.maps.offlinemap.OfflineMapCity
import com.amap.api.maps.offlinemap.OfflineMapManager
import com.amap.api.maps.offlinemap.OfflineMapProvince
import com.amap.api.maps.offlinemap.OfflineMapStatus
import com.kurban.xue_hua_gaode_map.AmapPrivacyState
import io.flutter.plugin.common.EventChannel

import java.util.Collections

class OfflineMapHandler(private val context: Context) {
    private var manager: OfflineMapManager? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val trackedCityCodes = Collections.synchronizedSet(mutableSetOf<String>())

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    fun setStoragePath(path: String) {
        MapsInitializer.sdcardDir = path
    }

    private fun ensureManager(): OfflineMapManager {
        AmapPrivacyState.requirePrivacyAgreed()
        if (manager == null) {
            manager = OfflineMapManager(context, object : OfflineMapManager.OfflineMapDownloadListener {
                override fun onDownload(status: Int, completeCode: Int, msg: String?) {
                    val city = resolveProgressCity(msg)
                    city?.code?.let { code ->
                        if (status == OfflineMapStatus.SUCCESS || status == OfflineMapStatus.ERROR) {
                            trackedCityCodes.remove(code)
                        }
                    }
                    val payload = mapOf(
                        "cityCode" to (city?.code ?: ""),
                        "cityName" to (city?.city ?: ""),
                        "status" to statusWire(status),
                        "completePercent" to completeCode,
                        "errorInfo" to msg,
                    )
                    mainHandler.post { eventSink?.success(payload) }
                }

                override fun onCheckUpdate(hasNew: Boolean, name: String?) {}

                override fun onRemove(success: Boolean, name: String?, describe: String?) {}
            })
        }
        return manager!!
    }

    fun getCityList(): List<Map<String, Any?>> {
        val offlineManager = ensureManager()
        val provinces = offlineManager.offlineMapProvinceList ?: return emptyList()
        val result = mutableListOf<Map<String, Any?>>()
        for (province in provinces) {
            result.add(cityToMap(province, isProvince = true))
            province.cityList?.forEach { city ->
                result.add(cityToMap(city, isProvince = false, provinceName = province.provinceName))
            }
        }
        return result
    }

    fun downloadByCityCode(cityCode: String) {
        val city = findCity(cityCode)
            ?: throw IllegalArgumentException("city not found: $cityCode")
        trackedCityCodes.add(city.code)
        ensureManager().downloadByCityCode(city.code)
    }

    fun downloadByCityName(cityName: String) {
        val city = findCityByName(cityName)
            ?: throw IllegalArgumentException("city not found: $cityName")
        trackedCityCodes.add(city.code)
        ensureManager().downloadByCityName(cityName)
    }

    fun pause(cityCode: String) {
        val city = findCity(cityCode)
            ?: throw IllegalArgumentException("city not found: $cityCode")
        ensureManager().pauseByName(city.city)
    }

    fun resume(cityCode: String) {
        downloadByCityCode(cityCode)
    }

    fun remove(cityCode: String) {
        val city = findCity(cityCode)
            ?: throw IllegalArgumentException("city not found: $cityCode")
        ensureManager().remove(city.city)
    }

    fun getDownloadStatus(cityCode: String): Map<String, Any?>? {
        val city = findCity(cityCode) ?: return null
        return cityToMap(city, isProvince = false)
    }

    fun destroy() {
        manager?.destroy()
        manager = null
        eventSink = null
        trackedCityCodes.clear()
    }

    private fun resolveProgressCity(msg: String?): OfflineMapCity? {
        val downloading = manager?.downloadingCityList ?: return null
        if (msg != null) {
            downloading.firstOrNull { it.city == msg || it.code == msg }?.let { return it }
        }
        synchronized(trackedCityCodes) {
            downloading.firstOrNull { it.code in trackedCityCodes }?.let { return it }
        }
        return downloading.firstOrNull()
    }

    private fun findCityByName(cityName: String): OfflineMapCity? {
        val offlineManager = ensureManager()
        offlineManager.offlineMapCityList?.firstOrNull { it.city == cityName }?.let { return it }
        offlineManager.offlineMapProvinceList?.forEach { province ->
            province.cityList?.forEach { city ->
                if (city.city == cityName) return city
            }
        }
        return null
    }

    private fun findCity(cityCode: String): OfflineMapCity? {
        val offlineManager = ensureManager()
        offlineManager.getItemByCityCode(cityCode)?.let { return it }
        offlineManager.offlineMapProvinceList?.forEach { province ->
            province.cityList?.forEach { city ->
                if (city.code == cityCode) return city
            }
        }
        return null
    }

    private fun cityToMap(
        city: OfflineMapCity,
        isProvince: Boolean,
        provinceName: String = "",
    ): Map<String, Any?> {
        return mapOf(
            "name" to city.city,
            "cityCode" to city.code,
            "provinceName" to provinceName,
            "isProvince" to isProvince,
            "downloaded" to (city.state == OfflineMapStatus.SUCCESS),
            "completePercent" to city.getcompleteCode(),
            "status" to statusWire(city.state),
        )
    }

    private fun cityToMap(
        province: OfflineMapProvince,
        isProvince: Boolean,
    ): Map<String, Any?> {
        return mapOf(
            "name" to province.provinceName,
            "cityCode" to province.provinceCode,
            "provinceName" to "",
            "isProvince" to isProvince,
            "downloaded" to (province.state == OfflineMapStatus.SUCCESS),
            "completePercent" to province.completeCode,
            "status" to statusWire(province.state),
        )
    }

    private fun statusWire(status: Int): String {
        return when (status) {
            OfflineMapStatus.LOADING, OfflineMapStatus.UNZIP -> "downloading"
            OfflineMapStatus.SUCCESS -> "finished"
            OfflineMapStatus.PAUSE -> "paused"
            OfflineMapStatus.STOP -> "cancelled"
            OfflineMapStatus.ERROR,
            OfflineMapStatus.EXCEPTION_AMAP,
            OfflineMapStatus.EXCEPTION_NETWORK_LOADING,
            OfflineMapStatus.EXCEPTION_SDCARD,
            OfflineMapStatus.START_DOWNLOAD_FAILED -> "error"
            OfflineMapStatus.WAITING -> "waiting"
            else -> "unknown"
        }
    }
}
