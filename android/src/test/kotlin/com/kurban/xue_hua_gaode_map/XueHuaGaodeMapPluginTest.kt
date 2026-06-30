package com.kurban.xue_hua_gaode_map

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

internal class XueHuaGaodeMapPluginTest {
    @Test
    fun unknownMethodIsNotImplemented() {
        val plugin = XueHuaGaodeMapPlugin()
        val call = MethodCall("unknownMethod", null)
        var notImplemented = false
        plugin.onMethodCall(
            call,
            object : MethodChannel.Result {
                override fun success(result: Any?) {}

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}

                override fun notImplemented() {
                    notImplemented = true
                }
            },
        )
        assertEquals(true, notImplemented)
    }

    @Test
    fun searchPoiKeywordWithoutPrivacyReturnsError() {
        AmapPrivacyState.privacyAgreed = false
        val plugin = XueHuaGaodeMapPlugin()
        val call = MethodCall(
            "search#poiKeyword",
            mapOf("keyword" to "coffee"),
        )
        var errorCode: String? = null
        plugin.onMethodCall(
            call,
            object : MethodChannel.Result {
                override fun success(result: Any?) {}

                override fun error(code: String, message: String?, details: Any?) {
                    errorCode = code
                }

                override fun notImplemented() {}
            },
        )
        assertEquals("PRIVACY_NOT_CONFIGURED", errorCode)
    }

    @Test
    fun searchPoiKeywordWithPrivacyDoesNotReturnPrivacyError() {
        AmapPrivacyState.privacyAgreed = true
        val plugin = XueHuaGaodeMapPlugin()
        val call = MethodCall(
            "search#poiKeyword",
            mapOf("keyword" to "coffee"),
        )
        var errorCode: String? = null
        var succeeded = false
        plugin.onMethodCall(
            call,
            object : MethodChannel.Result {
                override fun success(result: Any?) {
                    succeeded = true
                }

                override fun error(code: String, message: String?, details: Any?) {
                    errorCode = code
                }

                override fun notImplemented() {}
            },
        )
        assertTrue(!succeeded)
        assertTrue(errorCode != "PRIVACY_NOT_CONFIGURED")
    }
}
