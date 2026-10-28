import Flutter
import UIKit
import ImageIO

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var ossImageChannel: FlutterMethodChannel?
  private static let ossCompressionQueue = DispatchQueue(label: "com.zs.zslx.oss-image", qos: .utility)

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MDOssImageCompressor") else { return }
    let channel = FlutterMethodChannel(name: "com.zs.zslx/oss_image", binaryMessenger: registrar.messenger())
    ossImageChannel = channel
    channel.setMethodCallHandler { call, result in
      guard call.method == "compress" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any],
            let source = args["sourcePath"] as? String,
            let target = args["targetPath"] as? String,
            let maxDimension = args["maxDimension"] as? Int,
            let quality = args["quality"] as? Int,
            let maxBytes = args["maxBytes"] as? Int else {
        result(FlutterError(code: "arguments", message: "图片压缩参数错误", details: nil))
        return
      }
      // 全局串行后台队列，避免多张大图同时解码引起 CPU/内存峰值。
      Self.ossCompressionQueue.async {
        autoreleasepool {
          do {
            let value = try MDOssImageCompressor.compress(
              source: source, target: target, maxDimension: maxDimension,
              quality: quality, maxBytes: maxBytes
            )
            DispatchQueue.main.async { result(value) }
          } catch {
            let message = error.localizedDescription
            DispatchQueue.main.async {
              result(FlutterError(code: "compress_failed", message: message, details: nil))
            }
          }
        }
      }
    }
  }
}

/// 只从文件源创建降采样缩略图，不先构造全尺寸 UIImage。
/// 不携带原图 EXIF/GPS，ImageIO 在缩略图阶段修正图片方向。
enum MDOssImageCompressor {
  private enum CompressionError: LocalizedError {
    case invalidArguments, decode, encode, tooLarge
    var errorDescription: String? {
      switch self {
      case .invalidArguments: return "图片压缩参数错误"
      case .decode: return "无法读取或解码图片"
      case .encode: return "图片编码失败"
      case .tooLarge: return "图片无法压缩到指定大小"
      }
    }
  }

  static func compress(source: String, target: String, maxDimension: Int,
                       quality: Int, maxBytes: Int) throws -> [String: Int] {
    guard (1...4096).contains(maxDimension), (1...100).contains(quality),
          (1...(50 * 1024 * 1024)).contains(maxBytes),
          URL(fileURLWithPath: source).standardizedFileURL != URL(fileURLWithPath: target).standardizedFileURL else {
      throw CompressionError.invalidArguments
    }
    let options = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let imageSource = CGImageSourceCreateWithURL(URL(fileURLWithPath: source) as CFURL, options) else {
      throw CompressionError.decode
    }
    var edge = maxDimension
    // 固定最多四次，不循环进行高 CPU 的质量二分搜索。
    for _ in 0..<4 {
      let encoded: (Data, Int, Int) = try autoreleasepool {
        let thumbnailOptions: [CFString: Any] = [
          kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceCreateThumbnailWithTransform: true,
          kCGImageSourceThumbnailMaxPixelSize: edge,
          kCGImageSourceShouldCacheImmediately: true
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, thumbnailOptions as CFDictionary),
              image.width > 0, image.height > 0,
              image.width <= maxDimension, image.height <= maxDimension else {
          throw CompressionError.decode
        }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, "public.jpeg" as CFString, 1, nil) else {
          throw CompressionError.encode
        }
        CGImageDestinationAddImage(destination, image, [
          kCGImageDestinationLossyCompressionQuality: Double(quality) / 100
        ] as CFDictionary)
        guard CGImageDestinationFinalize(destination), data.length > 0 else {
          throw CompressionError.encode
        }
        return (data as Data, image.width, image.height)
      }
      if encoded.0.count <= maxBytes {
        try encoded.0.write(to: URL(fileURLWithPath: target), options: .atomic)
        return ["width": encoded.1, "height": encoded.2]
      }
      edge = max(1, edge / 2)
    }
    throw CompressionError.tooLarge
  }
}
