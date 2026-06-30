package com.kurban.xue_hua_gaode_map

import android.app.Activity
import android.app.Application
import android.content.Context
import android.os.Bundle
import com.kurban.xue_hua_gaode_map.map.GaodeMapLifecycleRegistry
import com.kurban.xue_hua_gaode_map.map.GaodeMapViewFactory
import com.kurban.xue_hua_gaode_map.map.OfflineMapHandler
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class XueHuaGaodeMapPlugin :
    FlutterPlugin,
    ActivityAware,
    Application.ActivityLifecycleCallbacks,
    MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: Context
    private lateinit var locationEventChannel: EventChannel
    private lateinit var geofenceEventChannel: EventChannel
    private lateinit var offlineMapEventChannel: EventChannel
    private val mapLifecycleRegistry = GaodeMapLifecycleRegistry()
    private val searchClientManager = SearchClientManager()
    private lateinit var offlineMapHandler: OfflineMapHandler
    private var trackedActivity: Activity? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        offlineMapHandler = OfflineMapHandler(applicationContext)
        val messenger = flutterPluginBinding.binaryMessenger
        channel = MethodChannel(messenger, "xue_hua_gaode_map")
        channel.setMethodCallHandler(this)

        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "xue_hua_gaode_map/map",
            GaodeMapViewFactory(messenger, mapLifecycleRegistry),
        )

        locationEventChannel = EventChannel(messenger, "xue_hua_gaode_map/location")
        locationEventChannel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    val clientId = arguments as? String ?: return
                    LocationClientRegistry.getOrCreate(applicationContext, clientId)
                        .setEventSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    val clientId = arguments as? String ?: return
                    LocationClientRegistry.get(applicationContext, clientId)?.setEventSink(null)
                }
            },
        )

        geofenceEventChannel = EventChannel(messenger, "xue_hua_gaode_map/geofence")
        geofenceEventChannel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    val clientId = arguments as? String ?: return
                    GeofenceClientRegistry.getOrCreate(applicationContext, clientId)
                        .setEventSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    val clientId = arguments as? String ?: return
                    GeofenceClientRegistry.get(applicationContext, clientId)?.setEventSink(null)
                }
            },
        )

        offlineMapEventChannel = EventChannel(messenger, "xue_hua_gaode_map/offline_map")
        offlineMapEventChannel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    offlineMapHandler.setEventSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    offlineMapHandler.setEventSink(null)
                }
            },
        )
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "updatePrivacyShow" -> {
                val hasContains = call.argument<Boolean>("hasContains") ?: false
                val hasShow = call.argument<Boolean>("hasShow") ?: false
                AmapCoreHandler.updatePrivacyShow(applicationContext, hasContains, hasShow)
                result.success(null)
            }

            "updatePrivacyAgree" -> {
                val hasAgree = call.argument<Boolean>("hasAgree") ?: false
                AmapCoreHandler.updatePrivacyAgree(applicationContext, hasAgree)
                result.success(null)
            }

            "setApiKey" -> {
                val apiKey = call.argument<String>("apiKey")
                if (apiKey.isNullOrEmpty()) {
                    result.error("INVALID_ARGUMENT", "apiKey is required", null)
                } else {
                    AmapCoreHandler.setApiKey(apiKey)
                    result.success(null)
                }
            }

            "setRegionLanguage" -> {
                // Android V11+ links GeoLanguage through location options at request time.
                result.success(null)
            }

            "updateCountryCode" -> {
                val countryCode = call.argument<String>("countryCode")
                if (countryCode.isNullOrEmpty()) {
                    result.error("INVALID_ARGUMENT", "countryCode is required", null)
                } else {
                    AmapCoreHandler.updateCountryCode(countryCode)
                    result.success(null)
                }
            }

            "location#setOptions" -> handleLocationSetOptions(call, result)
            "location#start" -> handleLocationStart(call, result)
            "location#stop" -> handleLocationStop(call, result)
            "location#getOnce" -> handleLocationGetOnce(call, result)
            "location#destroy" -> handleLocationDestroy(call, result)
            "location#reverseGeocode" -> handleLocationReverseGeocode(call, result)
            "geofence#setActiveActions" -> handleGeofenceSetActiveActions(call, result)
            "geofence#addCircle" -> handleGeofenceAddCircle(call, result)
            "geofence#addPolygon" -> handleGeofenceAddPolygon(call, result)
            "geofence#addPoiKeyword" -> handleGeofenceAddPoiKeyword(call, result)
            "geofence#addPoiAround" -> handleGeofenceAddPoiAround(call, result)
            "geofence#addDistrict" -> handleGeofenceAddDistrict(call, result)
            "geofence#remove" -> handleGeofenceRemove(call, result)
            "geofence#removeAll" -> handleGeofenceRemoveAll(call, result)
            "geofence#pause" -> handleGeofencePause(call, result)
            "geofence#resume" -> handleGeofenceResume(call, result)
            "geofence#destroy" -> handleGeofenceDestroy(call, result)
            "search#poiKeyword" -> handleSearchPoiKeyword(call, result)
            "search#poiAround" -> handleSearchPoiAround(call, result)
            "search#inputTips" -> handleSearchInputTips(call, result)
            "search#geocode" -> handleSearchGeocode(call, result)
            "offlineMap#setStoragePath" -> handleOfflineSetStoragePath(call, result)
            "offlineMap#getCityList" -> handleOfflineGetCityList(result)
            "offlineMap#downloadByCityCode" -> handleOfflineDownloadByCityCode(call, result)
            "offlineMap#downloadByCityName" -> handleOfflineDownloadByCityName(call, result)
            "offlineMap#pause" -> handleOfflinePause(call, result)
            "offlineMap#resume" -> handleOfflineResume(call, result)
            "offlineMap#remove" -> handleOfflineRemove(call, result)
            "offlineMap#getDownloadStatus" -> handleOfflineGetDownloadStatus(call, result)
            "offlineMap#destroy" -> {
                offlineMapHandler.destroy()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun handleOfflineSetStoragePath(call: MethodCall, result: Result) {
        val path = call.argument<String>("path")
            ?: return result.error("INVALID_ARGUMENT", "path required", null)
        runPrivacyGated(result) {
            offlineMapHandler.setStoragePath(path)
            result.success(null)
        }
    }

    private fun handleOfflineGetCityList(result: Result) {
        runPrivacyGated(result) {
            result.success(offlineMapHandler.getCityList())
        }
    }

    private fun handleOfflineDownloadByCityCode(call: MethodCall, result: Result) {
        val cityCode = call.argument<String>("cityCode")
            ?: return result.error("INVALID_ARGUMENT", "cityCode required", null)
        runPrivacyGated(result) {
            offlineMapHandler.downloadByCityCode(cityCode)
            result.success(null)
        }
    }

    private fun handleOfflineDownloadByCityName(call: MethodCall, result: Result) {
        val cityName = call.argument<String>("cityName")
            ?: return result.error("INVALID_ARGUMENT", "cityName required", null)
        runPrivacyGated(result) {
            offlineMapHandler.downloadByCityName(cityName)
            result.success(null)
        }
    }

    private fun handleOfflinePause(call: MethodCall, result: Result) {
        val cityCode = call.argument<String>("cityCode")
            ?: return result.error("INVALID_ARGUMENT", "cityCode required", null)
        runPrivacyGated(result) {
            offlineMapHandler.pause(cityCode)
            result.success(null)
        }
    }

    private fun handleOfflineResume(call: MethodCall, result: Result) {
        val cityCode = call.argument<String>("cityCode")
            ?: return result.error("INVALID_ARGUMENT", "cityCode required", null)
        runPrivacyGated(result) {
            offlineMapHandler.resume(cityCode)
            result.success(null)
        }
    }

    private fun handleOfflineRemove(call: MethodCall, result: Result) {
        val cityCode = call.argument<String>("cityCode")
            ?: return result.error("INVALID_ARGUMENT", "cityCode required", null)
        runPrivacyGated(result) {
            offlineMapHandler.remove(cityCode)
            result.success(null)
        }
    }

    private fun handleOfflineGetDownloadStatus(call: MethodCall, result: Result) {
        val cityCode = call.argument<String>("cityCode")
            ?: return result.error("INVALID_ARGUMENT", "cityCode required", null)
        runPrivacyGated(result) {
            result.success(offlineMapHandler.getDownloadStatus(cityCode))
        }
    }

    private fun handleSearchPoiKeyword(call: MethodCall, result: Result) {
        val keyword = call.argument<String>("keyword")
            ?: return result.error("INVALID_ARGUMENT", "keyword required", null)
        runPrivacyGated(result) {
            searchClientManager.poiKeyword(
                applicationContext,
                keyword,
                call.argument<String>("city") ?: "",
                call.argument<String>("type") ?: "",
                call.argument<Int>("page") ?: 1,
                call.argument<Int>("pageSize") ?: 20,
                result,
            )
        }
    }

    private fun handleSearchPoiAround(call: MethodCall, result: Result) {
        val lat = call.argument<Double>("latitude")
            ?: return result.error("INVALID_ARGUMENT", "latitude required", null)
        val lng = call.argument<Double>("longitude")
            ?: return result.error("INVALID_ARGUMENT", "longitude required", null)
        runPrivacyGated(result) {
            searchClientManager.poiAround(
                applicationContext,
                lat,
                lng,
                call.argument<String>("keyword") ?: "",
                call.argument<String>("type") ?: "",
                call.argument<Int>("radius") ?: 3000,
                call.argument<Int>("page") ?: 1,
                call.argument<Int>("pageSize") ?: 20,
                result,
            )
        }
    }

    private fun handleSearchInputTips(call: MethodCall, result: Result) {
        val keyword = call.argument<String>("keyword")
            ?: return result.error("INVALID_ARGUMENT", "keyword required", null)
        runPrivacyGated(result) {
            searchClientManager.inputTips(
                applicationContext,
                keyword,
                call.argument<String>("city") ?: "",
                result,
            )
        }
    }

    private fun handleSearchGeocode(call: MethodCall, result: Result) {
        val address = call.argument<String>("address")
            ?: return result.error("INVALID_ARGUMENT", "address required", null)
        runPrivacyGated(result) {
            searchClientManager.geocode(
                applicationContext,
                address,
                call.argument<String>("city") ?: "",
                result,
            )
        }
    }

    private fun clientId(call: MethodCall): String? = call.argument<String>("clientId")

    private inline fun runPrivacyGated(result: Result, block: () -> Unit) {
        try {
            block()
        } catch (e: IllegalStateException) {
            result.error("PRIVACY_NOT_CONFIGURED", e.message, null)
        } catch (e: IllegalArgumentException) {
            result.error("INVALID_ARGUMENT", e.message, null)
        } catch (e: Exception) {
            result.error("PLATFORM_ERROR", e.message, null)
        }
    }

    private fun handleLocationSetOptions(call: MethodCall, result: Result) {
        val id =
            clientId(call) ?: return result.error("INVALID_ARGUMENT", "clientId required", null)

        @Suppress("UNCHECKED_CAST")
        val options = call.argument<Map<String, Any?>>("options") ?: emptyMap()
        runPrivacyGated(result) {
            LocationClientRegistry.getOrCreate(applicationContext, id).setOptions(options)
            result.success(null)
        }
    }

    private fun handleLocationStart(call: MethodCall, result: Result) {
        val id =
            clientId(call) ?: return result.error("INVALID_ARGUMENT", "clientId required", null)
        runPrivacyGated(result) {
            LocationClientRegistry.getOrCreate(applicationContext, id).start()
            result.success(null)
        }
    }

    private fun handleLocationStop(call: MethodCall, result: Result) {
        val id =
            clientId(call) ?: return result.error("INVALID_ARGUMENT", "clientId required", null)
        LocationClientRegistry.getOrCreate(applicationContext, id).stop()
        result.success(null)
    }

    private fun handleLocationGetOnce(call: MethodCall, result: Result) {
        val id =
            clientId(call) ?: return result.error("INVALID_ARGUMENT", "clientId required", null)
        try {
            LocationClientRegistry.getOrCreate(applicationContext, id).getOnce { locationResult ->
                locationResult
                    .onSuccess { result.success(it) }
                    .onFailure { result.error("LOCATION_ERROR", it.message, null) }
            }
        } catch (e: IllegalStateException) {
            result.error("PRIVACY_NOT_CONFIGURED", e.message, null)
        }
    }

    private fun handleLocationDestroy(call: MethodCall, result: Result) {
        val id =
            clientId(call) ?: return result.error("INVALID_ARGUMENT", "clientId required", null)
        LocationClientRegistry.destroy(id)
        result.success(null)
    }

    private fun handleLocationReverseGeocode(call: MethodCall, result: Result) {
        val id =
            clientId(call) ?: return result.error("INVALID_ARGUMENT", "clientId required", null)
        val lat = call.argument<Double>("latitude")
        val lng = call.argument<Double>("longitude")
        if (lat == null || lng == null) {
            result.error("INVALID_ARGUMENT", "latitude and longitude required", null)
            return
        }
        try {
            LocationClientRegistry.getOrCreate(applicationContext, id)
                .reverseGeocode(lat, lng) { locationResult ->
                    locationResult
                        .onSuccess { result.success(it) }
                        .onFailure { result.error("REGEOCODE_ERROR", it.message, null) }
                }
        } catch (e: IllegalStateException) {
            result.error("PRIVACY_NOT_CONFIGURED", e.message, null)
        }
    }

    private fun handleGeofenceSetActiveActions(call: MethodCall, result: Result) {
        val id =
            clientId(call) ?: return result.error("INVALID_ARGUMENT", "clientId required", null)
        val actions = call.argument<List<String>>("actions") ?: listOf("enter")
        runPrivacyGated(result) {
            GeofenceClientRegistry.getOrCreate(applicationContext, id).setActiveActions(actions)
            result.success(null)
        }
    }

    private fun handleGeofenceAddCircle(call: MethodCall, result: Result) {
        val id =
            clientId(call) ?: return result.error("INVALID_ARGUMENT", "clientId required", null)
        val lat =
            call.argument<Double>("latitude") ?: return result.error(
                "INVALID_ARGUMENT",
                "latitude required",
                null
            )
        val lng =
            call.argument<Double>("longitude") ?: return result.error(
                "INVALID_ARGUMENT",
                "longitude required",
                null
            )
        val radius = call.argument<Double>("radius")?.toFloat()
            ?: return result.error("INVALID_ARGUMENT", "radius required", null)
        val customId =
            call.argument<String>("customId") ?: return result.error(
                "INVALID_ARGUMENT",
                "customId required",
                null
            )
        runPrivacyGated(result) {
            GeofenceClientRegistry.getOrCreate(applicationContext, id)
                .addCircle(lat, lng, radius, customId)
            result.success(null)
        }
    }

    private fun handleGeofenceAddPolygon(call: MethodCall, result: Result) {
        val id =
            clientId(call) ?: return result.error("INVALID_ARGUMENT", "clientId required", null)

        @Suppress("UNCHECKED_CAST")
        val points = call.argument<List<Map<String, Any?>>>("points")
            ?: return result.error("INVALID_ARGUMENT", "points required", null)
        val customId =
            call.argument<String>("customId") ?: return result.error(
                "INVALID_ARGUMENT",
                "customId required",
                null
            )
        runPrivacyGated(result) {
            GeofenceClientRegistry.getOrCreate(applicationContext, id).addPolygon(points, customId)
            result.success(null)
        }
    }

    private fun handleGeofenceAddPoiKeyword(call: MethodCall, result: Result) {
        val id =
            clientId(call) ?: return result.error("INVALID_ARGUMENT", "clientId required", null)
        val keyword =
            call.argument<String>("keyword") ?: return result.error(
                "INVALID_ARGUMENT",
                "keyword required",
                null
            )
        val poiType = call.argument<String>("poiType") ?: ""
        val city = call.argument<String>("city") ?: ""
        val size = call.argument<Int>("size") ?: 1
        val customId =
            call.argument<String>("customId") ?: return result.error(
                "INVALID_ARGUMENT",
                "customId required",
                null
            )
        runPrivacyGated(result) {
            GeofenceClientRegistry.getOrCreate(applicationContext, id)
                .addPoiKeyword(keyword, poiType, city, size, customId)
            result.success(null)
        }
    }

    private fun handleGeofenceAddPoiAround(call: MethodCall, result: Result) {
        val id =
            clientId(call) ?: return result.error("INVALID_ARGUMENT", "clientId required", null)
        val keyword =
            call.argument<String>("keyword") ?: return result.error(
                "INVALID_ARGUMENT",
                "keyword required",
                null
            )
        val poiType = call.argument<String>("poiType") ?: ""
        val lat =
            call.argument<Double>("latitude") ?: return result.error(
                "INVALID_ARGUMENT",
                "latitude required",
                null
            )
        val lng =
            call.argument<Double>("longitude") ?: return result.error(
                "INVALID_ARGUMENT",
                "longitude required",
                null
            )
        val aroundRadius = call.argument<Double>("aroundRadius")?.toFloat() ?: 3000f
        val size = call.argument<Int>("size") ?: 10
        val customId =
            call.argument<String>("customId") ?: return result.error(
                "INVALID_ARGUMENT",
                "customId required",
                null
            )
        runPrivacyGated(result) {
            GeofenceClientRegistry.getOrCreate(applicationContext, id)
                .addPoiAround(keyword, poiType, lat, lng, aroundRadius, size, customId)
            result.success(null)
        }
    }

    private fun handleGeofenceAddDistrict(call: MethodCall, result: Result) {
        val id =
            clientId(call) ?: return result.error("INVALID_ARGUMENT", "clientId required", null)
        val keyword =
            call.argument<String>("keyword") ?: return result.error(
                "INVALID_ARGUMENT",
                "keyword required",
                null
            )
        val customId =
            call.argument<String>("customId") ?: return result.error(
                "INVALID_ARGUMENT",
                "customId required",
                null
            )
        runPrivacyGated(result) {
            GeofenceClientRegistry.getOrCreate(applicationContext, id)
                .addDistrict(keyword, customId)
            result.success(null)
        }
    }

    private fun handleGeofenceRemove(call: MethodCall, result: Result) {
        val id =
            clientId(call) ?: return result.error("INVALID_ARGUMENT", "clientId required", null)
        runPrivacyGated(result) {
            GeofenceClientRegistry.getOrCreate(applicationContext, id)
                .remove(call.argument("customId"))
            result.success(null)
        }
    }

    private fun handleGeofenceRemoveAll(call: MethodCall, result: Result) {
        val id =
            clientId(call) ?: return result.error("INVALID_ARGUMENT", "clientId required", null)
        runPrivacyGated(result) {
            GeofenceClientRegistry.getOrCreate(applicationContext, id).removeAll()
            result.success(null)
        }
    }

    private fun handleGeofencePause(call: MethodCall, result: Result) {
        val id =
            clientId(call) ?: return result.error("INVALID_ARGUMENT", "clientId required", null)
        runPrivacyGated(result) {
            GeofenceClientRegistry.getOrCreate(applicationContext, id).pause()
            result.success(null)
        }
    }

    private fun handleGeofenceResume(call: MethodCall, result: Result) {
        val id =
            clientId(call) ?: return result.error("INVALID_ARGUMENT", "clientId required", null)
        runPrivacyGated(result) {
            GeofenceClientRegistry.getOrCreate(applicationContext, id).resume()
            result.success(null)
        }
    }

    private fun handleGeofenceDestroy(call: MethodCall, result: Result) {
        val id =
            clientId(call) ?: return result.error("INVALID_ARGUMENT", "clientId required", null)
        GeofenceClientRegistry.destroy(id)
        result.success(null)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        locationEventChannel.setStreamHandler(null)
        geofenceEventChannel.setStreamHandler(null)
        offlineMapEventChannel.setStreamHandler(null)
        LocationClientRegistry.destroyAll()
        GeofenceClientRegistry.destroyAll()
        mapLifecycleRegistry.destroyAll()
        if (::offlineMapHandler.isInitialized) {
            offlineMapHandler.destroy()
        }
        AmapPrivacyState.privacyAgreed = false
    }

    // region ActivityAware — forward host activity lifecycle to live map views.

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        trackedActivity = binding.activity
        binding.activity.application.registerActivityLifecycleCallbacks(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
        mapLifecycleRegistry.onResume()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        mapLifecycleRegistry.onPause()
        onDetachedFromActivity()
    }

    override fun onDetachedFromActivity() {
        trackedActivity?.application?.unregisterActivityLifecycleCallbacks(this)
        trackedActivity = null
    }

    override fun onActivityResumed(activity: Activity) {
        if (activity === trackedActivity) mapLifecycleRegistry.onResume()
    }

    override fun onActivityPaused(activity: Activity) {
        if (activity === trackedActivity) mapLifecycleRegistry.onPause()
    }

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}

    override fun onActivityStarted(activity: Activity) {}

    override fun onActivityStopped(activity: Activity) {}

    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}

    override fun onActivityDestroyed(activity: Activity) {}

    // endregion
}
