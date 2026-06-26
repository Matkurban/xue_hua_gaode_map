package com.kurban.xue_hua_gaode_map

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.amap.api.location.AMapLocation
import com.amap.api.location.AMapLocationClient
import com.amap.api.location.AMapLocationClientOption
import com.amap.api.location.AMapLocationListener
import com.amap.api.location.IReGeoLocationCallback
import io.flutter.plugin.common.EventChannel
import java.util.concurrent.ConcurrentHashMap

class LocationClientManager(
    private val context: Context,
    private val clientId: String,
) {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var client: AMapLocationClient? = null
    private var option = AMapLocationClientOption()
    private var eventSink: EventChannel.EventSink? = null
    private var pendingOnceResult: ((Result<Map<String, Any?>>) -> Unit)? = null
    private var pendingReGeoResult: ((Result<Map<String, Any?>>) -> Unit)? = null
    private var reGeoTimeoutRunnable: Runnable? = null
    private val callbackLock = Any()
    private var isContinuous = false

    private val locationListener =
        AMapLocationListener { location ->
            val map = LocationResultMapper.toMap(location)
            mainHandler.post {
                synchronized(callbackLock) {
                    pendingOnceResult?.let { callback ->
                        pendingOnceResult = null
                        if (location?.errorCode != 0) {
                            callback(
                                Result.failure(
                                    Exception(location?.errorInfo ?: "Location failed (${location?.errorCode})"),
                                ),
                            )
                        } else {
                            callback(Result.success(map))
                        }
                        return@post
                    }
                }
                eventSink?.success(map)
            }
        }

    private val reGeoCallback =
        IReGeoLocationCallback { location ->
            cancelReGeoTimeout()
            val map = LocationResultMapper.toMap(location)
            mainHandler.post {
                synchronized(callbackLock) {
                    pendingReGeoResult?.let { callback ->
                        pendingReGeoResult = null
                        if (location?.errorCode != 0) {
                            callback(
                                Result.failure(
                                    Exception(location?.errorInfo ?: "Reverse geocode failed (${location?.errorCode})"),
                                ),
                            )
                        } else {
                            callback(Result.success(map))
                        }
                    }
                }
            }
        }

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    fun setOptions(args: Map<String, Any?>) {
        AmapPrivacyState.requirePrivacyAgreed()
        LocationOptionsMapper.apply(option, args)
        ensureClient().setLocationOption(option)
    }

    fun start() {
        AmapPrivacyState.requirePrivacyAgreed()
        option.isOnceLocation = false
        isContinuous = true
        ensureClient().setLocationOption(option)
        ensureClient().startLocation()
    }

    fun stop() {
        isContinuous = false
        client?.stopLocation()
    }

    fun getOnce(callback: (Result<Map<String, Any?>>) -> Unit) {
        AmapPrivacyState.requirePrivacyAgreed()
        synchronized(callbackLock) {
            if (isContinuous) {
                callback(
                    Result.failure(
                        Exception("Cannot request single location while continuous updates are active"),
                    ),
                )
                return
            }
            if (pendingOnceResult != null || pendingReGeoResult != null) {
                callback(Result.failure(Exception("Another location operation is in progress")))
                return
            }
            pendingOnceResult = callback
        }
        // Clone the fully-configured option so single-shot requests keep every
        // setting the host passed via setOptions (locationMode, geoLanguage,
        // purpose, wifiActiveScan, ...) instead of reverting to defaults.
        val onceOption = option.clone().apply { isOnceLocation = true }
        ensureClient().setLocationOption(onceOption)
        ensureClient().startLocation()
    }

    fun reverseGeocode(lat: Double, lng: Double, callback: (Result<Map<String, Any?>>) -> Unit) {
        AmapPrivacyState.requirePrivacyAgreed()
        synchronized(callbackLock) {
            if (pendingOnceResult != null || pendingReGeoResult != null) {
                callback(Result.failure(Exception("Another location operation is in progress")))
                return
            }
            pendingReGeoResult = callback
        }
        val timeoutMs = option.httpTimeOut.coerceAtLeast(5_000L)
        cancelReGeoTimeout()
        reGeoTimeoutRunnable =
            Runnable {
                synchronized(callbackLock) {
                    pendingReGeoResult?.let { pending ->
                        pendingReGeoResult = null
                        pending(Result.failure(Exception("Reverse geocode timed out")))
                    }
                }
            }
        mainHandler.postDelayed(reGeoTimeoutRunnable!!, timeoutMs)
        val stubLocation =
            AMapLocation("").apply {
                latitude = lat
                longitude = lng
                errorCode = 0
            }
        ensureClient().getReGeoLocation(stubLocation)
    }

    fun destroy() {
        cancelReGeoTimeout()
        val cancelled = Result.failure<Map<String, Any?>>(Exception("Operation cancelled"))
        synchronized(callbackLock) {
            pendingOnceResult?.invoke(cancelled)
            pendingOnceResult = null
            pendingReGeoResult?.invoke(cancelled)
            pendingReGeoResult = null
        }
        eventSink = null
        isContinuous = false
        client?.onDestroy()
        client = null
    }

    private fun cancelReGeoTimeout() {
        reGeoTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        reGeoTimeoutRunnable = null
    }

    private fun ensureClient(): AMapLocationClient {
        AmapPrivacyState.requirePrivacyAgreed()
        if (client == null) {
            client = AMapLocationClient(context.applicationContext)
            client?.setLocationListener(locationListener)
            client?.setReGeoLocationCallback(reGeoCallback)
            client?.setLocationOption(option)
        }
        return client!!
    }
}

object LocationClientRegistry {
    private val clients = ConcurrentHashMap<String, LocationClientManager>()

    fun getOrCreate(context: Context, clientId: String): LocationClientManager =
        clients.getOrPut(clientId) { LocationClientManager(context, clientId) }

    fun get(context: Context, clientId: String): LocationClientManager? = clients[clientId]

    fun remove(clientId: String) {
        clients.remove(clientId)
    }

    fun destroy(clientId: String) {
        clients.remove(clientId)?.destroy()
    }

    fun destroyAll() {
        clients.values.forEach { it.destroy() }
        clients.clear()
    }
}
