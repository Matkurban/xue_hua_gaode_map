package com.kurban.xue_hua_gaode_map.map

import java.util.concurrent.CopyOnWriteArraySet

/// Tracks live [GaodeMapPlatformView]s so the plugin can forward host activity
/// lifecycle events (resume/pause) needed for correct map rendering.
class GaodeMapLifecycleRegistry {
    private val views = CopyOnWriteArraySet<GaodeMapPlatformView>()

    fun register(view: GaodeMapPlatformView) {
        views.add(view)
    }

    fun unregister(view: GaodeMapPlatformView) {
        views.remove(view)
    }

    fun onResume() {
        views.forEach { it.onResume() }
    }

    fun onPause() {
        views.forEach { it.onPause() }
    }

    fun destroyAll() {
        views.forEach { it.dispose() }
        views.clear()
    }
}
