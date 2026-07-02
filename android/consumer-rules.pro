# ---------------- 高德 SDK 混淆配置 开始 ----------------

# 声明不提示高德 SDK 的警告（防止编译不过）
-dontwarn com.amap.api.**
-dontwarn com.autonavi.**
-dontwarn com.amap.location.**

# 保持高德核心包下的所有类和方法不被混淆
-keep class com.amap.api.** {*;}
-keep class com.autonavi.** {*;}

# 针对你日志中明确报错的定位支持库/日志库进行强制保持
-keep class com.amap.location.** {*;}

# 如果你使用了高德导航/3D地图等，通常也需要保持以下 native 方法映射类
-keep class com.autonavi.base.amap.mapcore.NativeBase {*;}

# ---------------- 高德 SDK 混淆配置 结束 ----------------