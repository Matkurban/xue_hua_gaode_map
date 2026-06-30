package com.kurban.xue_hua_gaode_map

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import com.amap.api.fence.GeoFence
import com.amap.api.fence.GeoFenceClient
import com.amap.api.fence.GeoFenceListener
import com.amap.api.location.DPoint
import io.flutter.plugin.common.EventChannel
import java.util.concurrent.ConcurrentHashMap

class GeofenceClientManager(
    private val context: Context,
    private val clientId: String,
) {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var geoFenceClient: GeoFenceClient? = null
    private var eventSink: EventChannel.EventSink? = null
    private var broadcastReceiver: BroadcastReceiver? = null
    private val broadcastAction = "$GEOFENCE_BROADCAST_ACTION.$clientId"

    private val geoFenceListener =
        GeoFenceListener { geoFenceList, errorCode, _ ->
            val event =
                mapOf(
                    "type" to "createFinished",
                    "errorCode" to errorCode,
                    "success" to (errorCode == GeoFence.ADDGEOFENCE_SUCCESS),
                    "count" to geoFenceList.size,
                )
            mainHandler.post { eventSink?.success(event) }
        }

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    fun setActiveActions(actions: List<String>) {
        AmapPrivacyState.requirePrivacyAgreed()
        var action = 0
        if (actions.contains("enter")) action = action or GeoFenceClient.GEOFENCE_IN
        if (actions.contains("exit")) action = action or GeoFenceClient.GEOFENCE_OUT
        if (actions.contains("stayed")) action = action or GeoFenceClient.GEOFENCE_STAYED
        if (action == 0) action = GeoFenceClient.GEOFENCE_IN
        ensureClient().setActivateAction(action)
    }

    fun addCircle(lat: Double, lng: Double, radius: Float, customId: String) {
        AmapPrivacyState.requirePrivacyAgreed()
        ensureClient().addGeoFence(createPoint(lat, lng), radius, customId)
    }

    @Suppress("UNCHECKED_CAST")
    fun addPolygon(points: List<Map<String, Any?>>, customId: String) {
        AmapPrivacyState.requirePrivacyAgreed()
        if (points.size < 3) {
            throw IllegalArgumentException("Polygon requires at least 3 points")
        }
        val dPoints =
            points.mapIndexed { index, point ->
                val lat = point["latitude"] as? Number
                    ?: throw IllegalArgumentException("Point $index missing latitude")
                val lng = point["longitude"] as? Number
                    ?: throw IllegalArgumentException("Point $index missing longitude")
                createPoint(lat.toDouble(), lng.toDouble())
            }
        ensureClient().addGeoFence(dPoints, customId)
    }

    fun addPoiKeyword(
        keyword: String,
        poiType: String,
        city: String,
        size: Int,
        customId: String,
    ) {
        AmapPrivacyState.requirePrivacyAgreed()
        ensureClient().addGeoFence(keyword, poiType, city, size, customId)
    }

    fun addPoiAround(
        keyword: String,
        poiType: String,
        lat: Double,
        lng: Double,
        aroundRadius: Float,
        size: Int,
        customId: String,
    ) {
        AmapPrivacyState.requirePrivacyAgreed()
        ensureClient().addGeoFence(
            keyword,
            poiType,
            createPoint(lat, lng),
            aroundRadius,
            size,
            customId
        )
    }

    fun addDistrict(keyword: String, customId: String) {
        AmapPrivacyState.requirePrivacyAgreed()
        ensureClient().addGeoFence(keyword, customId)
    }

    fun remove(customId: String?) {
        if (customId == null) {
            ensureClient().removeGeoFence()
        } else {
            val fences =
                ensureClient().allGeoFence?.filter { it.customId == customId } ?: emptyList()
            fences.forEach { ensureClient().removeGeoFence(it) }
        }
    }

    fun removeAll() {
        ensureClient().removeGeoFence()
    }

    fun pause() {
        geoFenceClient?.pauseGeoFence()
    }

    fun resume() {
        geoFenceClient?.resumeGeoFence()
    }

    fun destroy() {
        eventSink = null
        geoFenceClient?.removeGeoFence()
        geoFenceClient = null
        unregisterReceiver()
    }

    private fun ensureClient(): GeoFenceClient {
        AmapPrivacyState.requirePrivacyAgreed()
        if (geoFenceClient == null) {
            geoFenceClient = GeoFenceClient(context.applicationContext)
            geoFenceClient?.setGeoFenceListener(geoFenceListener)
            geoFenceClient?.createPendingIntent(broadcastAction)
            registerReceiver()
        }
        return geoFenceClient!!
    }

    private fun registerReceiver() {
        if (broadcastReceiver != null) return
        broadcastReceiver =
            object : BroadcastReceiver() {
                override fun onReceive(ctx: Context, intent: Intent) {
                    val bundle = intent.extras ?: return
                    val status = bundle.getInt(GeoFence.BUNDLE_KEY_FENCESTATUS)
                    val customId = bundle.getString(GeoFence.BUNDLE_KEY_CUSTOMID)
                    val fenceId = bundle.getString(GeoFence.BUNDLE_KEY_FENCEID)
                    val event =
                        mapOf(
                            "type" to "trigger",
                            "status" to status,
                            "customId" to customId,
                            "fenceId" to fenceId,
                        )
                    mainHandler.post { eventSink?.success(event) }
                }
            }
        val filter = IntentFilter(broadcastAction)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(broadcastReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            ContextCompat.registerReceiver(
                context,
                broadcastReceiver,
                filter,
                ContextCompat.RECEIVER_NOT_EXPORTED
            )
        }
    }

    private fun unregisterReceiver() {
        broadcastReceiver?.let { context.unregisterReceiver(it) }
        broadcastReceiver = null
    }

    private fun createPoint(lat: Double, lng: Double): DPoint =
        DPoint().apply {
            latitude = lat
            longitude = lng
        }

    companion object {
        const val GEOFENCE_BROADCAST_ACTION = "com.kurban.xue_hua_gaode_map.GEOFENCE_BROADCAST"
    }
}

object GeofenceClientRegistry {
    private val clients = ConcurrentHashMap<String, GeofenceClientManager>()

    fun getOrCreate(context: Context, clientId: String): GeofenceClientManager =
        clients.getOrPut(clientId) { GeofenceClientManager(context, clientId) }

    fun get(context: Context, clientId: String): GeofenceClientManager? = clients[clientId]

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
