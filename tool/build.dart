// 构建 / 打包脚本：以 flavorizr.yaml 为唯一配置源，同步生成各平台配置 → 构建号 +1 → 按渠道构建。
//
// 用法（项目根目录执行）：
//   dart run tool/build.dart                          列出所有渠道，终端手动选择后打包
//   dart run tool/build.dart run <渠道> [flutter 参数]  本地调试运行，版本号取该渠道
//   dart run tool/build.dart sync                     仅同步配置，不改构建号
//   dart run tool/build.dart android [渠道...]        Android 打包，不传渠道则打全部渠道
//   dart run tool/build.dart ios                      iOS（AppStore）打包 ipa
//   dart run tool/build.dart all                      Android 全渠道 + iOS
//
// 调试： dart run tool/build.dart run appstore -d 00008101-001524812260001E（设备id）
// 版本号全部取自 flavorizr.yaml：渠道配置了 version 就用它，否则 Android 取 common.androidVersion、
// iOS 取 common.iosVersion；构建号统一取 common.buildNumber。
// 以 `-` 开头的参数原样透传给 flutter，如 `-d emulator-5554`、`--obfuscate --split-debug-info=build/symbols`。
// `-d` 支持写模糊关键字：flutter 本身只认设备 id 或完整名称，脚本会在唯一匹配时替换成真实 id（如 `-d iPhone`）。
// 每次打包构建号只 +1 一次，本次所有渠道共用；打包失败不回滚，避免已产出的包与下次撞号。
import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

const _flavorizrPath = 'flavorizr.yaml';
const _pubspecPath = 'pubspec.yaml';
const _iosAppInfoPath = 'ios/Flutter/AppInfo.xcconfig';
const _flavorsDartPath = 'lib/flavors.dart';
const _generatedHeader = '由 tool/build.dart 根据 flavorizr.yaml 生成，勿手改';

Future<void> main(List<String> args) async {
  final command = args.isEmpty ? 'menu' : args.first;

  // 命令之后，遇到第一个 `-` 开头的参数前都是渠道名，之后都是 flutter 参数
  // 例：`run appstore -d iPhone` → names=['appstore'], flutterArgs=['-d', 'iPhone']
  //     `android xiaomi huawei --obfuscate` → names=['xiaomi','huawei'], flutterArgs=['--obfuscate']
  var flagStart = args.length;
  for (var i = 1; i < args.length; i++) {
    if (args[i].startsWith('-')) {
      flagStart = i;
      break;
    }
  }
  // 不带参数（交互选渠道）时 args 为空，sublist(1, ...) 会越界
  final names = args.isEmpty ? const <String>[] : args.sublist(1, flagStart);
  final flutterArgs = args.isEmpty ? const <String>[] : args.sublist(flagStart);
  var config = _FlavorConfig.load();

  final List<String> selected;
  switch (command) {
    case 'sync':
      await _sync(config);
      return;
    case 'run':
      await _runDebug(config, names, flutterArgs);
      return;
    case 'menu':
      selected = _promptChannels(config);
    case 'android':
      final available = config.androidChannels.map((channel) => channel.name);
      final unknown = names.where((name) => !available.contains(name));
      if (unknown.isNotEmpty) {
        stderr.writeln('未知渠道：${unknown.join(', ')}');
        stderr.writeln('可选渠道：${available.join(', ')}');
        exit(64);
      }
      selected = names.isEmpty ? available.toList() : names;
    case 'ios':
      selected = [config.iosChannel.name];
    case 'all':
      selected = config.channelNames;
    default:
      _exitWithUsage();
  }

  _bumpBuildNumber();
  config = _FlavorConfig.load();
  await _sync(config);

  final built = config.channels
      .where((channel) => selected.contains(channel.name))
      .toList();
  for (final channel in built) {
    final versionArgs = [
      '--build-name',
      config.versionOf(channel),
      '--build-number',
      '${config.buildNumber}',
    ];
    if (config.isIos(channel)) {
      await _run('flutter', ['build', 'ipa', ...versionArgs, ...flutterArgs]);
    } else {
      await _run('flutter', [
        'build',
        'apk',
        '--flavor',
        channel.name,
        ...versionArgs,
        ...flutterArgs,
      ]);
    }
  }

  stdout.writeln('打包完成：');
  for (final channel in built) {
    stdout.writeln(_channelLine(config, channel, config.buildNumber));
  }
  if (built.any((channel) => !config.isIos(channel))) {
    stdout.writeln('Android：build/app/outputs/flutter-apk/app-<渠道>-release.apk');
  }
  if (built.any(config.isIos)) {
    stdout.writeln('iOS：build/ios/ipa');
  }
}

