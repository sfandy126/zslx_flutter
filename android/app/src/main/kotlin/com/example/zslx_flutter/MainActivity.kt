package com.example.zslx_flutter

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Process
import androidx.exifinterface.media.ExifInterface
import com.umeng.commonsdk.UMConfigure
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors
import kotlin.math.max

class MainActivity : FlutterActivity() {
    companion object {
        // 友盟 preInit 只执行一次
        private var umengPreInited = false

        // 跨批次串行压缩，后台优先级避免挤占 UI 线程。
        private val compressionQueue = Executors.newSingleThreadExecutor { action ->
            Thread({
                Process.setThreadPriority(Process.THREAD_PRIORITY_BACKGROUND)
                action.run()
            }, "oss-image")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val main = Handler(Looper.getMainLooper())
        // 友盟合规预初始化：渠道由 Dart 侧从 AppChannel 传入，
        // 隐私政策同意前仅采集必要设备标识，正式初始化由 Dart 侧隐私同意后调用 initCommon 完成
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.zs.zslx/umeng")
            .setMethodCallHandler { call, result ->
                if (call.method == "preInit" && !umengPreInited) {
                    umengPreInited = true
                    val meta = packageManager
                        .getApplicationInfo(
                            packageName,
                            android.content.pm.PackageManager.GET_META_DATA,
                        ).metaData
                    UMConfigure.preInit(
                        this,
                        meta?.getString("UMENG_APPKEY") ?: "",
                        call.argument<String>("channel") ?: "",
                    )
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.zs.zslx/oss_image")
            .setMethodCallHandler { call, result ->
                if (call.method != "compress") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val source = call.argument<String>("sourcePath")
                val target = call.argument<String>("targetPath")
                val edge = call.argument<Int>("maxDimension")
                val quality = call.argument<Int>("quality")
                val maxBytes = call.argument<Int>("maxBytes")
                if (source == null || target == null || edge == null || quality == null || maxBytes == null) {
                    result.error("arguments", "图片压缩参数错误", null)
                    return@setMethodCallHandler
                }
                compressionQueue.execute {
                    try {
                        val value = compressImage(source, target, edge, quality, maxBytes)
                        main.post { result.success(value) }
                    } catch (_: OutOfMemoryError) {
                        main.post { result.error("compress_failed", "图片过大，压缩内存不足", null) }
                    } catch (_: Exception) {
                        main.post { result.error("compress_failed", "图片压缩失败，请检查源文件和大小限制", null) }
                    }
                }
            }
    }

    private fun compressImage(source: String, target: String, edge: Int,
                              quality: Int, maxBytes: Int): Map<String, Int> {
        require(edge in 1..4096 && quality in 1..100 && maxBytes in 1..(50 * 1024 * 1024))
        require(File(source).canonicalPath != File(target).canonicalPath)
        // 先读取尺寸再设置采样率，禁止完整解码超大原图。
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(source, bounds)
        require(bounds.outWidth > 0 && bounds.outHeight > 0)
        var sample = 1
        val longest = max(bounds.outWidth, bounds.outHeight).toLong()
        while ((longest + sample - 1) / sample > edge) {
            check(sample <= (1 shl 29))
            sample *= 2
        }
        val options = BitmapFactory.Options().apply {
            inSampleSize = sample
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        val decoded = BitmapFactory.decodeFile(source, options) ?: error("图片解码失败")
        var image = decoded
        try {
            val orientation = try {
                ExifInterface(source).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
            } catch (_: Exception) {
                ExifInterface.ORIENTATION_NORMAL
            }
            val transform = Matrix().apply {
                when (orientation) {
                    ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> setScale(-1f, 1f)
                    ExifInterface.ORIENTATION_ROTATE_180 -> setRotate(180f)
                    ExifInterface.ORIENTATION_FLIP_VERTICAL -> setScale(1f, -1f)
                    ExifInterface.ORIENTATION_TRANSPOSE -> { setRotate(90f); postScale(-1f, 1f) }
                    ExifInterface.ORIENTATION_ROTATE_90 -> setRotate(90f)
                    ExifInterface.ORIENTATION_TRANSVERSE -> { setRotate(-90f); postScale(-1f, 1f) }
                    ExifInterface.ORIENTATION_ROTATE_270 -> setRotate(-90f)
                }
            }
            image = Bitmap.createBitmap(decoded, 0, 0, decoded.width, decoded.height, transform, true)
            require(image.width <= edge && image.height <= edge)
            // 固定最多四次；超限只降低尺寸，不进行高 CPU 的无限质量搜索。
            repeat(4) { attempt ->
                val output = ByteArrayOutputStream()
                check(image.compress(Bitmap.CompressFormat.JPEG, quality, output))
                if (output.size() in 1..maxBytes) {
                    File(target).outputStream().use { output.writeTo(it) }
                    return mapOf("width" to image.width, "height" to image.height)
                }
                if (attempt < 3) {
                    val smaller = Bitmap.createScaledBitmap(image, max(1, image.width / 2), max(1, image.height / 2), true)
                    if (image !== decoded && image !== smaller) image.recycle()
                    image = smaller
                }
            }
            error("图片无法压缩到指定大小")
        } finally {
            if (image !== decoded) image.recycle()
            decoded.recycle()
        }
    }
}
