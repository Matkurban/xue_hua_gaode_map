package com.kurban.xue_hua_gaode_map.map

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.view.View
import com.amap.api.maps.AMap
import com.amap.api.maps.AMap.OnCameraChangeListener
import com.amap.api.maps.AMap.OnMapClickListener
import com.amap.api.maps.AMap.OnMapLongClickListener
import com.amap.api.maps.AMap.OnMapScreenShotListener
import com.amap.api.maps.AMap.OnMarkerClickListener
import com.amap.api.maps.AMap.OnMarkerDragListener
import com.amap.api.maps.AMap.OnMyLocationChangeListener
import com.amap.api.maps.AMapOptions
import com.amap.api.maps.CameraUpdateFactory
import com.amap.api.maps.MapsInitializer
import com.amap.api.maps.MapView
import com.amap.api.maps.model.Arc
import com.amap.api.maps.model.ArcOptions
import com.amap.api.maps.model.BitmapDescriptorFactory
import com.amap.api.maps.model.CameraPosition
import com.amap.api.maps.model.Circle
import com.amap.api.maps.model.CircleOptions
import com.amap.api.maps.model.GroundOverlay
import com.amap.api.maps.model.GroundOverlayOptions
import com.amap.api.maps.model.HeatmapTileProvider
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.LatLngBounds
import com.amap.api.maps.model.Marker
import com.amap.api.maps.model.MarkerOptions
import com.amap.api.maps.model.MultiPointItem
import com.amap.api.maps.model.MultiPointOverlay
import com.amap.api.maps.model.MultiPointOverlayOptions
import com.amap.api.maps.model.MyLocationStyle
import com.amap.api.maps.model.Polygon
import com.amap.api.maps.model.PolygonOptions
import com.amap.api.maps.model.Polyline
import com.amap.api.maps.model.PolylineOptions
import com.amap.api.maps.model.TileOverlay
import com.amap.api.maps.model.TileOverlayOptions
import com.amap.api.maps.model.UrlTileProvider
import com.amap.api.maps.model.WeightedLatLng
import com.kurban.xue_hua_gaode_map.AmapPrivacyState
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.io.ByteArrayOutputStream
import java.net.URL
import java.util.concurrent.atomic.AtomicBoolean

