import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_oss_aliyun/flutter_oss_aliyun.dart' as aliyun;
import 'package:path_provider/path_provider.dart';
import 'md_post.dart';

enum MDOssTaskState { waiting, compressing, uploading, success, failed }

@immutable
class MDOssTask {
  const MDOssTask({
    required this.index,
    required this.imagePath,
    this.state = .waiting,
    this.progress = 0,
    this.sentBytes = 0,
    this.totalBytes = 0,
    this.url,
    this.error,
  });

  /// 始终对应输入图片的位置，包括重复路径和失败图片。
  final int index;
  final String imagePath;
  final MDOssTaskState state;
  final double progress;
  final int sentBytes;
  final int totalBytes;
  final String? url;
  final String? error;

  MDOssTask _with({
    MDOssTaskState? state,
    double? progress,
    int? sentBytes,
    int? totalBytes,
    String? url,
    String? error,
  }) => MDOssTask(
    index: index,
    imagePath: imagePath,
    state: state ?? this.state,
    progress: progress ?? this.progress,
    sentBytes: sentBytes ?? this.sentBytes,
    totalBytes: totalBytes ?? this.totalBytes,
    url: url ?? this.url,
    error: error ?? this.error,
  );
}

class MDOssResult {
  MDOssResult(List<MDOssTask> tasks) : tasks = List.unmodifiable(tasks);

  /// 与输入一一对应，顺序不受上传完成先后影响。
  final List<MDOssTask> tasks;

  /// 成功地址按输入顺序排列；需要保留失败占位时使用 [orderedUrls]。
  List<String> get urls =>
      List.unmodifiable(tasks.map((e) => e.url).whereType<String>());
  List<String?> get orderedUrls => List.unmodifiable(tasks.map((e) => e.url));
  List<MDOssTask> get fails =>
      List.unmodifiable(tasks.where((e) => e.state == .failed));
  bool get isSuccess => fails.isEmpty;
}

typedef _OssClient = ({aliyun.Client client, String host});

/// 多图 OSS 上传；直接传入 ImagePicker 返回的本地文件路径。
/// 单个文档（pdf/word）使用 [MDOss.uploadFile]。
class MDOss {
  MDOss._();

  /// [uploadFile] 支持的扩展名及上传时使用的 MIME
  static const fileTypes = {
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  };

  static const _imageChannel = MethodChannel('com.zs.zslx/oss_image');
  static final _compressionGate = _OssGate(1);
  static final _uploadGate = _OssGate(3);
  static final _random = Random.secure();
  static Future<_OssConfig>? _loadingConfig;

