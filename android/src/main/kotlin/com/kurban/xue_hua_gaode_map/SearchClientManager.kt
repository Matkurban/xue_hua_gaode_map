package com.kurban.xue_hua_gaode_map

import android.content.Context
import com.amap.api.services.core.AMapException
import com.amap.api.services.core.LatLonPoint
import com.amap.api.services.core.PoiItemV2
import com.amap.api.services.geocoder.GeocodeAddress
import com.amap.api.services.geocoder.GeocodeQuery
import com.amap.api.services.geocoder.GeocodeResult
import com.amap.api.services.geocoder.GeocodeSearch
import com.amap.api.services.geocoder.RegeocodeResult
import com.amap.api.services.help.Inputtips
import com.amap.api.services.help.InputtipsQuery
import com.amap.api.services.help.Tip
import com.amap.api.services.poisearch.PoiResultV2
import com.amap.api.services.poisearch.PoiSearchV2
import io.flutter.plugin.common.MethodChannel.Result
import java.util.Collections

/// Wraps the Amap Search SDK (POI keyword/around, input tips, geocode).
///
/// Each request keeps a strong reference to its search object until the async
/// callback fires, then releases it.
class SearchClientManager {
    private val inFlight = Collections.synchronizedSet(HashSet<Any>())

    fun poiKeyword(
        context: Context,
        keyword: String,
        city: String,
        type: String,
        page: Int,
        pageSize: Int,
        result: Result,
    ) {
        val query = PoiSearchV2.Query(keyword, type, city)
        query.pageSize = pageSize.coerceIn(1, 25)
        query.pageNum = page.coerceAtLeast(1)
        val search = PoiSearchV2(context, query)
        runPoiSearch(search, result)
    }

    fun poiAround(
        context: Context,
        latitude: Double,
        longitude: Double,
        keyword: String,
        type: String,
        radius: Int,
        page: Int,
        pageSize: Int,
        result: Result,
    ) {
        val query = PoiSearchV2.Query(keyword, type, "")
        query.pageSize = pageSize.coerceIn(1, 25)
        query.pageNum = page.coerceAtLeast(1)
        val search = PoiSearchV2(context, query)
        search.bound = PoiSearchV2.SearchBound(
            LatLonPoint(latitude, longitude),
            radius.coerceAtLeast(1),
        )
        runPoiSearch(search, result)
    }

    private fun runPoiSearch(search: PoiSearchV2, result: Result) {
        inFlight.add(search)
        var settled = false
        search.setOnPoiSearchListener(
            object : PoiSearchV2.OnPoiSearchListener {
                override fun onPoiSearched(pageResult: PoiResultV2?, errorCode: Int) {
                    inFlight.remove(search)
                    if (settled) return
                    settled = true
                    if (errorCode != AMapException.CODE_AMAP_SUCCESS) {
                        result.error("SEARCH_ERROR", "POI search failed ($errorCode)", null)
                        return
                    }
                    val pois = pageResult?.pois ?: arrayListOf()
                    val count = pageResult?.count ?: pois.size
                    val pageSize = search.query?.pageSize ?: 0
                    result.success(
                        mapOf(
                            "pois" to pois.map { poiToMap(it) },
                            "count" to count,
                            "pageCount" to if (pageSize > 0) {
                                (count + pageSize - 1) / pageSize
                            } else {
                                0
                            },
                        ),
                    )
                }

                override fun onPoiItemSearched(poiItem: PoiItemV2?, errorCode: Int) {
                    // POI id search is not exposed; ignored.
                }

                override fun onVisualSearched(
                    visualSearchResult: com.amap.api.services.poisearch.VisualSearchResult?,
                    errorCode: Int,
                ) {
                    // Visual (image) search is not exposed; ignored.
                }
            },
        )
        search.searchPOIAsyn()
    }

    fun inputTips(context: Context, keyword: String, city: String, result: Result) {
        val query = InputtipsQuery(keyword, city)
        val inputTips = Inputtips(context, query)
        inFlight.add(inputTips)
        var settled = false
        inputTips.setInputtipsListener { tipList, errorCode ->
            inFlight.remove(inputTips)
            if (settled) return@setInputtipsListener
            settled = true
            if (errorCode != AMapException.CODE_AMAP_SUCCESS) {
                result.error("SEARCH_ERROR", "Input tips failed ($errorCode)", null)
                return@setInputtipsListener
            }
            result.success((tipList ?: emptyList()).map { tipToMap(it) })
        }
        inputTips.requestInputtipsAsyn()
    }

    fun geocode(context: Context, address: String, city: String, result: Result) {
        val search: GeocodeSearch
        try {
            search = GeocodeSearch(context)
        } catch (e: AMapException) {
            result.error("SEARCH_ERROR", e.errorMessage ?: e.message, null)
            return
        }
        inFlight.add(search)
        var settled = false
        search.setOnGeocodeSearchListener(
            object : GeocodeSearch.OnGeocodeSearchListener {
                override fun onGeocodeSearched(geocodeResult: GeocodeResult?, errorCode: Int) {
                    inFlight.remove(search)
                    if (settled) return
                    settled = true
                    if (errorCode != AMapException.CODE_AMAP_SUCCESS) {
                        result.error("SEARCH_ERROR", "Geocode failed ($errorCode)", null)
                        return
                    }
                    val list = geocodeResult?.geocodeAddressList ?: arrayListOf()
                    result.success(
                        mapOf("geocodes" to list.map { geocodeToMap(it) }),
                    )
                }

                override fun onRegeocodeSearched(
                    regeocodeResult: RegeocodeResult?,
                    errorCode: Int
                ) {
                    // Reverse geocode is handled by the location module.
                }
            },
        )
        search.getFromLocationNameAsyn(GeocodeQuery(address, city))
    }

    private fun poiToMap(poi: PoiItemV2): Map<String, Any?> {
        val point = poi.latLonPoint
        return mapOf(
            "id" to poi.poiId,
            "name" to poi.title,
            "address" to poi.snippet,
            "latitude" to point?.latitude,
            "longitude" to point?.longitude,
            "type" to poi.typeDes,
            "province" to poi.provinceName,
            "city" to poi.cityName,
            "district" to poi.adName,
            "adCode" to poi.adCode,
        )
    }

    private fun tipToMap(tip: Tip): Map<String, Any?> {
        val point = tip.point
        return mapOf(
            "name" to tip.name,
            "district" to tip.district,
            "adCode" to tip.adcode,
            "latitude" to point?.latitude,
            "longitude" to point?.longitude,
            "address" to tip.address,
            "poiId" to tip.poiID,
        )
    }

    private fun geocodeToMap(address: GeocodeAddress): Map<String, Any?> {
        val point = address.latLonPoint
        return mapOf(
            "formattedAddress" to address.formatAddress,
            "latitude" to point?.latitude,
            "longitude" to point?.longitude,
            "province" to address.province,
            "city" to address.city,
            "district" to address.district,
            "adCode" to address.adcode,
            "level" to address.level,
        )
    }
}
