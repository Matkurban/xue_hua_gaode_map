package com.kurban.xue_hua_gaode_map

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.assertEquals
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
}