  // 独立于业务 HTTP 客户端，避免向 OSS 附带业务 token/sign 或业务拦截器。
  // 插件内部 Dio 是静态字段，各批次初始化时必须复用同一个实例。
  static final _session = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(minutes: 5),
      receiveTimeout: const Duration(seconds: 60),
      responseType: ResponseType.plain,
      followRedirects: false,
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    ),
  );

  @visibleForTesting
  static Dio get uploadSession => _session;

  /// 所有图片必须重编码为 JPEG 后才能上传，失败时不会退回原图。
  ///
  /// 压缩全局串行，在原生后台队列降采样；默认最长边 2560px、质量 85、
  /// 最大 5MB。最长边上限 4096px，低于 Apple 9000px 风险边界。
  /// 上传每批默认并发 3 张，全局最多 3 张；不会把整批原图读入 Dart 内存。
  /// [progress] 实时返回按输入顺序排列的不可变快照，失败查看 state/error。
  static Future<MDOssResult> upload(
    List<String> images, {
    ValueChanged<List<MDOssTask>>? progress,
    int maxConcurrentUploads = 3,
    int maxDimension = 2560,
    int quality = 85,
    int maxBytes = 5 * 1024 * 1024,
  }) async {
    if (maxConcurrentUploads < 1 || maxConcurrentUploads > 3) {
      throw ArgumentError.value(
        maxConcurrentUploads,
        'maxConcurrentUploads',
        '必须在 1 到 3 之间',
      );
    }
    if (maxDimension < 1 || maxDimension > 4096) {
      throw ArgumentError.value(
        maxDimension,
        'maxDimension',
        '必须在 1 到 4096 之间',
      );
    }
    if (quality < 1 ||
        quality > 100 ||
        maxBytes < 1 ||
        maxBytes > 50 * 1024 * 1024) {
      throw ArgumentError('quality 必须在 1 到 100 之间，maxBytes 必须在 1 到 50MB 之间');
    }

    final tasks = List.generate(
      images.length,
      (i) => MDOssTask(index: i, imagePath: images[i]),
    );
    void report() {
      if (progress == null) return;
      try {
        progress(List.unmodifiable(tasks));
      } catch (_) {
        // UI 回调异常不能中断上传，也不能把已上传的图片误报为失败。
        debugPrint('OSS 上传进度回调异常');
      }
    }

    report();
    if (tasks.isEmpty) return MDOssResult(tasks);
    Directory? directory;
    try {
      final oss = await _client();
      final temp = await getTemporaryDirectory();
      directory = await temp.createTemp('md_oss_');
      final batchDirectory = directory;
      var nextIndex = 0;

      Future<void> worker() async {
        while (nextIndex < tasks.length) {
          final index = nextIndex++;
          final target = '${batchDirectory.path}/$index.jpg';
          try {
            await _compressionGate.run(() async {
              tasks[index] = tasks[index]._with(
                state: .compressing,
              );
              report();
              final dimensions = await _imageChannel
                  .invokeMapMethod<String, dynamic>('compress', {
                    'sourcePath': tasks[index].imagePath,
                    'targetPath': target,
                    'maxDimension': maxDimension,
                    'quality': quality,
                    'maxBytes': maxBytes,
                  });
              final width = dimensions?['width'];
              final height = dimensions?['height'];
              final bytes = await File(target).length();
              if (width is! int ||
                  height is! int ||
                  width < 1 ||
                  height < 1 ||
                  width > maxDimension ||
                  height > maxDimension ||
                  bytes < 1 ||
                  bytes > maxBytes) {
                throw StateError('图片压缩结果不符合尺寸或大小限制');
              }
              tasks[index] = tasks[index]._with(totalBytes: bytes);
            });

            await _uploadGate.run(() async {
              tasks[index] = tasks[index]._with(
                state: .uploading,
              );
              report();
              final key = _objectKey();
              await oss.client.putObjectFile(
                target,
                fileKey: key,
                option: aliyun.PutRequestOption(
                  override: false,
                  headers: const {'content-type': 'image/jpeg'},
                  onSendProgress: (sent, total) {
                    if (total <= 0) return;
                    final value = (sent / total).clamp(0.0, 0.99);
                    tasks[index] = tasks[index]._with(
                      progress: max(tasks[index].progress, value),
                      sentBytes: sent.clamp(0, total),
                      totalBytes: total,
                    );
                    report();
                  },
                ),
              );
              tasks[index] = tasks[index]._with(
                state: .success,
                progress: 1,
                sentBytes: tasks[index].totalBytes,
                url: 'https://${oss.host}/$key',
              );
            });
          } catch (error) {
            tasks[index] = tasks[index]._with(
              state: .failed,
              error: _message(error),
            );
          }
          report();
        }
      }

      await Future.wait(
        List.generate(min(maxConcurrentUploads, tasks.length), (_) => worker()),
      );
    } catch (error) {
      // STS/临时目录初始化失败仍返回完整任务，方便逐张展示和重试。
      for (var i = 0; i < tasks.length; i++) {
        if (tasks[i].state != .success) {
          tasks[i] = tasks[i]._with(
            state: .failed,
            error: _message(error),
          );
        }
      }
      report();
    } finally {
      // 只删除本批次创建的临时目录，不修改选择器返回的源文件。
      try {
        await directory?.delete(recursive: true);
      } catch (_) {
        debugPrint('OSS 临时图片清理失败');
      }
    }
    return MDOssResult(tasks);
  }

  /// 单文件上传，一次只上传一个文件，仅支持 [fileTypes] 中的扩展名。
  ///
  /// 文档不做任何转码，按原始扩展名和 MIME 直传；与图片共享全局上传并发门。
  /// [progress] 实时返回任务快照；上传过程不会抛出异常，失败查看返回值的 state/error。
  static Future<MDOssTask> uploadFile(
    String filePath, {
    ValueChanged<MDOssTask>? progress,
    CancelToken? cancelToken,
    int maxBytes = 50 * 1024 * 1024,
  }) async {
    if (maxBytes < 1 || maxBytes > 200 * 1024 * 1024) {
      throw ArgumentError.value(maxBytes, 'maxBytes', '必须在 1 到 200MB 之间');
    }
    var task = MDOssTask(index: 0, imagePath: filePath);
    void report() {
      if (progress == null) return;
      try {
        progress(task);
      } catch (_) {
        debugPrint('OSS 文件上传进度回调异常');
      }
    }

    report();
    try {
      final dot = filePath.lastIndexOf('.');
      final extension = dot < 0
          ? ''
          : filePath.substring(dot + 1).toLowerCase();
      final contentType = fileTypes[extension];
      if (contentType == null) {
        throw StateError('仅支持上传 ${fileTypes.keys.join('、')} 文件');
      }
      final bytes = await File(filePath).length();
      if (bytes < 1) throw StateError('文件内容为空');
      if (bytes > maxBytes) {
        throw StateError('文件不能超过 ${maxBytes ~/ (1024 * 1024)}MB');
      }
      task = task._with(totalBytes: bytes);
      final oss = await _client();
      await _uploadGate.run(() async {
        if (cancelToken?.isCancelled == true) throw cancelToken!.cancelError!;
        task = task._with(state: .uploading);
        report();
        final key = _objectKey(extension);
        await oss.client.putObjectFile(
          filePath,
          fileKey: key,
          cancelToken: cancelToken,
          option: aliyun.PutRequestOption(
            override: false,
            headers: {'content-type': contentType},
            onSendProgress: (sent, total) {
              if (total <= 0) return;
              final value = (sent / total).clamp(0.0, 0.99);
              task = task._with(
                progress: max(task.progress, value),
                sentBytes: sent.clamp(0, total),
                totalBytes: total,
              );
              report();
            },
          ),
        );
        task = task._with(
          state: .success,
          progress: 1,
          sentBytes: task.totalBytes,
          url: 'https://${oss.host}/$key',
        );
      });
    } catch (error) {
      task = task._with(
        state: .failed,
        error: _message(error, '文件'),
      );
    }
    report();
    return task;
  }

  /// 按当前 STS 配置创建客户端；凭证过期时自动续期，配置变更则中止本批。
  static Future<_OssClient> _client() async {
    var config = await _loadConfig();
    final endpoint = config.endpoint;
    final bucket = config.bucket;
    final client = aliyun.Client.init(
      ossEndpoint: endpoint,
      bucketName: bucket,
      dio: _session,
      authGetter: () async {
        if (!config.isUsable) config = await _loadConfig();
        if (config.endpoint != endpoint || config.bucket != bucket) {
          throw StateError('OSS 配置已变更，请重新上传');
        }
        return config.auth;
      },
    );
    return (client: client, host: '$bucket.$endpoint');
  }

  static String _objectKey([String extension = 'jpg']) {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final nonce = List.generate(
      16,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return '$date/${now.microsecondsSinceEpoch}_$nonce.$extension';
  }

  /// 合并并发 STS 请求；失败后清除 Future，下一批可以重新获取。
  static Future<_OssConfig> _loadConfig() async {
    final pending = _loadingConfig;
    if (pending != null) return pending;
    final future = _fetchConfig();
    _loadingConfig = future;
    try {
      return await future;
    } finally {
      if (identical(_loadingConfig, future)) _loadingConfig = null;
    }
  }

  static Future<_OssConfig> _fetchConfig() async {
    final result = await MDPost.sendApiSession(cmd: .oss);
    if (!result.isSuccess) throw StateError(result.msg ?? '加载 OSS 上传配置失败');
    final info = result.data?['info'];
    if (info is! Map) throw StateError('OSS 上传配置缺失');
    return _OssConfig.fromMap(info);
  }

  static String _message(Object error, [String name = '图片']) {
    if (error is StateError) return error.message;
    if (error is PlatformException) return error.message ?? '图片压缩失败';
    if (error is MissingPluginException) return '当前平台未接入图片压缩，请完整重启应用';
    if (error is FileSystemException) return '$name不可读或临时目录不可写';
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return '$name上传超时，请稍后重试';
        default:
          return error.response?.statusCode == 403
              ? 'OSS 上传权限失效，请重新上传'
              : '$name上传失败，请检查网络';
      }
    }
    return '$name上传失败';
  }
}

