package com.kurban.xue_hua_gaode_map.map

import android.content.Context
import android.view.View
import com.amap.api.maps.AMap
import com.amap.api.maps.CameraUpdateFactory
import com.amap.api.maps.MapView
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.Marker
import com.amap.api.maps.model.MarkerOptions
import com.amap.api.maps.model.MyLocationStyle
import com.kurban.xue_hua_gaode_map.AmapPrivacyState
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

/// Hosts a Amap [MapView] and exposes control over a per-view method channel.
class GaodeMapPlatformView(
    context: Context,
    messenger: BinaryMessenger,
    viewId: Int,
    creationParams: Map<String, Any?>,
) : PlatformView, MethodChannel.MethodCallHandler {
    private val mapView = MapView(context)
    private val aMap: AMap = mapView.map
    private val channel = MethodChannel(messenger, "xue_hua_gaode_map/map_$viewId")
    private val markers = HashMap<String, Marker>()
    private var disposed = false

    init {
        mapView.onCreate(null)
        mapView.onResume()
        applyInitialOptions(creationParams)
        channel.setMethodCallHandler(this)
    }

    override fun getView(): View = mapView

    override fun dispose() {
        if (disposed) return
        disposed = true
        channel.setMethodCallHandler(null)
        markers.clear()
        mapView.onDestroy()
    }

    fun onResume() {
        if (!disposed) mapView.onResume()
    }

    fun onPause() {
        if (!disposed) mapView.onPause()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "map#moveCamera" -> {
                val position = parsePosition(call) ?: return result.error(
                    "INVALID_ARGUMENT", "target required", null,
                )
                aMap.moveCamera(
                    CameraUpdateFactory.newLatLngZoom(position.first, position.second),
                )
                result.success(null)
            }

            "map#setMapType" -> {
                aMap.mapType = mapTypeValue(call.argument<String>("mapType"))
                result.success(null)
            }

            "map#setMyLocationEnabled" -> {
                try {
                    setMyLocationEnabled(call.argument<Boolean>("enabled") ?: false)
                    result.success(null)
                } catch (e: IllegalStateException) {
                    result.error("PRIVACY_NOT_CONFIGURED", e.message, null)
                }
            }

            "map#addMarker" -> {
                addMarker(call)
                result.success(null)
            }

            "map#removeMarker" -> {
                val id = call.argument<String>("id")
                markers.remove(id)?.remove()
                result.success(null)
            }

            "map#clearMarkers" -> {
                markers.values.forEach { it.remove() }
                markers.clear()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun applyInitialOptions(params: Map<String, Any?>) {
        aMap.mapType = mapTypeValue(params["mapType"] as? String)

        val uiSettings = aMap.uiSettings
        uiSettings.isZoomGesturesEnabled = params["zoomGesturesEnabled"] as? Boolean ?: true
        uiSettings.isScrollGesturesEnabled = params["scrollGesturesEnabled"] as? Boolean ?: true
        uiSettings.isRotateGesturesEnabled = params["rotateGesturesEnabled"] as? Boolean ?: true
        uiSettings.isTiltGesturesEnabled = params["tiltGesturesEnabled"] as? Boolean ?: true

        // Only enable the location dot if privacy is already configured;
        // otherwise skip silently so creating the view never crashes. Hosts can
        // call setMyLocationEnabled(true) later once compliance is set up.
        if (params["myLocationEnabled"] as? Boolean == true && AmapPrivacyState.privacyAgreed) {
            setMyLocationEnabled(true)
        }

        @Suppress("UNCHECKED_CAST")
        val camera = params["initialCamera"] as? Map<String, Any?>
        if (camera != null) {
            val target = camera["target"] as? Map<String, Any?>
            val lat = (target?.get("latitude") as? Number)?.toDouble()
            val lng = (target?.get("longitude") as? Number)?.toDouble()
            val zoom = (camera["zoom"] as? Number)?.toFloat() ?: 16f
            if (lat != null && lng != null) {
                aMap.moveCamera(
                    CameraUpdateFactory.newLatLngZoom(LatLng(lat, lng), zoom),
                )
            }
        }
    }

    private fun setMyLocationEnabled(enabled: Boolean) {
        if (enabled) {
            AmapPrivacyState.requirePrivacyAgreed()
            aMap.myLocationStyle = MyLocationStyle().apply {
                myLocationType(MyLocationStyle.LOCATION_TYPE_LOCATION_ROTATE_NO_CENTER)
            }
        }
        aMap.isMyLocationEnabled = enabled
    }

    private fun addMarker(call: MethodCall) {
        val id = call.argument<String>("id") ?: return
        val position = call.argument<Map<String, Any?>>("position") ?: return
        val lat = (position["latitude"] as? Number)?.toDouble() ?: return
        val lng = (position["longitude"] as? Number)?.toDouble() ?: return
        markers.remove(id)?.remove()
        val options = MarkerOptions()
            .position(LatLng(lat, lng))
            .title(call.argument("title"))
            .snippet(call.argument("snippet"))
        aMap.addMarker(options)?.let { markers[id] = it }
    }

    private fun parsePosition(call: MethodCall): Pair<LatLng, Float>? {
        val target = call.argument<Map<String, Any?>>("target") ?: return null
        val lat = (target["latitude"] as? Number)?.toDouble() ?: return null
        val lng = (target["longitude"] as? Number)?.toDouble() ?: return null
        val zoom = (call.argument<Number>("zoom"))?.toFloat() ?: 16f
        return LatLng(lat, lng) to zoom
    }

    private fun mapTypeValue(type: String?): Int {
        return when (type) {
            "satellite" -> AMap.MAP_TYPE_SATELLITE
            "night" -> AMap.MAP_TYPE_NIGHT
            else -> AMap.MAP_TYPE_NORMAL
        }
    }
}
