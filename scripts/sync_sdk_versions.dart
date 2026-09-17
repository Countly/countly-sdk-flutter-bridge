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

  // ---- iOS: native SDK dependency ----
  // The native iOS SDK is a SwiftPM dependency, so its version lives in
  // Package.swift rather than in a checked-out tree.
  final iosTag = args.isNotEmpty ? args[0] : iosVersion;
  final packageSwift = '$rootDir/ios/countly_flutter/Package.swift';
  final pinnedByBranch = File(packageSwift).existsSync() &&
      RegExp(r'countly-sdk-swift\.git",\s*branch:').hasMatch(File(packageSwift).readAsStringSync());

  print('');
  if (pinnedByBranch) {
    // Fail rather than print: a releaser who sees a success banner will ship
    // believing the version was written, and nothing else records it.
    stderr.writeln('❌ ios/countly_flutter/Package.swift pins countly-sdk-swift by branch, not by version.');
    stderr.writeln('   The iOS SDK version cannot be synced while that is true, so this would');
    stderr.writeln('   report $iosTag while the build resolves whatever the branch HEAD is.');
    stderr.writeln('   Move Package.swift to a version requirement, then re-run.');
    exit(1);
  }

  // ---- Flutter version files ----
  replaceInFile(
    '$rootDir/pubspec.yaml',
    RegExp(r'^version: .+', multiLine: true),
    'version: $flutterVersion',
    'Flutter → pubspec.yaml',
  );

  replaceInFile(
    '$rootDir/android/src/main/java/ly/count/dart/countly_flutter/CountlyFlutterPlugin.java',
    RegExp(r'COUNTLY_FLUTTER_SDK_VERSION_STRING = ".+"'),
    'COUNTLY_FLUTTER_SDK_VERSION_STRING = "$flutterVersion"',
    'Flutter → CountlyFlutterPlugin.java',
  );

  replaceInFile(
    '$rootDir/ios/countly_flutter/Sources/countly_flutter/CountlyFlutterPlugin.swift',
    RegExp(r'kCountlyFlutterSDKVersion = ".+"'),
    'kCountlyFlutterSDKVersion = "$flutterVersion"',
    'Flutter → ios/countly_flutter/Sources/countly_flutter/CountlyFlutterPlugin.swift',
  );

  replaceInFile(
    '$rootDir/lib/src/web/plugin_config.dart',
    RegExp(r"static const String SDK_VERSION_STRING = '.+'"),
    "static const String SDK_VERSION_STRING = '$flutterVersion'",
    'Flutter → plugin_config.dart',
  );

  replaceInFile(
    '$rootDir/example/integration_test/utils.dart',
    RegExp(r"expect\(requestObject\['sdk_version'\]\?\[0\], '.+'\);"),
    "expect(requestObject['sdk_version']?[0], '$flutterVersion');",
    'Flutter → example/integration_test/utils.dart',
  );

  replaceInFile(
    '$scriptDir/no-push-files/pubspec.yaml',
    RegExp(r'^version: .+', multiLine: true),
    'version: $flutterVersion',
    'Flutter → no-push-files/pubspec.yaml',
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

  replaceInFile(
    packageSwift,
    RegExp(r'countly-sdk-swift\.git", from: "[^"]+"'),
    'countly-sdk-swift.git", from: "$iosTag"',
    'iOS      → Package.swift',
  );
  print('');

  // ---- Stage all modified files ----
  print('');
  print('📋 Staging changed files...');
  run(
      'git',
      [
        'add',
        'scripts/config/sdk_versions.txt',
        'pubspec.yaml',
        'android/src/main/java/ly/count/dart/countly_flutter/CountlyFlutterPlugin.java',
        'ios/countly_flutter/Sources/countly_flutter/CountlyFlutterPlugin.swift',
        'lib/src/web/plugin_config.dart',
        'scripts/no-push-files/pubspec.yaml',
        'android/build.gradle',
        'scripts/no-push-files/build.gradle',
        'ios/countly_flutter/Package.swift',
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