class _OssConfig {
  const _OssConfig(this.endpoint, this.bucket, this.auth);

  final String endpoint;
  final String bucket;
  final aliyun.Auth auth;
  bool get isUsable => !auth.isExpired;

  factory _OssConfig.fromMap(Map info) {
    String field(String key, [String? alias]) {
      final value = (info[key] ?? info[alias])?.toString().trim();
      if (value == null || value.isEmpty) throw StateError('OSS 上传配置字段缺失：$key');
      return value;
    }

    final endpoint = field('endpoint');
    final uri = Uri.tryParse(
      endpoint.contains('://') ? endpoint : 'https://$endpoint',
    );
    final bucket = field('bucket');
    if (uri == null ||
        uri.host.isEmpty ||
        uri.hasPort ||
        uri.userInfo.isNotEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        !RegExp(r'^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$').hasMatch(bucket)) {
      throw StateError('OSS endpoint 或 bucket 格式错误');
    }
    final expiration = DateTime.tryParse(field('Expiration', 'exporation'));
    // 提前一分钟刷新，避免上传开始时使用即将过期的 STS。
    if (expiration == null ||
        !expiration.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      throw StateError('OSS 上传凭证已过期或即将过期');
    }
    return _OssConfig(
      uri.host,
      bucket,
      aliyun.Auth(
        accessKey: field('AccessKeyId', 'keyId'),
        accessSecret: field('AccessKeySecret', 'keyScrect'),
        secureToken: field('SecurityToken', 'token'),
        expire: expiration
            .subtract(const Duration(minutes: 1))
            .toUtc()
            .toIso8601String(),
      ),
    );
  }
}

/// FIFO 并发门，跨批次共享，异常时也释放名额。
class _OssGate {
  _OssGate(this._available);
  int _available;
  final _waiters = <Completer<void>>[];

  Future<T> run<T>(Future<T> Function() action) async {
    if (_available > 0) {
      _available--;
    } else {
      final waiter = Completer<void>();
      _waiters.add(waiter);
      await waiter.future;
    }
    try {
      return await action();
    } finally {
      if (_waiters.isEmpty) {
        _available++;
      } else {
        _waiters.removeAt(0).complete();
      }
    }
  }
}