/// 本地调试构建：flutter run 不支持 --build-name，所以把该渠道的版本号写进 pubspec 再启动
Future<void> _runDebug(
  _FlavorConfig config,
  List<String> names,
  List<String> flutterArgs,
) async {
  if (names.length != 1) {
    stderr.writeln('run 需指定一个渠道：dart run tool/build.dart run <渠道>');
    stderr.writeln('可选渠道：${config.channelNames.join(', ')}');
    exit(64);
  }

  final channel = config.channelByName(names.single);
  if (channel == null) {
    stderr.writeln('未知渠道：${names.single}');
    stderr.writeln('可选渠道：${config.channelNames.join(', ')}');
    exit(64);
  }

  // 先解析设备：设备写错时直接退出，避免改了 pubspec 才失败
  final runArgs = await _resolveDeviceArgs(flutterArgs);
  await _sync(config, pubspecVersion: config.versionOf(channel));
  stdout.writeln('调试构建 $_pubspecPath 版本：${config.versionOf(channel)}+${config.buildNumber}');
  if (config.isIos(channel)) {
    await _run('flutter', ['run', ...runArgs]);
  } else {
    await _run('flutter', ['run', '--flavor', channel.name, ...runArgs]);
  }
}

/// 把 -d / --device-id 后的模糊关键字替换成 flutter 能识别的设备 id
Future<List<String>> _resolveDeviceArgs(List<String> flutterArgs) async {
  final resolved = <String>[];
  var i = 0;
  while (i < flutterArgs.length) {
    final arg = flutterArgs[i];
    if (arg.startsWith('--device-id=')) {
      final keyword = arg.substring('--device-id='.length);
      resolved.add('--device-id=${await _resolveDevice(keyword)}');
      i++;
    } else if (arg == '-d' || arg == '--device-id') {
      if (i + 1 >= flutterArgs.length) {
        stderr.writeln('$arg 缺少设备关键字');
        exit(64);
      }
      resolved.add(arg);
      resolved.add(await _resolveDevice(flutterArgs[i + 1]));
      i += 2;
    } else {
      resolved.add(arg);
      i++;
    }
  }
  return resolved;
}

/// 设备 id / 名称完全一致时原样返回；否则按不区分大小写的子串匹配，唯一命中才算成功
Future<String> _resolveDevice(String keyword) async {
  final devices = await _listDevices();
  if (devices.any((device) => device.id == keyword || device.name == keyword)) {
    return keyword;
  }

  final lower = keyword.toLowerCase();
  final matched = devices
      .where(
        (device) =>
            device.id.toLowerCase().contains(lower) ||
            device.name.toLowerCase().contains(lower),
      )
      .toList();
  if (matched.length == 1) {
    final device = matched.single;
    stdout.writeln('设备 $keyword → ${device.name}（${device.id}）');
    return device.id;
  }

  if (matched.isEmpty) {
    stderr.writeln('未找到匹配“$keyword”的设备，当前可用设备：');
  } else {
    stderr.writeln('“$keyword”匹配到多个设备，请指定其中一个：');
  }
  for (final device in devices) {
    stderr.writeln('  ${device.id.padRight(30)}${device.name}');
  }
  exit(65);
}

