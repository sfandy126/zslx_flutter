# Generated missing classes from optional/native integrations.
-dontwarn com.baijiayun.live.ui.BR
-dontwarn com.baijiayun.liveshow.ui.BR
-dontwarn com.baijiayun.liveuibase.BR
-dontwarn com.hpplay.ble.AdvertiseManager
-dontwarn com.hpplay.ble.DiscoveryAdvertiseManager$BleDiscoveryCallback
-dontwarn com.hpplay.ble.DiscoveryAdvertiseManager
-dontwarn dalvik.system.VMStack

# 百家云官方直播/点播/回放共用规则：包含反射及 JNI 调用的类型。
-dontwarn com.baijiahulian.**
-dontwarn com.bjhl.**
-keep class com.baijiahulian.** { *; }
-keep class com.bjhl.** { *; }
-keep class com.baijia.** { *; }
-keep class com.baijiayun.** { *; }
-keep class org.webrtc.** { *; }
-keep class com.tencent.** { *; }
-keep class org.boom.** { *; }
-keep class org.brtc.** { *; }
-keep class tv.danmaku.ijk.** { *; }
-keepclassmembers class * {
    @org.brtc.webrtc.CalledByNative <fields>;
    @org.brtc.webrtc.CalledByNative <methods>;
}
-dontwarn sun.misc.**
-keepclassmembers class rx.internal.util.unsafe.*ArrayQueue*Field* {
    long producerIndex;
    long consumerIndex;
}
-keepclassmembers class rx.internal.util.unsafe.BaseLinkedQueueProducerNodeRef {
    rx.internal.util.atomic.LinkedQueueNode producerNode;
}
-keepclassmembers class rx.internal.util.unsafe.BaseLinkedQueueConsumerNodeRef {
    rx.internal.util.atomic.LinkedQueueNode consumerNode;
}
# 不整体保留 log4j：其桌面 UI/JMS/邮件模块依赖 Android 不提供的 Java API。

# Retrofit 2.11.0 / Gson 2.11.0 的通用规则由依赖 JAR 的
# META-INF/proguard 自动合入，不在宿主重复维护。

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