/// Hosts an Amap [MapView] and exposes control over a per-view method channel.
class GaodeMapPlatformView(
    context: Context,
    messenger: BinaryMessenger,
    viewId: Int,
    creationParams: Map<String, Any?>,
    private val lifecycleRegistry: GaodeMapLifecycleRegistry? = null,
) : PlatformView,
    MethodChannel.MethodCallHandler,
    OnMapClickListener,
    OnMapLongClickListener,
    OnCameraChangeListener,
    OnMarkerClickListener,
    OnMarkerDragListener {
    private val mapView: MapView
    private val aMap: AMap
    private val channel = MethodChannel(messenger, "xue_hua_gaode_map/map_$viewId")
    private val eventChannel = EventChannel(messenger, "xue_hua_gaode_map/map_events_$viewId")
    private var eventSink: EventChannel.EventSink? = null

    private val markers = HashMap<String, Marker>()
    private val polylines = HashMap<String, Polyline>()
    private val polygons = HashMap<String, Polygon>()
    private val circles = HashMap<String, Circle>()
    private val arcs = HashMap<String, Arc>()
    private val groundOverlays = HashMap<String, GroundOverlay>()
    private val heatmapTiles = HashMap<String, TileOverlay>()
    private val multiPoints = HashMap<String, MultiPointOverlay>()
    private val tileOverlays = HashMap<String, TileOverlay>()

    private var myLocationIconConfig: Map<String, Any?>? = null
    private var myLocationStyleConfig: Map<String, Any?>? = null
    private var restoreMyLocationStyleAfterLocate = false
    private var cameraMoving = false
    private var disposed = false

    init {
        if (creationParams["terrainEnabled"] as? Boolean == true) {
            MapsInitializer.setTerrainEnable(true)
        }
        mapView = MapView(context)
        mapView.onCreate(null)
        mapView.onResume()
        aMap = mapView.map
        setupListeners()
        eventChannel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            },
        )
        applyInitialOptions(creationParams)
        channel.setMethodCallHandler(this)
    }

    private fun setupListeners() {
        aMap.setOnMapClickListener(this)
        aMap.setOnMapLongClickListener(this)
        aMap.setOnCameraChangeListener(this)
        aMap.setOnMarkerClickListener(this)
        aMap.setOnMarkerDragListener(this)
        aMap.setOnInfoWindowClickListener { marker ->
            val id = marker.getObject() as? String ?: return@setOnInfoWindowClickListener
            emit("infoWindowTap", mapOf("id" to id))
        }
        aMap.setOnMyLocationChangeListener(
            OnMyLocationChangeListener { location ->
                if (restoreMyLocationStyleAfterLocate) {
                    restoreMyLocationStyleAfterLocate = false
                    aMap.myLocationStyle = buildMyLocationStyle()
                }
                emit(
                    "myLocationChange",
                    mapOf(
                        "coordinate" to
                            GaodeMapParsing.coordinateMap(
                                LatLng(location.latitude, location.longitude),
                            ),
                        "accuracy" to location.accuracy.toDouble(),
                        "bearing" to location.bearing.toDouble(),
                        "speed" to location.speed.toDouble(),
                    ),
                )
            },
        )
    }

    override fun getView(): View = mapView

    override fun dispose() {
        if (disposed) return
        disposed = true
        lifecycleRegistry?.unregister(this)
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        eventSink = null
        clearAllOverlays()
        mapView.onDestroy()
    }

    fun onResume() {
        if (!disposed) mapView.onResume()
    }

    fun onPause() {
        if (!disposed) mapView.onPause()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "map#getCameraPosition" -> result.success(readCameraPosition())
                "map#moveCamera" -> {
                    applyCamera(call, animated = call.argument<Boolean>("animated") ?: true)
                    result.success(null)
                }
                "map#animateCamera" -> {
                    animateCamera(call)
                    result.success(null)
                }
                "map#fitBounds" -> {
                    fitBounds(call)
                    result.success(null)
                }
                "map#setMapRegionLimits" -> {
                    setRegionLimits(call)
                    result.success(null)
                }
                "map#zoomIn" -> {
                    aMap.animateCamera(CameraUpdateFactory.zoomIn())
                    result.success(null)
                }
                "map#zoomOut" -> {
                    aMap.animateCamera(CameraUpdateFactory.zoomOut())
                    result.success(null)
                }
                "map#setMapType" -> {
                    aMap.mapType = mapTypeValue(call.argument<String>("mapType"))
                    result.success(null)
                }
                "map#setTrafficEnabled" -> {
                    aMap.isTrafficEnabled = call.argument<Boolean>("enabled") ?: false
                    result.success(null)
                }
                "map#setBuildingsEnabled" -> {
                    aMap.showBuildings(call.argument<Boolean>("enabled") ?: true)
                    result.success(null)
                }
                "map#setMapTextEnabled" -> {
                    aMap.showMapText(call.argument<Boolean>("enabled") ?: true)
                    result.success(null)
                }
                "map#setIndoorEnabled" -> {
                    aMap.showIndoorMap(call.argument<Boolean>("enabled") ?: false)
                    result.success(null)
                }
                "map#setCompassEnabled" -> {
                    aMap.uiSettings.isCompassEnabled = call.argument<Boolean>("enabled") ?: true
                    result.success(null)
                }
                "map#setScaleEnabled" -> {
                    aMap.uiSettings.isScaleControlsEnabled = call.argument<Boolean>("enabled") ?: true
                    result.success(null)
                }
                "map#setLogoPosition" -> {
                    aMap.uiSettings.logoPosition = logoPositionValue(call.argument<String>("position"))
                    result.success(null)
                }
                "map#setMinMaxZoom" -> {
                    call.argument<Number>("minZoom")?.toFloat()?.let { aMap.minZoomLevel = it }
                    call.argument<Number>("maxZoom")?.toFloat()?.let { aMap.maxZoomLevel = it }
                    result.success(null)
                }
                "map#setMyLocationEnabled" -> {
                    setMyLocationEnabled(call.argument<Boolean>("enabled") ?: false)
                    result.success(null)
                }
                "map#setMyLocationIcon" -> {
                    @Suppress("UNCHECKED_CAST")
                    myLocationIconConfig = call.argument<Map<String, Any?>>("icon")
                    if (aMap.isMyLocationEnabled) {
                        aMap.myLocationStyle = buildMyLocationStyle()
                    }
                    result.success(null)
                }
                "map#setMyLocationStyle" -> {
                    @Suppress("UNCHECKED_CAST")
                    myLocationStyleConfig = call.argument<Map<String, Any?>>("style")
                    if (aMap.isMyLocationEnabled) {
                        aMap.myLocationStyle = buildMyLocationStyle()
                    }
                    result.success(null)
                }
                "map#getMyLocation" -> {
                    result.success(readMyLocation())
                }
                "map#moveToMyLocation" -> {
                    moveToMyLocation(call.argument<Boolean>("animated") ?: true)
                    result.success(null)
                }
                "map#setMyLocationButtonEnabled" -> {
                    aMap.uiSettings.isMyLocationButtonEnabled =
                        call.argument<Boolean>("enabled") ?: false
                    result.success(null)
                }
                "map#setZoomControlsEnabled" -> {
                    aMap.uiSettings.isZoomControlsEnabled =
                        call.argument<Boolean>("enabled") ?: false
                    result.success(null)
                }
                "map#setZoomControlsPosition" -> {
                    aMap.uiSettings.zoomPosition =
                        zoomPositionValue(call.argument<String>("position"))
                    result.success(null)
                }
                "map#addMarker" -> {
                    addMarker(call)
                    result.success(null)
                }
                "map#removeMarker" -> removeById(markers, call.argument("id"), result)
                "map#clearMarkers" -> {
                    markers.values.forEach { it.remove() }
                    markers.clear()
                    result.success(null)
                }
                "map#showInfoWindow" -> {
                    markers[call.argument("id")]?.showInfoWindow()
                    result.success(null)
                }
                "map#hideInfoWindow" -> {
                    markers[call.argument("id")]?.hideInfoWindow()
                    result.success(null)
                }
                "map#addPolyline" -> {
                    addPolyline(call)
                    result.success(null)
                }
                "map#removePolyline" -> removeById(polylines, call.argument("id"), result)
                "map#clearPolylines" -> {
                    polylines.values.forEach { it.remove() }
                    polylines.clear()
                    result.success(null)
                }
                "map#addPolygon" -> {
                    addPolygon(call)
                    result.success(null)
                }
                "map#removePolygon" -> removeById(polygons, call.argument("id"), result)
                "map#clearPolygons" -> {
                    polygons.values.forEach { it.remove() }
                    polygons.clear()
                    result.success(null)
                }
                "map#addCircle" -> {
                    addCircle(call)
                    result.success(null)
                }
                "map#removeCircle" -> removeById(circles, call.argument("id"), result)
                "map#clearCircles" -> {
                    circles.values.forEach { it.remove() }
                    circles.clear()
                    result.success(null)
                }
                "map#addArc" -> {
                    addArc(call)
                    result.success(null)
                }
                "map#removeArc" -> removeById(arcs, call.argument("id"), result)
                "map#clearArcs" -> {
                    arcs.values.forEach { it.remove() }
                    arcs.clear()
                    result.success(null)
                }
                "map#addGroundOverlay" -> {
                    addGroundOverlay(call)
                    result.success(null)
                }
                "map#removeGroundOverlay" -> removeById(groundOverlays, call.argument("id"), result)
                "map#clearGroundOverlays" -> {
                    groundOverlays.values.forEach { it.remove() }
                    groundOverlays.clear()
                    result.success(null)
                }
                "map#addHeatmap" -> {
                    addHeatmap(call)
                    result.success(null)
                }
                "map#removeHeatmap" -> {
                    heatmapTiles.remove(call.argument("id"))?.remove()
                    result.success(null)
                }
                "map#clearHeatmaps" -> {
                    heatmapTiles.values.forEach { it.remove() }
                    heatmapTiles.clear()
                    result.success(null)
                }
                "map#addMultiPoint" -> {
                    addMultiPoint(call)
                    result.success(null)
                }
                "map#removeMultiPoint" -> {
                    multiPoints.remove(call.argument("id"))?.remove()
                    result.success(null)
                }
                "map#clearMultiPoints" -> {
                    multiPoints.values.forEach { it.remove() }
                    multiPoints.clear()
                    result.success(null)
                }
                "map#addTileOverlay" -> {
                    addTileOverlay(call)
                    result.success(null)
                }
                "map#removeTileOverlay" -> {
                    tileOverlays.remove(call.argument("id"))?.remove()
                    result.success(null)
                }
                "map#clearTileOverlays" -> {
                    tileOverlays.values.forEach { it.remove() }
                    tileOverlays.clear()
                    result.success(null)
                }
                "map#clearOverlays" -> {
                    clearAllOverlays()
                    result.success(null)
                }
                "map#takeSnapshot" -> takeSnapshot(result)
                "map#toScreenLocation" -> {
                    val latLng = GaodeMapParsing.latLng(call.arguments as? Map<String, Any?>)
                        ?: return result.error("INVALID_ARGUMENT", "coordinate required", null)
                    val point = aMap.projection.toScreenLocation(latLng)
                    result.success(mapOf("x" to point.x.toDouble(), "y" to point.y.toDouble()))
                }
                "map#fromScreenLocation" -> {
                    @Suppress("UNCHECKED_CAST")
                    val args = call.arguments as? Map<String, Any?> ?: emptyMap()
                    val x = (args["x"] as? Number)?.toFloat() ?: return result.error(
                        "INVALID_ARGUMENT",
                        "x required",
                        null,
                    )
                    val y = (args["y"] as? Number)?.toFloat() ?: return result.error(
                        "INVALID_ARGUMENT",
                        "y required",
                        null,
                    )
                    val latLng = aMap.projection.fromScreenLocation(android.graphics.Point(x.toInt(), y.toInt()))
                    result.success(GaodeMapParsing.coordinateMap(latLng))
                }
                else -> result.notImplemented()
            }
        } catch (e: IllegalStateException) {
            result.error("PRIVACY_NOT_CONFIGURED", e.message, null)
        } catch (e: IllegalArgumentException) {
            result.error("INVALID_ARGUMENT", e.message, null)
        } catch (e: Exception) {
            result.error("PLATFORM_ERROR", e.message, null)
        }
    }

    private fun clearAllOverlays() {
        markers.values.forEach { it.remove() }
        markers.clear()
        polylines.values.forEach { it.remove() }
        polylines.clear()
        polygons.values.forEach { it.remove() }
        polygons.clear()
        circles.values.forEach { it.remove() }
        circles.clear()
        arcs.values.forEach { it.remove() }
        arcs.clear()
        groundOverlays.values.forEach { it.remove() }
        groundOverlays.clear()
        heatmapTiles.values.forEach { it.remove() }
        heatmapTiles.clear()
        multiPoints.values.forEach { it.remove() }
        multiPoints.clear()
        tileOverlays.values.forEach { it.remove() }
        tileOverlays.clear()
    }

    private fun <T> removeById(
        map: HashMap<String, T>,
        id: String?,
        result: MethodChannel.Result,
    ) where T : Any {
        map.remove(id)?.let {
            when (it) {
                is Marker -> it.remove()
                is Polyline -> it.remove()
                is Polygon -> it.remove()
                is Circle -> it.remove()
                is Arc -> it.remove()
                is GroundOverlay -> it.remove()
            }
        }
        result.success(null)
    }

    private fun emit(type: String, payload: Map<String, Any?> = emptyMap()) {
        eventSink?.success(mapOf("type" to type) + payload)
    }

    private fun readCameraPosition(): Map<String, Any?> {
        val pos = aMap.cameraPosition
        return GaodeMapParsing.cameraMap(
            pos.target,
            pos.zoom,
            pos.bearing,
            pos.tilt,
        )
    }

    private fun applyInitialOptions(params: Map<String, Any?>) {
        aMap.mapType = mapTypeValue(params["mapType"] as? String)
        aMap.isTrafficEnabled = params["trafficEnabled"] as? Boolean ?: false
        aMap.showBuildings(params["buildingsEnabled"] as? Boolean ?: true)
        aMap.showMapText(params["mapTextEnabled"] as? Boolean ?: true)
        aMap.showIndoorMap(params["indoorEnabled"] as? Boolean ?: false)

        val uiSettings = aMap.uiSettings
        uiSettings.isZoomGesturesEnabled = params["zoomGesturesEnabled"] as? Boolean ?: true
        uiSettings.isScrollGesturesEnabled = params["scrollGesturesEnabled"] as? Boolean ?: true
        uiSettings.isRotateGesturesEnabled = params["rotateGesturesEnabled"] as? Boolean ?: true
        uiSettings.isTiltGesturesEnabled = params["tiltGesturesEnabled"] as? Boolean ?: true
        uiSettings.isMyLocationButtonEnabled =
            params["myLocationButtonEnabled"] as? Boolean ?: false
        uiSettings.isZoomControlsEnabled = params["zoomControlsEnabled"] as? Boolean ?: false
        uiSettings.zoomPosition = zoomPositionValue(params["zoomControlsPosition"] as? String)
        uiSettings.isCompassEnabled = params["compassEnabled"] as? Boolean ?: true
        uiSettings.isScaleControlsEnabled = params["scaleEnabled"] as? Boolean ?: true
        uiSettings.logoPosition = logoPositionValue(params["logoPosition"] as? String)

        (params["minZoom"] as? Number)?.toFloat()?.let { aMap.minZoomLevel = it }
        (params["maxZoom"] as? Number)?.toFloat()?.let { aMap.maxZoomLevel = it }

        @Suppress("UNCHECKED_CAST")
        myLocationIconConfig = params["myLocationIcon"] as? Map<String, Any?>
        @Suppress("UNCHECKED_CAST")
        myLocationStyleConfig = params["myLocationStyle"] as? Map<String, Any?>

        if (params["myLocationEnabled"] as? Boolean == true && AmapPrivacyState.privacyAgreed) {
            setMyLocationEnabled(true)
        }

        @Suppress("UNCHECKED_CAST")
        val limits = params["regionLimits"] as? Map<String, Any?>
        if (limits != null) {
            boundsFromMap(limits)?.let { aMap.setMapStatusLimits(it) }
        }

        @Suppress("UNCHECKED_CAST")
        val camera = params["initialCamera"] as? Map<String, Any?>
        if (camera != null) {
            applyCameraMap(camera, animated = false)
        }
    }

    private fun applyCamera(call: MethodCall, animated: Boolean) {
        val update = cameraUpdateFromCall(call)
            ?: throw IllegalArgumentException("invalid camera arguments")
        if (animated) {
            aMap.animateCamera(update)
        } else {
            aMap.moveCamera(update)
        }
    }

    private fun animateCamera(call: MethodCall) {
        val update = cameraUpdateFromCall(call)
            ?: throw IllegalArgumentException("invalid camera arguments")
        val duration = call.argument<Number>("durationMs")?.toLong() ?: 250L
        aMap.animateCamera(update, duration, null)
    }

    private fun cameraUpdateFromCall(call: MethodCall): com.amap.api.maps.CameraUpdate? {
        val target = GaodeMapParsing.latLng(call.argument("target")) ?: return null
        val zoom = call.argument<Number>("zoom")?.toFloat() ?: aMap.cameraPosition.zoom
        val bearing = call.argument<Number>("bearing")?.toFloat() ?: aMap.cameraPosition.bearing
        val tilt = call.argument<Number>("tilt")?.toFloat() ?: aMap.cameraPosition.tilt
        return CameraUpdateFactory.newCameraPosition(
            CameraPosition(target, zoom, tilt, bearing),
        )
    }

    private fun applyCameraMap(map: Map<String, Any?>, animated: Boolean) {
        val targetMap = map["target"] as? Map<String, Any?> ?: return
        val lat = (targetMap["latitude"] as? Number)?.toDouble() ?: return
        val lng = (targetMap["longitude"] as? Number)?.toDouble() ?: return
        val zoom = (map["zoom"] as? Number)?.toFloat() ?: 16f
        val bearing = (map["bearing"] as? Number)?.toFloat() ?: 0f
        val tilt = (map["tilt"] as? Number)?.toFloat() ?: 0f
        val update = CameraUpdateFactory.newCameraPosition(
            CameraPosition(LatLng(lat, lng), zoom, tilt, bearing),
        )
        if (animated) aMap.animateCamera(update) else aMap.moveCamera(update)
    }

    private fun fitBounds(call: MethodCall) {
        @Suppress("UNCHECKED_CAST")
        val boundsMap = call.argument<Map<String, Any?>>("bounds")
            ?: throw IllegalArgumentException("bounds required")
        val bounds = boundsFromMap(boundsMap)
            ?: throw IllegalArgumentException("invalid bounds")
        @Suppress("UNCHECKED_CAST")
        val paddingMap = call.argument<Map<String, Any?>>("padding") ?: emptyMap()
        val left = (paddingMap["left"] as? Number)?.toInt() ?: 0
        val top = (paddingMap["top"] as? Number)?.toInt() ?: 0
        val right = (paddingMap["right"] as? Number)?.toInt() ?: 0
        val bottom = (paddingMap["bottom"] as? Number)?.toInt() ?: 0
        val animated = call.argument<Boolean>("animated") ?: true
        val update = CameraUpdateFactory.newLatLngBoundsRect(bounds, left, top, right, bottom)
        if (animated) aMap.animateCamera(update) else aMap.moveCamera(update)
    }

    private fun setRegionLimits(call: MethodCall) {
        @Suppress("UNCHECKED_CAST")
        val boundsMap = call.argument<Map<String, Any?>>("bounds")
        if (boundsMap == null) {
            aMap.setMapStatusLimits(null)
            return
        }
        val bounds = boundsFromMap(boundsMap)
            ?: throw IllegalArgumentException("invalid bounds")
        aMap.setMapStatusLimits(bounds)
    }

    private fun boundsFromMap(map: Map<String, Any?>): LatLngBounds? {
        @Suppress("UNCHECKED_CAST")
        val sw = map["southwest"] as? Map<String, Any?> ?: return null
        @Suppress("UNCHECKED_CAST")
        val ne = map["northeast"] as? Map<String, Any?> ?: return null
        val swLatLng = GaodeMapParsing.latLng(sw) ?: return null
        val neLatLng = GaodeMapParsing.latLng(ne) ?: return null
        return LatLngBounds(swLatLng, neLatLng)
    }

    private fun setMyLocationEnabled(enabled: Boolean) {
        if (enabled) {
            AmapPrivacyState.requirePrivacyAgreed()
            aMap.myLocationStyle = buildMyLocationStyle()
        }
        aMap.isMyLocationEnabled = enabled
    }

    private fun buildMyLocationStyle(): MyLocationStyle {
        val config = myLocationStyleConfig
        return MyLocationStyle().apply {
            myLocationType(myLocationTypeValue(config?.get("type") as? String))
            interval((config?.get("interval") as? Number)?.toLong()?.coerceAtLeast(1000L) ?: 1000L)
            showMyLocation(config?.get("showMarker") as? Boolean ?: true)
            (config?.get("strokeColor") as? Number)?.toLong()?.let {
                strokeColor(GaodeMapParsing.colorFromArgb(it))
            }
            (config?.get("fillColor") as? Number)?.toLong()?.let {
                radiusFillColor(GaodeMapParsing.colorFromArgb(it))
            }
            (config?.get("strokeWidth") as? Number)?.toFloat()?.let { strokeWidth(it) }
            val icon = myLocationIconConfig ?: return@apply
            val bytes = icon["bytes"] as? ByteArray ?: return@apply
            val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return@apply
            myLocationIcon(BitmapDescriptorFactory.fromBitmap(bitmap))
            val anchorU = (icon["anchorU"] as? Number)?.toFloat() ?: 0.5f
            val anchorV = (icon["anchorV"] as? Number)?.toFloat() ?: 0.5f
            anchor(anchorU, anchorV)
        }
    }

    private fun myLocationTypeValue(type: String?): Int {
        return when (type) {
            "show" -> MyLocationStyle.LOCATION_TYPE_SHOW
            "locate" -> MyLocationStyle.LOCATION_TYPE_LOCATE
            "follow" -> MyLocationStyle.LOCATION_TYPE_FOLLOW
            "mapRotate" -> MyLocationStyle.LOCATION_TYPE_MAP_ROTATE
            "locationRotate" -> MyLocationStyle.LOCATION_TYPE_LOCATION_ROTATE
            "followNoCenter" -> MyLocationStyle.LOCATION_TYPE_FOLLOW_NO_CENTER
            "mapRotateNoCenter" -> MyLocationStyle.LOCATION_TYPE_MAP_ROTATE_NO_CENTER
            "locationRotateNoCenter" -> MyLocationStyle.LOCATION_TYPE_LOCATION_ROTATE_NO_CENTER
            else -> MyLocationStyle.LOCATION_TYPE_LOCATION_ROTATE_NO_CENTER
        }
    }

    private fun readMyLocation(): Map<String, Any?>? {
        val loc = aMap.myLocation ?: return null
        return mapOf(
            "latitude" to loc.latitude,
            "longitude" to loc.longitude,
            "accuracy" to loc.accuracy.toDouble(),
            "bearing" to loc.bearing.toDouble(),
            "speed" to loc.speed.toDouble(),
        )
    }

    private fun moveToMyLocation(animated: Boolean) {
        val loc = aMap.myLocation
        if (loc != null) {
            val update = CameraUpdateFactory.newLatLng(LatLng(loc.latitude, loc.longitude))
            if (animated) {
                aMap.animateCamera(update)
            } else {
                aMap.moveCamera(update)
            }
            return
        }
        restoreMyLocationStyleAfterLocate = true
        aMap.myLocationStyle =
            buildMyLocationStyle().myLocationType(MyLocationStyle.LOCATION_TYPE_LOCATE)
    }

    private fun addMarker(call: MethodCall) {
        val id = call.argument<String>("id")
            ?: throw IllegalArgumentException("id required")
        val latLng = GaodeMapParsing.latLng(call.argument("position"))
            ?: throw IllegalArgumentException("position required")
        markers.remove(id)?.remove()
        val options = MarkerOptions()
            .position(latLng)
            .title(call.argument("title"))
            .snippet(call.argument("snippet"))
            .draggable(call.argument<Boolean>("draggable") ?: false)
            .visible(call.argument<Boolean>("visible") ?: true)
            .rotateAngle(call.argument<Number>("rotation")?.toFloat() ?: 0f)
            .alpha(call.argument<Number>("alpha")?.toFloat() ?: 1f)
            .setFlat(call.argument<Boolean>("flat") ?: false)
            .zIndex(call.argument<Int>("zIndex")?.toFloat() ?: 0f)
            .infoWindowEnable(call.argument<Boolean>("infoWindowEnabled") ?: true)
        GaodeMapParsing.bitmapDescriptor(call.argument("icon"))?.let { options.icon(it) }
        aMap.addMarker(options)?.let { marker ->
            marker.setObject(id)
            markers[id] = marker
        } ?: throw IllegalArgumentException("failed to add marker")
    }

    private fun addPolyline(call: MethodCall) {
        val id = call.argument<String>("id")
            ?: throw IllegalArgumentException("id required")
        @Suppress("UNCHECKED_CAST")
        val points = GaodeMapParsing.latLngList(call.argument("points"))
        if (points.isEmpty()) throw IllegalArgumentException("points required")
        polylines.remove(id)?.remove()
        val options = PolylineOptions()
            .addAll(points)
            .width(call.argument<Number>("width")?.toFloat() ?: 10f)
            .color(GaodeMapParsing.argColor(call, "color", 0xFF0000FF.toInt()))
            .geodesic(call.argument<Boolean>("geodesic") ?: false)
            .setDottedLine(call.argument<Boolean>("dottedLine") ?: false)
            .zIndex(call.argument<Int>("zIndex")?.toFloat() ?: 0f)
            .visible(call.argument<Boolean>("visible") ?: true)
        aMap.addPolyline(options)?.let { polylines[id] = it }
    }

    private fun addPolygon(call: MethodCall) {
        val id = call.argument<String>("id")
            ?: throw IllegalArgumentException("id required")
        @Suppress("UNCHECKED_CAST")
        val points = GaodeMapParsing.latLngList(call.argument("points"))
        if (points.size < 3) throw IllegalArgumentException("at least 3 points required")
        polygons.remove(id)?.remove()
        val options = PolygonOptions()
            .addAll(points)
            .fillColor(GaodeMapParsing.argColor(call, "fillColor", 0x330000FF.toInt()))
            .strokeColor(GaodeMapParsing.argColor(call, "strokeColor", 0xFF0000FF.toInt()))
            .strokeWidth(call.argument<Number>("strokeWidth")?.toFloat() ?: 10f)
            .zIndex(call.argument<Int>("zIndex")?.toFloat() ?: 0f)
            .visible(call.argument<Boolean>("visible") ?: true)
        aMap.addPolygon(options)?.let { polygons[id] = it }
    }

    private fun addCircle(call: MethodCall) {
        val id = call.argument<String>("id")
            ?: throw IllegalArgumentException("id required")
        val center = GaodeMapParsing.latLng(call.argument("center"))
            ?: throw IllegalArgumentException("center required")
        val radius = call.argument<Double>("radius")
            ?: throw IllegalArgumentException("radius required")
        circles.remove(id)?.remove()
        val options = CircleOptions()
            .center(center)
            .radius(radius)
            .fillColor(GaodeMapParsing.argColor(call, "fillColor", 0x330000FF.toInt()))
            .strokeColor(GaodeMapParsing.argColor(call, "strokeColor", 0xFF0000FF.toInt()))
            .strokeWidth(call.argument<Number>("strokeWidth")?.toFloat() ?: 10f)
            .zIndex(call.argument<Int>("zIndex")?.toFloat() ?: 0f)
            .visible(call.argument<Boolean>("visible") ?: true)
        aMap.addCircle(options)?.let { circles[id] = it }
    }

    private fun addArc(call: MethodCall) {
        val id = call.argument<String>("id")
            ?: throw IllegalArgumentException("id required")
        val start = GaodeMapParsing.latLng(call.argument("start"))
            ?: throw IllegalArgumentException("start required")
        val passed = GaodeMapParsing.latLng(call.argument("passed"))
            ?: throw IllegalArgumentException("passed required")
        val end = GaodeMapParsing.latLng(call.argument("end"))
            ?: throw IllegalArgumentException("end required")
        arcs.remove(id)?.remove()
        val options = ArcOptions()
            .point(start, passed, end)
            .strokeColor(GaodeMapParsing.argColor(call, "strokeColor", 0xFF0000FF.toInt()))
            .strokeWidth(call.argument<Number>("strokeWidth")?.toFloat() ?: 10f)
            .zIndex(call.argument<Int>("zIndex")?.toFloat() ?: 0f)
            .visible(call.argument<Boolean>("visible") ?: true)
        aMap.addArc(options)?.let { arcs[id] = it }
    }

    private fun addGroundOverlay(call: MethodCall) {
        val id = call.argument<String>("id")
            ?: throw IllegalArgumentException("id required")
        @Suppress("UNCHECKED_CAST")
        val boundsMap = call.argument<Map<String, Any?>>("bounds")
            ?: throw IllegalArgumentException("bounds required")
        val bounds = boundsFromMap(boundsMap)
            ?: throw IllegalArgumentException("invalid bounds")
        @Suppress("UNCHECKED_CAST")
        val imageMap = call.argument<Map<String, Any?>>("image")
            ?: throw IllegalArgumentException("image required")
        val bytes = imageMap["bytes"] as? ByteArray
            ?: throw IllegalArgumentException("image bytes required")
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            ?: throw IllegalArgumentException("invalid image bytes")
        groundOverlays.remove(id)?.remove()
        val options = GroundOverlayOptions()
            .image(BitmapDescriptorFactory.fromBitmap(bitmap))
            .positionFromBounds(bounds)
            .transparency(call.argument<Number>("transparency")?.toFloat() ?: 0f)
            .zIndex(call.argument<Int>("zIndex")?.toFloat() ?: 0f)
            .visible(call.argument<Boolean>("visible") ?: true)
        aMap.addGroundOverlay(options)?.let { groundOverlays[id] = it }
    }

    private fun addHeatmap(call: MethodCall) {
        val id = call.argument<String>("id")
            ?: throw IllegalArgumentException("id required")
        @Suppress("UNCHECKED_CAST")
        val points = call.argument<List<Map<String, Any?>>>("points")
            ?: throw IllegalArgumentException("points required")
        val weighted = points.mapNotNull { point ->
            val lat = (point["latitude"] as? Number)?.toDouble() ?: return@mapNotNull null
            val lng = (point["longitude"] as? Number)?.toDouble() ?: return@mapNotNull null
            val intensity = (point["intensity"] as? Number)?.toDouble() ?: 1.0
            WeightedLatLng(LatLng(lat, lng), intensity)
        }
        if (weighted.isEmpty()) throw IllegalArgumentException("heatmap points required")
        heatmapTiles.remove(id)?.remove()
        val radius = call.argument<Int>("radius") ?: 38
        val opacity = call.argument<Number>("opacity")?.toDouble() ?: 0.6
        val provider = HeatmapTileProvider.Builder()
            .weightedData(weighted)
            .radius(radius)
            .transparency(1.0 - opacity)
            .build()
        val overlay = aMap.addTileOverlay(
            TileOverlayOptions()
                .tileProvider(provider)
                .zIndex(call.argument<Int>("zIndex")?.toFloat() ?: 0f)
                .visible(call.argument<Boolean>("visible") ?: true),
        )
        heatmapTiles[id] = overlay
    }

    private fun addMultiPoint(call: MethodCall) {
        val id = call.argument<String>("id")
            ?: throw IllegalArgumentException("id required")
        @Suppress("UNCHECKED_CAST")
        val points = GaodeMapParsing.latLngList(call.argument("points"))
        if (points.isEmpty()) throw IllegalArgumentException("points required")
        @Suppress("UNCHECKED_CAST")
        val iconMap = call.argument<Map<String, Any?>>("icon")
            ?: throw IllegalArgumentException("icon required")
        val descriptor = GaodeMapParsing.bitmapDescriptor(iconMap)
            ?: throw IllegalArgumentException("invalid icon")
        multiPoints.remove(id)?.remove()
        val items = points.map { MultiPointItem(it) }
        val overlay = aMap.addMultiPointOverlay(
            MultiPointOverlayOptions().icon(descriptor),
        )
        overlay.items = items
        overlay.setEnable(call.argument<Boolean>("visible") ?: true)
        multiPoints[id] = overlay
    }

    private fun addTileOverlay(call: MethodCall) {
        val id = call.argument<String>("id")
            ?: throw IllegalArgumentException("id required")
        val template = call.argument<String>("urlTemplate")
            ?: throw IllegalArgumentException("urlTemplate required")
        val tileSize = call.argument<Int>("tileSize") ?: 256
        tileOverlays.remove(id)?.remove()
        val provider = object : UrlTileProvider(tileSize, tileSize) {
            override fun getTileUrl(x: Int, y: Int, zoom: Int): URL? {
                val url = template
                    .replace("{x}", x.toString())
                    .replace("{y}", y.toString())
                    .replace("{z}", zoom.toString())
                return try {
                    URL(url)
                } catch (_: Exception) {
                    null
                }
            }
        }
        val overlay = aMap.addTileOverlay(
            TileOverlayOptions()
                .tileProvider(provider)
                .zIndex(call.argument<Int>("zIndex")?.toFloat() ?: 0f)
                .visible(call.argument<Boolean>("visible") ?: true),
        )
        tileOverlays[id] = overlay
    }

    private fun takeSnapshot(result: MethodChannel.Result) {
        val replied = AtomicBoolean(false)
        aMap.getMapScreenShot(
            object : OnMapScreenShotListener {
                override fun onMapScreenShot(bitmap: Bitmap?) {
                    if (!replied.compareAndSet(false, true)) return
                    if (bitmap == null) {
                        result.error("SNAPSHOT_FAILED", "bitmap is null", null)
                        return
                    }
                    val stream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                    result.success(stream.toByteArray())
                }

                override fun onMapScreenShot(bitmap: Bitmap?, status: Int) {
                    onMapScreenShot(bitmap)
                }
            },
        )
    }

    // region Map listeners

    override fun onMapClick(latLng: LatLng) {
        emit("tap", mapOf("coordinate" to GaodeMapParsing.coordinateMap(latLng)))
    }

    override fun onMapLongClick(latLng: LatLng) {
        emit("longPress", mapOf("coordinate" to GaodeMapParsing.coordinateMap(latLng)))
    }

    override fun onCameraChange(position: CameraPosition) {
        if (!cameraMoving) {
            cameraMoving = true
            emit("cameraMoveStart")
        }
        emit(
            "cameraMove",
            mapOf("position" to GaodeMapParsing.cameraMap(position.target, position.zoom, position.bearing, position.tilt)),
        )
    }

    override fun onCameraChangeFinish(position: CameraPosition) {
        cameraMoving = false
        emit(
            "cameraMoveEnd",
            mapOf("position" to GaodeMapParsing.cameraMap(position.target, position.zoom, position.bearing, position.tilt)),
        )
    }

    override fun onMarkerClick(marker: Marker): Boolean {
        val id = marker.getObject() as? String ?: return false
        emit("markerTap", mapOf("id" to id))
        if (marker.isInfoWindowEnable) {
            marker.showInfoWindow()
        }
        return true
    }

    override fun onMarkerDragStart(marker: Marker) {
        val id = marker.getObject() as? String ?: return
        emit(
            "markerDragStart",
            mapOf("id" to id, "position" to GaodeMapParsing.coordinateMap(marker.position)),
        )
    }

    override fun onMarkerDrag(marker: Marker) {
        val id = marker.getObject() as? String ?: return
        emit(
            "markerDrag",
            mapOf("id" to id, "position" to GaodeMapParsing.coordinateMap(marker.position)),
        )
    }

    override fun onMarkerDragEnd(marker: Marker) {
        val id = marker.getObject() as? String ?: return
        emit(
            "markerDragEnd",
            mapOf("id" to id, "position" to GaodeMapParsing.coordinateMap(marker.position)),
        )
    }

    // endregion

    private fun mapTypeValue(type: String?): Int {
        return when (type) {
            "satellite" -> AMap.MAP_TYPE_SATELLITE
            "night" -> AMap.MAP_TYPE_NIGHT
            "navi" -> AMap.MAP_TYPE_NAVI
            "bus" -> AMap.MAP_TYPE_BUS
            else -> AMap.MAP_TYPE_NORMAL
        }
    }

    private fun zoomPositionValue(position: String?): Int {
        return when (position) {
            "rightTop", "rightCenter" -> AMapOptions.ZOOM_POSITION_RIGHT_CENTER
            else -> AMapOptions.ZOOM_POSITION_RIGHT_BOTTOM
        }
    }

    private fun logoPositionValue(position: String?): Int {
        return when (position) {
            "centerBottom" -> AMapOptions.LOGO_POSITION_BOTTOM_CENTER
            "rightBottom" -> AMapOptions.LOGO_POSITION_BOTTOM_RIGHT
            else -> AMapOptions.LOGO_POSITION_BOTTOM_LEFT
        }
    }
}