/// 读 flutter devices --machine 的 JSON 输出，只保留可运行的设备
Future<List<_Device>> _listDevices() async {
  final result = await Process.run(
    'flutter',
    ['devices', '--machine'],
    runInShell: Platform.isWindows,
  );
  final output = result.stdout as String;
  final start = output.indexOf('[');
  final end = output.lastIndexOf(']');
  if (result.exitCode != 0 || start < 0 || end <= start) {
    stderr.writeln('获取设备列表失败（exit ${result.exitCode}）：$output${result.stderr}');
    exit(result.exitCode == 0 ? 65 : result.exitCode);
  }

  final list = jsonDecode(output.substring(start, end + 1)) as List<dynamic>;
  return [
    for (final item in list.cast<Map<String, dynamic>>())
      if (item['isSupported'] != false) _Device(item['id'] as String, item['name'] as String),
  ];
}

/// 列出全部渠道供终端手动选择，返回所选渠道名；输入 q 直接退出
List<String> _promptChannels(_FlavorConfig config) {
  if (!stdin.hasTerminal) {
    stderr.writeln('当前环境不支持交互选择，请显式指定渠道：');
    _exitWithUsage();
  }

  final channels = config.channels;
  final nextBuildNumber = config.buildNumber + 1;
  while (true) {
    // 开头换行：避开 dart run 自带的 "Running build hooks..." 末尾无换行输出
    stdout.writeln('\n${config.appName}  构建号 $nextBuildNumber（渠道 / 平台 / 版本号）');
    for (var i = 0; i < channels.length; i++) {
      final index = '${i + 1})'.padLeft(5);
      stdout.writeln('$index${_channelLine(config, channels[i], nextBuildNumber)}');
    }
    stdout.writeln('      a)  全部 Android 渠道');
    stdout.writeln('      b)  全部渠道（Android + iOS）');
    stdout.writeln('      q)  退出');
    stdout.write('请选择渠道（多选用空格或逗号分隔）：');

    final input = stdin.readLineSync()?.trim().toLowerCase() ?? 'q';
    if (input == 'q' || input.isEmpty) {
      stdout.writeln('已取消');
      exit(0);
    }

    final List<_Channel> picked;
    if (input == 'a') {
      picked = [...config.androidChannels];
    } else if (input == 'b') {
      picked = [...channels];
    } else {
      picked = <_Channel>[];
      for (final token in input.split(RegExp(r'[\s,，]+'))) {
        final index = int.tryParse(token);
        if (index == null || index < 1 || index > channels.length) {
          stderr.writeln('无效输入：$token\n');
          picked.clear();
          break;
        }
        final channel = channels[index - 1];
        if (!picked.contains(channel)) picked.add(channel);
      }
    }
    if (picked.isEmpty) continue;

    stdout.writeln('\n已选 ${picked.length} 个渠道：');
    for (final channel in picked) {
      stdout.writeln(_channelLine(config, channel, nextBuildNumber));
    }
    stdout.write('确认开始打包？(Y/n) ');
    final confirm = stdin.readLineSync()?.trim().toLowerCase() ?? 'n';
    if (confirm.isEmpty || confirm == 'y') {
      return picked.map((channel) => channel.name).toList();
    }
    stdout.writeln('');
  }
}

/// 渠道一行展示：渠道名、平台、版本号
String _channelLine(_FlavorConfig config, _Channel channel, int buildNumber) {
  final platform = config.isIos(channel) ? 'iOS' : 'Android';
  return '  ${channel.name.padRight(20)}${platform.padRight(11)}'
      '${config.versionOf(channel)}+$buildNumber';
}

