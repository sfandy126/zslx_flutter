# Generated missing classes from optional/native integrations.
-dontwarn com.baijiayun.live.ui.BR
-dontwarn com.baijiayun.liveshow.ui.BR
-dontwarn com.baijiayun.liveuibase.BR
-dontwarn com.hpplay.ble.AdvertiseManager
-dontwarn com.hpplay.ble.DiscoveryAdvertiseManager$BleDiscoveryCallback
-dontwarn com.hpplay.ble.DiscoveryAdvertiseManager
-dontwarn dalvik.system.VMStack

# 友盟 APM 通过反射调用的采集及上传组件。
-keep class com.umeng.** { *; }
-keep class com.uc.** { *; }
-keep class com.efs.** { *; }
-keepclassmembers class * {
    public <init>(org.json.JSONObject);
}
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
