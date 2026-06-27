package com.kurban.xue_hua_gaode_map.map

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/// Creates [GaodeMapPlatformView] instances for the `xue_hua_gaode_map/map`
/// platform view type.
class GaodeMapViewFactory(
    private val messenger: BinaryMessenger,
    private val lifecycleRegistry: GaodeMapLifecycleRegistry,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val params = args as? Map<String, Any?> ?: emptyMap()
        val view = GaodeMapPlatformView(context, messenger, viewId, params, lifecycleRegistry)
        lifecycleRegistry.register(view)
        return view
    }
}