/// 由 flavorizr.yaml 生成 Android flavor、iOS xcconfig、Dart 渠道枚举，并同步 pubspec 版本号
Future<void> _sync(_FlavorConfig config, {String? pubspecVersion}) async {
  await _run('dart', ['run', 'flutter_flavorizr', '-f']);

  _writeIfChanged(_iosAppInfoPath, '''
// $_generatedHeader
APP_DISPLAY_NAME = ${config.appName}
PRODUCT_BUNDLE_IDENTIFIER = ${config.iosBundleId}
''');

  _writeIfChanged(_flavorsDartPath, '''
// $_generatedHeader
enum Flavor {
${config.channelNames.map((name) => '  $name,').join('\n')}
}
''');

  final pubspec = File(_pubspecPath).readAsStringSync();
  final versionLine = RegExp(r'^version:.*$', multiLine: true);
  if (!versionLine.hasMatch(pubspec)) {
    stderr.writeln('$_pubspecPath 缺少 version 配置行');
    exit(65);
  }
  final version = pubspecVersion ?? config.defaultVersion;
  _writeIfChanged(
    _pubspecPath,
    pubspec.replaceFirst(versionLine, 'version: $version+${config.buildNumber}'),
  );

  stdout.writeln('配置已同步：${config.appName}  构建号 ${config.buildNumber}');
  final byVersion = <String, List<String>>{};
  for (final channel in config.channels) {
    byVersion.putIfAbsent(config.versionOf(channel), () => []).add(channel.name);
  }
  for (final entry in byVersion.entries) {
    stdout.writeln('  ${entry.key}  ${entry.value.join(', ')}');
  }
  stdout.writeln('  $_pubspecPath 默认 $version+${config.buildNumber}（未指定渠道时）');
}

/// flavorizr.yaml 中 common.buildNumber 自增 1（按文本替换，保留注释与格式）
void _bumpBuildNumber() {
  final file = File(_flavorizrPath);
  final content = file.readAsStringSync();
  final pattern = RegExp(r'^([ \t]+buildNumber:[ \t]*)(\d+)', multiLine: true);
  final matches = pattern.allMatches(content).toList();
  if (matches.length != 1) {
    stderr.writeln('$_flavorizrPath 中需有且仅有一行 common.buildNumber');
    exit(65);
  }
  final match = matches.single;
  file.writeAsStringSync(
    content.replaceRange(match.start, match.end, '${match[1]}${int.parse(match[2]!) + 1}'),
  );
}

void _writeIfChanged(String path, String content) {
  final file = File(path);
  if (file.existsSync() && file.readAsStringSync() == content) return;
  file.writeAsStringSync(content);
}

Future<void> _run(String executable, List<String> arguments) async {
  stdout.writeln('\$ $executable ${arguments.join(' ')}');
  final process = await Process.start(
    executable,
    arguments,
    mode: ProcessStartMode.inheritStdio,
    runInShell: Platform.isWindows,
  );
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    stderr.writeln('命令执行失败（exit $exitCode）：$executable ${arguments.join(' ')}');
    exit(exitCode);
  }
}

Never _exitWithUsage() {
  stderr.writeln(
    '用法：dart run tool/build.dart <不带参数进入交互选择|sync|run <渠道>|android [渠道...]|ios|all>'
    ' [flutter 参数]',
  );
  exit(64);
}

Never _exitWithConfigError(String message) {
  stderr.writeln('$_flavorizrPath 配置错误：$message');
  exit(65);
}

class _Device {
  final String id;
  final String name;

  const _Device(this.id, this.name);
}

class _Channel {
  final String name;

  /// 渠道单独版本号，为空表示取平台默认版本号
  final String? versionOverride;

  const _Channel(this.name, this.versionOverride);
}

class _FlavorConfig {
  final String appName;
  final String iosBundleId;

  /// Android 渠道默认版本号（common.androidVersion）
  final String androidVersion;

  /// iOS 渠道默认版本号（common.iosVersion）
  final String iosVersion;
  final int buildNumber;
  final List<_Channel> channels;
  final List<_Channel> androidChannels;
  final _Channel iosChannel;

