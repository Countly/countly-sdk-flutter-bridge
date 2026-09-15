import 'dart:io';

void main(List<String> args) {
  final scriptDir = File(Platform.script.toFilePath()).parent.path;
  final rootDir = Directory('$scriptDir/..').resolveSymbolicLinksSync();
  final configFile = File('$scriptDir/config/sdk_versions.txt');

  if (!configFile.existsSync()) {
    stderr.writeln('❌ Config file not found: ${configFile.path}');
    exit(1);
  }

  // Parse versions
  final config = <String, String>{};
  for (final line in configFile.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || !trimmed.contains('=')) continue;
    final parts = trimmed.split('=');
    config[parts[0]] = parts[1];
  }

  final flutterVersion = config['flutter_sdk_version'];
  final androidVersion = config['android_sdk_version'];
  final iosVersion = config['ios_sdk_version'];
  final webVersion = config['web_sdk_version'];

  if (flutterVersion == null || flutterVersion.isEmpty) {
    stderr.writeln('❌ flutter_sdk_version not found');
    exit(1);
  }
  if (androidVersion == null || androidVersion.isEmpty) {
    stderr.writeln('❌ android_sdk_version not found');
    exit(1);
  }
  if (iosVersion == null || iosVersion.isEmpty) {
    stderr.writeln('❌ ios_sdk_version not found');
    exit(1);
  }
  if (webVersion == null || webVersion.isEmpty) {
    stderr.writeln('❌ web_sdk_version not found');
    exit(1);
  }

  print('📦 Syncing SDK versions');
  print('   Flutter: $flutterVersion');
  print('   Android: $androidVersion');
  print('   iOS:     $iosVersion');
  print('   Web:     $webVersion');
  print('');

  // ---- Flutter version files ----
  replaceInFile(
    '$rootDir/pubspec.yaml',
    RegExp(r'^version: .+', multiLine: true),
    'version: $flutterVersion',
    'Flutter → pubspec.yaml',
  );

  replaceInFile(
    '$rootDir/ios/countly_flutter.podspec',
    RegExp(r"s\.version = '.+'"),
    "s.version = '$flutterVersion'",
    'Flutter → ios/countly_flutter.podspec',
  );

  replaceInFile(
    '$rootDir/android/src/main/java/ly/count/dart/countly_flutter/CountlyFlutterPlugin.java',
    RegExp(r'COUNTLY_FLUTTER_SDK_VERSION_STRING = ".+"'),
    'COUNTLY_FLUTTER_SDK_VERSION_STRING = "$flutterVersion"',
    'Flutter → CountlyFlutterPlugin.java',
  );

  replaceInFile(
    '$rootDir/ios/countly_flutter/Sources/countly_flutter/CountlyFlutterPlugin.m',
    RegExp(r'kCountlyFlutterSDKVersion = @".+"'),
    'kCountlyFlutterSDKVersion = @"$flutterVersion"',
    'Flutter → ios/countly_flutter/Sources/countly_flutter/CountlyFlutterPlugin.m',
  );

  replaceInFile(
    '$rootDir/lib/src/web/plugin_config.dart',
    RegExp(r"static const String SDK_VERSION_STRING = '.+'"),
    "static const String SDK_VERSION_STRING = '$flutterVersion'",
    'Flutter → plugin_config.dart',
  );

  replaceInFile(
    '$scriptDir/no-push-files/pubspec.yaml',
    RegExp(r'^version: .+', multiLine: true),
    'version: $flutterVersion',
    'Flutter → no-push-files/pubspec.yaml',
  );

  replaceInFile(
    '$scriptDir/no-push-files/countly_flutter_np.podspec',
    RegExp(r"s\.version = '.+'"),
    "s.version = '$flutterVersion'",
    'Flutter → no-push-files/countly_flutter_np.podspec',
  );

  // ---- Web version ----
  replaceInFile(
    '$rootDir/lib/src/web/plugin_config.dart',
    RegExp(r"static const String WEB_SDK_VERSION = '.+'"),
    "static const String WEB_SDK_VERSION = '$webVersion'",
    'Web     → plugin_config.dart',
  );

  // ---- Android version ----
  replaceInFile(
    '$rootDir/android/build.gradle',
    RegExp(r"implementation 'ly\.count\.android:sdk:.+'"),
    "implementation 'ly.count.android:sdk:$androidVersion'",
    'Android → android/build.gradle',
  );

  replaceInFile(
    '$scriptDir/no-push-files/build.gradle',
    RegExp(r"implementation 'ly\.count\.android:sdk:.+'"),
    "implementation 'ly.count.android:sdk:$androidVersion'",
    'Android → no-push-files/build.gradle',
  );

  // ---- iOS: submodule init & sparse checkout ----
  final iosTag = args.isNotEmpty ? args[0] : iosVersion;
  final submodulePath = 'ios/countly_flutter/Sources/countly_flutter/countly-sdk-ios';
  final sparseFile = '$scriptDir/config/sparse-checkout.list';

  print('');
  print('🔧 Initializing iOS SDK submodule...');
  print('   Tag: $iosTag');
  print('   Path: $submodulePath');
  print('');

  run('git', ['submodule', 'update', '--init', '--recursive', submodulePath], rootDir);

  run('git', ['fetch', '--all', '--tags'], '$rootDir/$submodulePath');

  final checkoutResult = Process.runSync('git', ['checkout', iosTag], workingDirectory: '$rootDir/$submodulePath');
  if (checkoutResult.exitCode != 0) {
    stderr.writeln('❌ Tag not found: $iosTag');
    stderr.writeln(checkoutResult.stderr);
    exit(1);
  }
  print('📥 Checked out tag $iosTag');

  if (!File(sparseFile).existsSync()) {
    stderr.writeln('❌ Missing sparse-checkout rules at: $sparseFile');
    exit(1);
  }

  run('git', ['sparse-checkout', 'init', '--no-cone'], '$rootDir/$submodulePath');

  final gitPathResult = Process.runSync('git', ['rev-parse', '--git-path', 'info/sparse-checkout'], workingDirectory: '$rootDir/$submodulePath');
  final sparseTarget = gitPathResult.stdout.toString().trim();
  // git rev-parse may return a relative or absolute path
  final sparseTargetPath = sparseTarget.startsWith('/') ? sparseTarget : '$rootDir/$submodulePath/$sparseTarget';
  File(sparseFile).copySync(sparseTargetPath);

  run('git', ['read-tree', '-mu', 'HEAD'], '$rootDir/$submodulePath');

  print('✅ iOS     → submodule checked out at $iosTag');

  // ---- Stage all modified files ----
  print('');
  print('📋 Staging changed files...');
  run(
      'git',
      [
        'add',
        'scripts/config/sdk_versions.txt',
        'pubspec.yaml',
        'ios/countly_flutter.podspec',
        'android/src/main/java/ly/count/dart/countly_flutter/CountlyFlutterPlugin.java',
        'ios/countly_flutter/Sources/countly_flutter/CountlyFlutterPlugin.m',
        'lib/src/web/plugin_config.dart',
        'scripts/no-push-files/pubspec.yaml',
        'scripts/no-push-files/countly_flutter_np.podspec',
        'android/build.gradle',
        'scripts/no-push-files/build.gradle',
        'ios/countly_flutter/Sources/countly_flutter/countly-sdk-ios',
      ],
      rootDir);
  print('✅ All changed files staged');

  // ---- Flutter clean & pub get ----
  print('');
  print('🧹 Running flutter clean...');
  run('flutter', ['clean'], rootDir);

  print('');
  print('📦 Running flutter pub get...');
  run('flutter', ['pub', 'get'], rootDir);

  print('');
  print('✅ All SDK versions synced, staged, and project refreshed');
}

void replaceInFile(String path, RegExp pattern, String replacement, String label) {
  final file = File(path);
  if (!file.existsSync()) {
    print('⏭️  Skipped $label (file not found)');
    return;
  }
  final content = file.readAsStringSync();
  final updated = content.replaceAll(pattern, replacement);
  if (content != updated) {
    file.writeAsStringSync(updated);
    print('✅ $label');
  } else {
    print('✅ $label (already up to date)');
  }
}

void run(String command, List<String> args, String workingDir) {
  final result = Process.runSync(command, args, workingDirectory: workingDir);
  if (result.exitCode != 0) {
    stderr.writeln('❌ Failed: $command ${args.join(' ')}');
    stderr.writeln(result.stderr);
    exit(1);
  }
}