  const _FlavorConfig({
    required this.appName,
    required this.iosBundleId,
    required this.androidVersion,
    required this.iosVersion,
    required this.buildNumber,
    required this.channels,
    required this.androidChannels,
    required this.iosChannel,
  });

  List<String> get channelNames => channels.map((channel) => channel.name).toList();

  /// 未指定渠道时同步到 pubspec 的版本号（Android 为主开发平台，取 androidVersion）
  String get defaultVersion => androidVersion;

  bool isIos(_Channel channel) => channel == iosChannel;

  /// 渠道版本号：渠道配置了 version 用它，否则按平台取默认值
  String versionOf(_Channel channel) =>
      channel.versionOverride ?? (isIos(channel) ? iosVersion : androidVersion);

  _Channel? channelByName(String name) {
    for (final channel in channels) {
      if (channel.name == name) return channel;
    }
    return null;
  }

  factory _FlavorConfig.load() {
    final yaml = loadYaml(File(_flavorizrPath).readAsStringSync()) as YamlMap;
    final common = yaml['common'];
    final flavors = yaml['flavors'];
    if (common is! YamlMap || flavors is! YamlMap) {
      _exitWithConfigError('缺少 common 或 flavors 节');
    }
    if (common.containsKey('version')) {
      _exitWithConfigError('common.version 已拆分，请改用 common.androidVersion 与 common.iosVersion');
    }

    final androidVersion = _parseVersion(common['androidVersion'], 'common.androidVersion');
    final iosVersion = _parseVersion(common['iosVersion'], 'common.iosVersion');
    final buildNumber = common['buildNumber'];
    if (buildNumber is! int || buildNumber < 1) {
      _exitWithConfigError('common.buildNumber 需为正整数');
    }

    final channels = <_Channel>[];
    final androidChannels = <_Channel>[];
    final iosChannels = <_Channel>[];
    String? appName;
    String? iosBundleId;
    for (final entry in flavors.entries) {
      final name = entry.key as String;
      final flavor = entry.value as YamlMap;
      if (!RegExp(r'^[a-z][a-z0-9]*$').hasMatch(name)) {
        _exitWithConfigError('渠道名 $name 只能由小写字母和数字组成');
      }
      // version 写在 android / ios 节里不生效（flavorizr 也会静默忽略），直接报错避免打错版本号
      for (final section in ['android', 'ios']) {
        if ((flavor[section] as YamlMap?)?.containsKey('version') ?? false) {
          _exitWithConfigError(
            '$name.$section.version 不生效：渠道单独版本号请写在渠道下（与 $section 同级），'
            '平台默认版本号请改 common.androidVersion / common.iosVersion',
          );
        }
      }
      final channel = _Channel(
        name,
        flavor['version'] == null ? null : _parseVersion(flavor['version'], '$name.version'),
      );
      channels.add(channel);
      if (flavor['android'] != null) androidChannels.add(channel);
      if (flavor['ios'] != null) {
        iosChannels.add(channel);
        appName = flavor['app']['name'] as String;
        iosBundleId = flavor['ios']['bundleId'] as String;
      }
    }
    if (iosChannels.length != 1) {
      _exitWithConfigError('iOS 渠道需有且仅有一个（appstore）');
    }

    return _FlavorConfig(
      appName: appName!,
      iosBundleId: iosBundleId!,
      androidVersion: androidVersion,
      iosVersion: iosVersion,
      buildNumber: buildNumber,
      channels: channels,
      androidChannels: androidChannels,
      iosChannel: iosChannels.single,
    );
  }

  static String _parseVersion(Object? value, String key) {
    final version = value?.toString() ?? '';
    if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version)) {
      _exitWithConfigError('$key 需为 x.y.z 格式，当前为 "$version"');
    }
    return version;
  }
}
