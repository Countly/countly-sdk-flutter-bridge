#!/usr/bin/env dart
// @dart=3.0

/// Integration Test Runner for Countly Flutter SDK
///
/// Cross-platform Dart version — works on both macOS and Windows.
///
/// Auto-discovers connected Android emulators, iOS simulators, and physical
/// devices, categorizes test files by scanning their content, distributes
/// tests across available devices in parallel, caches results, and saves logs.
///
/// Usage:
///   dart run scripts/run_integration_tests.dart [OPTIONS]
///
/// Categories:
///   --auto              Run all unattended tests distributed across devices (default)
///   --manual            Run only manual tests (need fg/bg switching, single device)
///   --server            Run only local-server tests (SBS, BM, networking)
///   --rc                Run only remote config tests
///   --light             Run only lightweight tests
///   --all               Run everything (manual tests run last, single device)
///
/// Display:
///   --list              List discovered devices and categorized tests
///   --dry-run           Show distribution plan without running
///   -v, --verbose       Stream full test output live (not just pass/fail)
///
/// Caching:
///   --fresh             Ignore cache, re-run all tests (even previously passed ones)
///   --clear-cache       Delete the cache file and exit
///
/// Devices:
///   -d, --device ID     Restrict to specific device(s), comma-separated
///   --timeout SECS      Per-test timeout in seconds (default: 300)
///
/// Filtering:
///   --filter PATTERN    Only run tests whose path matches PATTERN (regex)
///
/// Output:
///   Logs saved to test_results/<timestamp>/ in the project root:
///     worker_N.log           Full output per device
///     tests/<test_name>.log  Individual test output
///
/// Examples:
///   dart run scripts/run_integration_tests.dart                    # auto-discover, use cache
///   dart run scripts/run_integration_tests.dart --fresh            # ignore cache, run all
///   dart run scripts/run_integration_tests.dart --list             # see devices + test categories
///   dart run scripts/run_integration_tests.dart --light --server   # specific categories
///   dart run scripts/run_integration_tests.dart -d emulator-5554,IPHONE_UUID
///   dart run scripts/run_integration_tests.dart --dry-run          # preview distribution
///   dart run scripts/run_integration_tests.dart -v                 # verbose live output

import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ── ANSI Colors (bold) ─────────────────────────────────────────────
class C {
  static const red = '\x1B[1;31m';
  static const green = '\x1B[1;32m';
  static const yellow = '\x1B[1;33m';
  static const cyan = '\x1B[1;36m';
  static const white = '\x1B[1;37m';
  static const dim = '\x1B[2m';
  static const nc = '\x1B[0m';
}

// ── Configuration ──────────────────────────────────────────────────
class Config {
  String timeout = '300s';
  bool runManual = false;
  bool runServer = false;
  bool runRc = false;
  bool runLight = false;
  bool runAuto = false;
  bool listOnly = false;
  bool dryRun = false;
  bool verbose = false;
  bool fresh = false;
  bool clearCache = false;
  String restrictDevices = '';
  String filter = '';
}

// ── Device ─────────────────────────────────────────────────────────
class Device {
  final String platform; // 'android' or 'ios'
  final String id;

  Device(this.platform, this.id);

  @override
  String toString() => '$platform:$id';
}

// ── Worker Result ──────────────────────────────────────────────────
class WorkerResult {
  final int workerId;
  final Device device;
  int passed = 0;
  int failed = 0;
  int time = 0;
  List<String> failedTests = [];

  WorkerResult({required this.workerId, required this.device});
}

// ── Paths ──────────────────────────────────────────────────────────
late final String scriptDir;
late final String projectRoot;
late final String exampleDir;
late final String testDir;
late final String resultsBase;

void initPaths() {
  scriptDir = File(Platform.script.toFilePath()).parent.path;
  projectRoot = Directory(scriptDir).parent.path;
  exampleDir = '$projectRoot${Platform.pathSeparator}example';
  testDir = '$exampleDir${Platform.pathSeparator}integration_test';
  resultsBase = '$projectRoot${Platform.pathSeparator}test_results';
}

// ── Utility ────────────────────────────────────────────────────────

/// Cross-platform SHA-256 hash of concatenated file contents.
Future<String> computeSha256(List<String> filePaths) async {
  final tempPath = '${Directory.systemTemp.path}${Platform.pathSeparator}.countly_hash_${pid}';
  final tempFile = File(tempPath);
  final sink = tempFile.openWrite();
  for (final path in filePaths) {
    final f = File(path);
    if (await f.exists()) {
      await sink.addStream(f.openRead());
    }
  }
  await sink.close();

  ProcessResult result;
  if (Platform.isWindows) {
    result = await Process.run('powershell', [
      '-NoProfile',
      '-Command',
      "(Get-FileHash -Path '${tempFile.path}' -Algorithm SHA256).Hash",
    ]);
  } else {
    result = await Process.run('shasum', ['-a', '256', tempFile.path]);
  }

  await tempFile.delete().catchError((_) => tempFile);

  if (Platform.isWindows) {
    return result.stdout.toString().trim().toLowerCase();
  } else {
    return result.stdout.toString().split(' ').first.trim();
  }
}

/// Check if a command exists on the system.
Future<bool> commandExists(String command) async {
  try {
    final cmd = Platform.isWindows ? 'where' : 'which';
    final r = await Process.run(cmd, [command]);
    return r.exitCode == 0;
  } catch (_) {
    return false;
  }
}

/// Count non-empty lines in a list.
int countTests(List<String> tests) => tests.where((t) => t.isNotEmpty).length;

/// Format seconds to a human-readable duration string.
String formatDuration(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m}m ${s}s';
}

// ── Device Discovery ───────────────────────────────────────────────

Future<List<Device>> discoverDevices() async {
  final devices = <Device>[];

  // ── Android: emulators and physical devices via adb ──
  if (await commandExists('adb')) {
    try {
      final result = await Process.run('adb', ['devices']);
      final lines = result.stdout.toString().split('\n');
      for (final line in lines.skip(1)) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length >= 2 && parts[1] == 'device') {
          devices.add(Device('android', parts[0]));
        }
      }
    } catch (_) {}
  }

  // ── iOS: booted simulators via simctl (macOS only) ──
  if (!Platform.isWindows && await commandExists('xcrun')) {
    try {
      final result = await Process.run('xcrun', ['simctl', 'list', 'devices', 'booted']);
      final uuidPattern = RegExp(r'[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}', caseSensitive: false);
      // simctl lists every runtime; only iOS sections hold devices the tests can run on.
      var inIosSection = false;
      for (final line in result.stdout.toString().split('\n')) {
        if (line.startsWith('-- ')) inIosSection = line.startsWith('-- iOS ');
        if (inIosSection && line.toLowerCase().contains('booted')) {
          final match = uuidPattern.firstMatch(line);
          if (match != null) {
            devices.add(Device('ios', match.group(0)!));
          }
        }
      }
    } catch (_) {}
  }

  // ── iOS: connected physical devices (macOS only) ──
  if (!Platform.isWindows && await commandExists('idevice_id')) {
    try {
      final result = await Process.run('idevice_id', ['-l']);
      for (final udid in result.stdout.toString().split('\n')) {
        final trimmed = udid.trim();
        if (trimmed.isNotEmpty && !devices.any((d) => d.id.contains(trimmed))) {
          devices.add(Device('ios', trimmed));
        }
      }
    } catch (_) {}
  }

  return devices;
}

Future<String> getDeviceLabel(Device device) async {
  if (device.platform == 'android') {
    try {
      final result = await Process.run('adb', ['-s', device.id, 'shell', 'getprop', 'ro.product.model']);
      final model = result.stdout.toString().trim();
      if (model.isNotEmpty) return '[Android] $model (${device.id})';
    } catch (_) {}
    return '[Android] ${device.id}';
  } else {
    if (!Platform.isWindows) {
      try {
        final result = await Process.run('xcrun', ['simctl', 'list', 'devices']);
        for (final line in result.stdout.toString().split('\n')) {
          if (line.contains(device.id)) {
            final name = line.split('(').first.trim();
            if (name.isNotEmpty) return '[iOS] $name (${device.id})';
          }
        }
      } catch (_) {}
    }
    return '[iOS] ${device.id}';
  }
}

// ── Test Discovery ─────────────────────────────────────────────────

final _manualPattern = RegExp(r'FlutterForegroundTask\.(minimizeApp|launchApp)|goBackgroundAndForeground\(\)|goForeground\(\)|goBackground\(\)');
final _serverPattern = RegExp(r'createServer\(');
final _rcPattern = RegExp(r'SERVER_URL_RC|APP_KEY_RC');

class TestCategories {
  final List<String> manual = [];
  final List<String> server = [];
  final List<String> rc = [];
  final List<String> light = [];

  int get total => manual.length + server.length + rc.length + light.length;
}

Future<TestCategories> discoverTests({String filter = ''}) async {
  final categories = TestCategories();

  // Pre-scan utility files (not utils.dart) for category traits
  final utilTraits = <String, Set<String>>{};
  final dir = Directory(testDir);
  if (!await dir.exists()) return categories;

  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final name = _basename(entity.path);
    if (!name.contains('utils') || !name.endsWith('.dart')) continue;
    if (name == 'utils.dart') continue;

    final content = await entity.readAsString();
    final traits = <String>{};
    if (_manualPattern.hasMatch(content)) traits.add('manual');
    if (_serverPattern.hasMatch(content)) traits.add('server');
    if (_rcPattern.hasMatch(content)) traits.add('rc');
    if (traits.isNotEmpty) utilTraits[name] = traits;
  }

  // Scan test files
  final testFiles = <File>[];
  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('_test.dart')) {
      testFiles.add(entity);
    }
  }
  testFiles.sort((a, b) => a.path.compareTo(b.path));

  for (final testFile in testFiles) {
    final relPath = testFile.path.substring(testDir.length + 1);

    // Skip utility files
    if (relPath.contains('utils.dart') || relPath.endsWith('_utils.dart')) {
      continue;
    }

    // Apply --filter pattern (match against forward-slash normalized path)
    if (filter.isNotEmpty && !RegExp(filter).hasMatch(relPath.replaceAll('\\', '/'))) {
      continue;
    }

    final content = await testFile.readAsString();
    var isManual = false;
    var isServer = false;
    var isRc = false;

    // Direct pattern match
    if (_manualPattern.hasMatch(content)) isManual = true;
    if (_serverPattern.hasMatch(content)) isServer = true;
    if (_rcPattern.hasMatch(content)) isRc = true;

    // Transitive match via imported local utils
    for (final line in content.split('\n')) {
      if (!line.startsWith('import ') || line.contains('package:')) continue;
      final match = RegExp(r"'([^']+)'").firstMatch(line);
      if (match != null) {
        final importedFile = _basename(match.group(1)!);
        if (utilTraits.containsKey(importedFile)) {
          final traits = utilTraits[importedFile]!;
          if (traits.contains('manual')) isManual = true;
          if (traits.contains('server')) isServer = true;
          if (traits.contains('rc')) isRc = true;
        }
      }
    }

    // Priority: manual > server > rc > light
    // Normalize to forward slashes for consistent cache keys across platforms
    final normalizedPath = relPath.replaceAll('\\', '/');
    if (isManual) {
      categories.manual.add(normalizedPath);
    } else if (isServer) {
      categories.server.add(normalizedPath);
    } else if (isRc) {
      categories.rc.add(normalizedPath);
    } else {
      categories.light.add(normalizedPath);
    }
  }

  return categories;
}

String _basename(String path) {
  final sep = path.lastIndexOf('/');
  final sep2 = path.lastIndexOf('\\');
  final idx = sep > sep2 ? sep : sep2;
  return idx >= 0 ? path.substring(idx + 1) : path;
}

// ── Cache ──────────────────────────────────────────────────────────
// Per-platform caching: passing on Android doesn't mean passing on iOS.
// Format: one line per passed test:
//   <test_relative_path> <composite_hash>

String _cacheFileForPlatform(String platform) => '$resultsBase${Platform.pathSeparator}.cache_$platform';

Future<String> _computeTestHash(String testRelPath) async {
  // Resolve test file path (testRelPath uses forward slashes)
  final testFilePath = '$testDir${Platform.pathSeparator}${testRelPath.replaceAll('/', Platform.pathSeparator)}';
  final testFile = File(testFilePath);
  final filesToHash = <String>[testFilePath];

  // Find local imports and resolve them
  if (await testFile.exists()) {
    final content = await testFile.readAsString();
    final testFileDir = testFile.parent.path;
    for (final line in content.split('\n')) {
      if (!line.startsWith('import ') || line.contains('package:')) continue;
      final match = RegExp(r"'([^']+)'").firstMatch(line);
      if (match != null) {
        final relImport = match.group(1)!;
        final resolved = '$testFileDir${Platform.pathSeparator}${relImport.replaceAll('/', Platform.pathSeparator)}';
        if (await File(resolved).exists()) {
          filesToHash.add(resolved);
        }
      }
    }
  }

  // Include SDK pubspec (version changes invalidate cache)
  final sdkPubspec = '$projectRoot${Platform.pathSeparator}pubspec.yaml';
  if (await File(sdkPubspec).exists()) {
    filesToHash.add(sdkPubspec);
  }

  return computeSha256(filesToHash);
}

Future<bool> cacheIsPassed(String testPath, String platform, bool fresh) async {
  if (fresh) return false;
  final cacheFile = File(_cacheFileForPlatform(platform));
  if (!await cacheFile.exists()) return false;

  final currentHash = await _computeTestHash(testPath);
  final lines = await cacheFile.readAsLines();
  return lines.any((line) => line == '$testPath $currentHash');
}

Future<void> cacheMarkPassed(String testPath, String platform) async {
  final cf = File(_cacheFileForPlatform(platform));
  await Directory(resultsBase).create(recursive: true);

  final currentHash = await _computeTestHash(testPath);

  if (await cf.exists()) {
    final lines = await cf.readAsLines();
    final filtered = lines.where((l) => !l.startsWith('$testPath ')).toList();
    filtered.add('$testPath $currentHash');
    await cf.writeAsString('${filtered.join('\n')}\n');
  } else {
    await cf.writeAsString('$testPath $currentHash\n');
  }
}

Future<void> cacheMarkFailed(String testPath, String platform) async {
  final cf = File(_cacheFileForPlatform(platform));
  if (!await cf.exists()) return;
  final lines = await cf.readAsLines();
  final filtered = lines.where((l) => !l.startsWith('$testPath ')).toList();
  await cf.writeAsString('${filtered.join('\n')}\n');
}

/// Filter out cached tests for a given platform. Returns (filtered list, skip count).
Future<(List<String>, int)> filterCachedTests(List<String> tests, String platform, bool fresh) async {
  final filtered = <String>[];
  var skipped = 0;
  for (final test in tests) {
    if (test.isEmpty) continue;
    if (await cacheIsPassed(test, platform, fresh)) {
      skipped++;
    } else {
      filtered.add(test);
    }
  }
  return (filtered, skipped);
}

// ── Worker ─────────────────────────────────────────────────────────

Future<WorkerResult> runWorker({
  required int workerId,
  required Device device,
  required List<String> tests,
  required String logDir,
  required Config config,
  required int iosStagger,
}) async {
  final result = WorkerResult(workerId: workerId, device: device);
  final logFile = File('$logDir${Platform.pathSeparator}worker_$workerId.log');
  final stopwatch = Stopwatch()..start();

  // Stagger iOS workers to prevent Xcode concurrent build lock conflicts
  if (device.platform == 'ios' && iosStagger > 0) {
    await Future.delayed(Duration(seconds: iosStagger * 40));
  }

  final label = await getDeviceLabel(device);
  final logSink = logFile.openWrite();
  logSink.writeln('════════════════════════════════════════════════════');
  logSink.writeln('  Worker $workerId — $label');
  logSink.writeln('  Started: ${DateTime.now()}');
  logSink.writeln('════════════════════════════════════════════════════');
  logSink.writeln('');

  for (final test in tests) {
    if (test.isEmpty) continue;

    final testPath = 'integration_test/$test';
    final testLogName = test.replaceAll('/', '__').replaceAll('\\', '__');
    final testLogFile = File('$logDir${Platform.pathSeparator}tests${Platform.pathSeparator}$testLogName.log');
    await testLogFile.parent.create(recursive: true);
    final testStopwatch = Stopwatch()..start();

    logSink.writeln('[W$workerId] ▶ $test');

    final port = 8080 + workerId;
    final process = await Process.start(
      'flutter',
      [
        'test',
        testPath,
        '-d',
        device.id,
        '--timeout',
        config.timeout,
        '--dart-define=TEST_SERVER_PORT=$port',
      ],
      workingDirectory: exampleDir,
    );

    final testLogSink = testLogFile.openWrite();
    final stdoutLines = <String>[];
    final stderrLines = <String>[];

    // Capture stdout
    process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      stdoutLines.add(line);
      testLogSink.writeln(line);
      logSink.writeln(line);
    });

    // Capture stderr
    process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      stderrLines.add(line);
      testLogSink.writeln(line);
      logSink.writeln(line);
    });

    final exitCode = await awaitTestProcess(process, config.timeout);
    await testLogSink.close();

    testStopwatch.stop();
    final elapsed = testStopwatch.elapsed.inSeconds;

    if (exitCode == 0) {
      logSink.writeln('[W$workerId] ✓ PASSED ($test) ${elapsed}s');
      await cacheMarkPassed(test, device.platform);
      result.passed++;
    } else {
      logSink.writeln('[W$workerId] ✗ FAILED ($test) ${elapsed}s');
      await cacheMarkFailed(test, device.platform);
      result.failed++;
      result.failedTests.add(test);
    }
    logSink.writeln('');
  }

  stopwatch.stop();
  result.time = stopwatch.elapsed.inSeconds;
  await logSink.close();

  return result;
}

/// Waits for a test process, killing it if it outlives the timeout.
///
/// The `--timeout` passed to `flutter test` bounds each test case, not the
/// process. A `flutter test` that hangs after reporting a failure would
/// otherwise stall the whole run indefinitely, which is exactly when the run
/// most needs to finish and report.
Future<int> awaitTestProcess(Process process, String seconds) async {
  final limit = Duration(seconds: (int.tryParse(seconds) ?? 300) + 60);
  try {
    return await process.exitCode.timeout(limit);
  } on TimeoutException {
    process.kill(ProcessSignal.sigkill);
    await process.exitCode;
    return 124;
  }
}

/// Raises the app on an iOS simulator when a test asks to be foregrounded.
///
/// These tests are only "manual" because iOS forbids an app raising itself from
/// the background, so `FlutterForegroundTask.launchApp()` degrades to printing a
/// prompt and waiting for a tap. An external `simctl launch` has no such limit,
/// so on a simulator the tap can be scripted and the whole manual set runs
/// unattended. A physical device still needs a person.
///
/// Each prompt is answered once, so a test that backgrounds more than once is
/// raised each time rather than only the first.
class ForegroundResponder {
  ForegroundResponder(this.device, this.bundleId);

  /// Reads the host app's bundle identifier from the Xcode project rather than
  /// assuming it, so renaming the example app does not silently stop the
  /// foregrounding working while looking like the automation is broken.
  static String? bundleIdFrom(String exampleDir) {
    final pbxproj = File('$exampleDir${Platform.pathSeparator}ios${Platform.pathSeparator}Runner.xcodeproj${Platform.pathSeparator}project.pbxproj');
    if (!pbxproj.existsSync()) return null;
    for (final line in pbxproj.readAsLinesSync()) {
      final match = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([\w.]+);').firstMatch(line);
      // Extension targets share the app's prefix; the app itself has no suffix.
      if (match != null && !match.group(1)!.contains('.CountlyNSE')) return match.group(1);
    }
    return null;
  }

  final Device device;
  final String bundleId;
  int _answered = 0;

  bool get canAutomate => device.platform == 'ios' && device.id.contains('-');

  void onOutput(String data) {
    if (!canAutomate) return;
    final prompts = 'go to foreground now'.allMatches(data).length;
    for (var i = 0; i < prompts; i++) {
      _answered++;
      Process.run('xcrun', ['simctl', 'launch', device.id, bundleId]);
    }
  }

  int get answered => _answered;
}

// ── Live Progress ──────────────────────────────────────────────────

/// Watches worker log files and prints progress lines to stdout.
List<StreamSubscription> startLiveProgress(int numWorkers, String logDir, bool verbose) {
  final colors = [C.red, C.green, C.yellow, C.cyan, '\x1B[0;35m', '\x1B[0;36m'];
  final subscriptions = <StreamSubscription>[];
  final progressPattern = RegExp(r'[▶✓✗]');

  for (var i = 0; i < numWorkers; i++) {
    final color = colors[i % colors.length];
    final logFile = File('$logDir${Platform.pathSeparator}worker_$i.log');

    // Ensure the file exists for tailing
    logFile.createSync(recursive: true);

    // Poll the file for new content
    var lastLength = 0;
    final timer = Stream.periodic(const Duration(milliseconds: 500));
    final sub = timer.listen((_) async {
      try {
        if (!await logFile.exists()) return;
        final content = await logFile.readAsString();
        if (content.length > lastLength) {
          final newContent = content.substring(lastLength);
          lastLength = content.length;
          for (final line in newContent.split('\n')) {
            if (line.isEmpty) continue;
            if (verbose || progressPattern.hasMatch(line)) {
              stdout.writeln('$color$line${C.nc}');
            }
          }
        }
      } catch (_) {}
    });
    subscriptions.add(sub);
  }

  return subscriptions;
}

// ── Parse Arguments ────────────────────────────────────────────────

Config parseArgs(List<String> args) {
  final config = Config();
  var hasCategory = false;
  var i = 0;

  while (i < args.length) {
    switch (args[i]) {
      case '--auto':
        config.runAuto = true;
        hasCategory = true;
      case '--manual':
        config.runManual = true;
        hasCategory = true;
      case '--server':
        config.runServer = true;
        hasCategory = true;
      case '--rc':
        config.runRc = true;
        hasCategory = true;
      case '--light':
        config.runLight = true;
        hasCategory = true;
      case '--all':
        config.runManual = true;
        config.runServer = true;
        config.runRc = true;
        config.runLight = true;
        hasCategory = true;
      case '--list':
        config.listOnly = true;
        hasCategory = true;
      case '--dry-run':
        config.dryRun = true;
      case '-v' || '--verbose':
        config.verbose = true;
      case '--fresh':
        config.fresh = true;
      case '--clear-cache':
        config.clearCache = true;
      case '-d' || '--device':
        i++;
        if (i < args.length) config.restrictDevices = args[i];
      case '--timeout':
        i++;
        if (i < args.length) config.timeout = args[i];
      case '--filter':
        i++;
        if (i < args.length) config.filter = args[i];
      case '-h' || '--help':
        _printHelp();
        exit(0);
      default:
        stderr.writeln('Unknown option: ${args[i]} (use --help)');
        exit(1);
    }
    i++;
  }

  if (!hasCategory) config.runAuto = true;
  if (config.runAuto) {
    config.runServer = true;
    config.runRc = true;
    config.runLight = true;
  }

  return config;
}

void _printHelp() {
  // Print the doc comment at the top of this file
  final lines = File(Platform.script.toFilePath()).readAsLinesSync();
  for (final line in lines.skip(1)) {
    if (!line.startsWith('///')) break;
    stdout.writeln(line.replaceFirst(RegExp(r'^/// ?'), ''));
  }
}

// ── Main ───────────────────────────────────────────────────────────

Future<void> main(List<String> args) async {
  initPaths();
  final config = parseArgs(args);

  // Handle --clear-cache
  if (config.clearCache) {
    var cleared = false;
    for (final p in ['android', 'ios']) {
      final cf = File(_cacheFileForPlatform(p));
      if (await cf.exists()) {
        await cf.delete();
        cleared = true;
      }
    }
    if (cleared) {
      stdout.writeln('${C.green}Cache cleared (android + ios).${C.nc}');
    } else {
      stdout.writeln('${C.dim}No cache files found.${C.nc}');
    }
    return;
  }

  stdout.writeln('${C.white}Countly Flutter SDK - Integration Test Runner${C.nc}');
  stdout.writeln('');

  // ── Step 1: Discover devices ──────────────────────────────────────
  stdout.writeln('${C.dim}Scanning for devices...${C.nc}');
  var deviceList = await discoverDevices();

  // Apply device filter
  if (config.restrictDevices.isNotEmpty) {
    final filters = config.restrictDevices.split(',');
    deviceList = deviceList.where((d) => filters.contains(d.id)).toList();
  }

  if (deviceList.isEmpty) {
    stdout.writeln('${C.red}No devices found!${C.nc}');
    stdout.writeln('');
    stdout.writeln('Start a device first:');
    stdout.writeln('  Android emulator:    flutter emulators --launch Pixel_9_Pro_XL_API_36');
    if (Platform.isMacOS) {
      stdout.writeln('  iOS simulator:       open -a Simulator');
      stdout.writeln('  Check connected:     adb devices && xcrun simctl list devices booted');
    } else {
      stdout.writeln('  Check connected:     adb devices');
    }
    exit(1);
  }

  stdout.writeln('${C.green}Found ${deviceList.length} device(s):${C.nc}');
  for (final device in deviceList) {
    final label = await getDeviceLabel(device);
    stdout.writeln('  ${C.cyan}●${C.nc} $label');
  }

  // ── Step 2: Discover and categorize tests ─────────────────────────
  stdout.writeln('');
  stdout.writeln('${C.dim}Scanning for tests...${C.nc}');
  final categories = await discoverTests(filter: config.filter);

  stdout.writeln('${C.green}Found ${categories.total} test(s):${C.nc}');
  stdout.writeln('  Light: ${categories.light.length}  Server: ${categories.server.length}  RC: ${categories.rc.length}  Manual: ${categories.manual.length}');

  // Show cache status per platform
  if (!config.fresh) {
    for (final p in ['android', 'ios']) {
      final cf = File(_cacheFileForPlatform(p));
      if (await cf.exists()) {
        final lines = (await cf.readAsLines()).where((l) => l.trim().isNotEmpty);
        stdout.writeln('  ${C.dim}Cache ($p): ${lines.length} passed (use --fresh to re-run)${C.nc}');
      }
    }
  }

  // ── List mode ─────────────────────────────────────────────────────
  if (config.listOnly) {
    stdout.writeln('');
    final categoryMap = {
      'manual': ('Manual (fg/bg switching required)', categories.manual),
      'server': ('Server (local test server)', categories.server),
      'rc': ('Remote Config (needs network)', categories.rc),
      'light': ('Lightweight (no server needed)', categories.light),
    };

    for (final entry in categoryMap.entries) {
      final label = entry.value.$1;
      final tests = entry.value.$2;
      stdout.writeln('${C.yellow}$label (${tests.length}):${C.nc}');
      for (final test in tests) {
        final cachedOn = <String>[];
        for (final p in ['android', 'ios']) {
          if (await cacheIsPassed(test, p, config.fresh)) cachedOn.add(p);
        }
        if (cachedOn.isNotEmpty) {
          stdout.writeln('  ${C.dim}✓ $test (cached: ${cachedOn.join(' ')})${C.nc}');
        } else {
          stdout.writeln('  $test');
        }
      }
      stdout.writeln('');
    }
    return;
  }

  // ── Step 3: Build test list, applying per-platform cache ──────────
  // Determine active platforms
  final activePlatforms = deviceList.map((d) => d.platform).toSet().toList();
  stdout.writeln('  ${C.dim}Active platforms: ${activePlatforms.join(' ')}${C.nc}');

  // Collect all auto tests for selected categories
  final allAutoTests = <String>[];
  if (config.runLight) allAutoTests.addAll(categories.light);
  if (config.runServer) allAutoTests.addAll(categories.server);
  if (config.runRc) allAutoTests.addAll(categories.rc);

  final allManualTests = config.runManual ? List<String>.from(categories.manual) : <String>[];

  // Filter per platform and show skip counts
  final filteredAutoPerPlatform = <String, List<String>>{};
  final filteredManualPerPlatform = <String, List<String>>{};
  final skipMessages = <String>[];

  for (final p in activePlatforms) {
    final (filteredAuto, skippedAuto) = await filterCachedTests(allAutoTests, p, config.fresh);
    filteredAutoPerPlatform[p] = filteredAuto;
    if (skippedAuto > 0) {
      skipMessages.add('  ${C.green}Skipping $skippedAuto cached test(s) on $p${C.nc}');
    }

    final (filteredManual, skippedManual) = await filterCachedTests(allManualTests, p, config.fresh);
    filteredManualPerPlatform[p] = filteredManual;
    if (skippedManual > 0) {
      skipMessages.add('  ${C.green}Skipping $skippedManual cached manual test(s) on $p${C.nc}');
    }
  }

  if (skipMessages.isNotEmpty) {
    for (final msg in skipMessages) {
      stdout.writeln(msg);
    }
  }

  // Check if there's anything to run
  final hasAuto = filteredAutoPerPlatform.values.any((tests) => tests.isNotEmpty);
  final hasManual = filteredManualPerPlatform.values.any((tests) => tests.isNotEmpty);

  if (!hasAuto && !hasManual) {
    stdout.writeln('');
    stdout.writeln('${C.green}All tests already passed (cached) on all platforms. Use --fresh to re-run.${C.nc}');
    return;
  }

  // ── Step 4: Distribute tests across devices ───────────────────────
  // Group devices by platform, round-robin distribute each platform's tests
  final deviceTests = <int, List<String>>{};
  for (var i = 0; i < deviceList.length; i++) {
    deviceTests[i] = [];
  }

  for (final p in activePlatforms) {
    final platformDeviceIndices = <int>[];
    for (var i = 0; i < deviceList.length; i++) {
      if (deviceList[i].platform == p) platformDeviceIndices.add(i);
    }

    final tests = filteredAutoPerPlatform[p] ?? [];
    if (platformDeviceIndices.length <= 1) {
      // Single device for this platform — gets all tests
      for (final idx in platformDeviceIndices) {
        deviceTests[idx] = List.from(tests);
      }
    } else {
      // Round-robin split
      for (var t = 0; t < tests.length; t++) {
        final targetIdx = platformDeviceIndices[t % platformDeviceIndices.length];
        deviceTests[targetIdx]!.add(tests[t]);
      }
    }
  }

  // Count totals
  var totalAuto = 0;
  for (final tests in deviceTests.values) {
    totalAuto += tests.length;
  }

  // Collect unique manual tests to run across all platforms
  var manualTestsToRun = <String>{};
  if (config.runManual) {
    for (final tests in filteredManualPerPlatform.values) {
      manualTestsToRun.addAll(tests);
    }
  }
  final totalManual = manualTestsToRun.length;

  stdout.writeln('  ${C.white}Running: $totalAuto auto + $totalManual manual${C.nc}');
  stdout.writeln('');

  if (totalAuto > 0) {
    stdout.writeln('${C.white}Distribution Plan:${C.nc}');
    for (var i = 0; i < deviceList.length; i++) {
      final tests = deviceTests[i]!;
      final label = await getDeviceLabel(deviceList[i]);
      stdout.writeln('  ${C.cyan}●${C.nc} $label → ${tests.length} test(s)');
      if (config.dryRun) {
        for (final t in tests) {
          stdout.writeln('      $t');
        }
      }
    }
  }

  if (totalManual > 0) {
    stdout.writeln('  ${C.yellow}●${C.nc} Manual tests (after parallel run) → $totalManual test(s)');
  }

  if (config.dryRun) {
    stdout.writeln('');
    stdout.writeln('${C.dim}Dry run complete. Remove --dry-run to execute.${C.nc}');
    return;
  }

  // ── Step 5: Create log directory & launch workers ─────────────────
  final overallStopwatch = Stopwatch()..start();
  final runTs = DateTime.now().toIso8601String().replaceAll(':', '').replaceAll('-', '').substring(0, 15).replaceAll('T', '_');
  final logDir = '$resultsBase${Platform.pathSeparator}$runTs';
  await Directory('$logDir${Platform.pathSeparator}tests').create(recursive: true);

  var totalPassed = 0;
  var totalFailed = 0;
  final allFailedTests = <String>[];

  if (totalAuto > 0) {
    stdout.writeln('');
    stdout.writeln('${C.white}Running $totalAuto unattended tests across ${deviceList.length} device(s)...${C.nc}');
    stdout.writeln('${C.dim}Logs → $logDir${C.nc}');
    stdout.writeln('');

    // Start live progress watchers
    final progressSubs = startLiveProgress(deviceList.length, logDir, config.verbose);

    // Launch workers in parallel
    final futures = <Future<WorkerResult>>[];
    var iosCount = 0;
    for (var i = 0; i < deviceList.length; i++) {
      if (deviceTests[i]!.isNotEmpty) {
        var stagger = 0;
        if (deviceList[i].platform == 'ios') {
          stagger = iosCount;
          iosCount++;
        }
        futures.add(runWorker(
          workerId: i,
          device: deviceList[i],
          tests: deviceTests[i]!,
          logDir: logDir,
          config: config,
          iosStagger: stagger,
        ));
      }
    }

    // Wait for all workers
    final results = await Future.wait(futures);

    // Stop progress watchers
    for (final sub in progressSubs) {
      await sub.cancel();
    }

    stdout.writeln('');

    // ── Step 6: Aggregate results ───────────────────────────────────
    stdout.writeln('${C.white}═══════════════════════════════════════════════════${C.nc}');
    stdout.writeln('${C.white}  Results${C.nc}');
    stdout.writeln('${C.white}═══════════════════════════════════════════════════${C.nc}');

    for (final wr in results) {
      final label = await getDeviceLabel(wr.device);
      stdout.writeln('');
      stdout.writeln('  ${C.cyan}●${C.nc} $label');
      stdout.writeln('    ${C.green}Passed: ${wr.passed}${C.nc}  ${C.red}Failed: ${wr.failed}${C.nc}  Time: ${wr.time}s');
      for (final ft in wr.failedTests) {
        stdout.writeln('    ${C.red}✗${C.nc} $ft');
        allFailedTests.add(ft);
      }
      totalPassed += wr.passed;
      totalFailed += wr.failed;
    }
  }

  // ── Step 7: Manual tests (single device, sequential) ─────────────
  if (manualTestsToRun.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('${C.yellow}═══════════════════════════════════════════════════${C.nc}');
    stdout.writeln('${C.yellow}  Manual Tests (${manualTestsToRun.length} tests)${C.nc}');
    stdout.writeln('${C.yellow}  These need you at the device for fg/bg switching.${C.nc}');
    stdout.writeln('${C.yellow}═══════════════════════════════════════════════════${C.nc}');
    stdout.writeln('');
    stdout.writeln('Which device for manual tests?');
    for (var i = 0; i < deviceList.length; i++) {
      final label = await getDeviceLabel(deviceList[i]);
      stdout.writeln('  [$i] $label');
    }
    stdout.write('Device number [0]: ');
    final input = stdin.readLineSync()?.trim() ?? '';
    final manualDeviceIdx = input.isEmpty ? 0 : int.tryParse(input) ?? 0;

    final manualDevice = deviceList[manualDeviceIdx];

    // Re-filter manual tests for the selected device's platform
    final (refilteredManual, _) = await filterCachedTests(allManualTests, manualDevice.platform, config.fresh);

    if (refilteredManual.isEmpty) {
      stdout.writeln('\n${C.green}All manual tests already passed (cached) on ${manualDevice.platform}. Use --fresh to re-run.${C.nc}');
    } else {
      final bundleId = ForegroundResponder.bundleIdFrom(exampleDir);
      final responder = ForegroundResponder(manualDevice, bundleId ?? 'com.countly.demo');
      if (bundleId == null) {
        stdout.writeln('${C.yellow}Could not read the bundle id from the Xcode project; falling back to com.countly.demo.${C.nc}');
      }
      stdout.writeln('');
      if (responder.canAutomate) {
        stdout.writeln('${C.green}iOS simulator detected: foregrounding will be scripted, no interaction needed.${C.nc}');
      } else {
        stdout.write('Press Enter when ready (stay at the device)...');
        stdin.readLineSync();
      }

      var manualPassed = 0;
      var manualFailed = 0;

      for (final test in refilteredManual) {
        stdout.writeln('\n${C.cyan}▶${C.nc} $test');
        final testStopwatch = Stopwatch()..start();
        final testLogName = test.replaceAll('/', '__').replaceAll('\\', '__');
        final testLogFile = File('$logDir${Platform.pathSeparator}tests${Platform.pathSeparator}$testLogName.log');
        await testLogFile.parent.create(recursive: true);

        final process = await Process.start(
          'flutter',
          [
            'test',
            'integration_test/$test',
            '-d',
            manualDevice.id,
            '--timeout',
            config.timeout,
            '--dart-define=TEST_SERVER_PORT=8080',
          ],
          workingDirectory: exampleDir,
        );

        final testLogSink = testLogFile.openWrite();

        // Stream output live for manual tests
        process.stdout.transform(utf8.decoder).listen((data) {
          stdout.write(data);
          testLogSink.write(data);
          responder.onOutput(data);
        });
        process.stderr.transform(utf8.decoder).listen((data) {
          stderr.write(data);
          testLogSink.write(data);
        });

        final exitCode = await awaitTestProcess(process, config.timeout);
        await testLogSink.close();
        testStopwatch.stop();
        final elapsed = testStopwatch.elapsed.inSeconds;

        if (exitCode == 0) {
          stdout.writeln('${C.green}  ✓ PASSED${C.nc} (${elapsed}s)');
          await cacheMarkPassed(test, manualDevice.platform);
          manualPassed++;
        } else {
          stdout.writeln('${C.red}  ✗ FAILED${C.nc} (${elapsed}s)');
          await cacheMarkFailed(test, manualDevice.platform);
          manualFailed++;
          allFailedTests.add(test);
        }
      }

      totalPassed += manualPassed;
      totalFailed += manualFailed;
    }
  }

  // ── Final Summary ─────────────────────────────────────────────────
  overallStopwatch.stop();
  final overallTime = overallStopwatch.elapsed.inSeconds;

  stdout.writeln('');
  stdout.writeln('${C.white}═══════════════════════════════════════════════════${C.nc}');
  stdout.writeln('${C.white}  Final Summary${C.nc}');
  stdout.writeln('${C.white}═══════════════════════════════════════════════════${C.nc}');
  stdout.writeln('  Ran: ${totalPassed + totalFailed}  ${C.green}Passed: $totalPassed${C.nc}  ${C.red}Failed: $totalFailed${C.nc}');
  stdout.writeln('  Wall time: ${formatDuration(overallTime)}');

  if (allFailedTests.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('  ${C.red}Failed tests:${C.nc}');
    for (final ft in allFailedTests) {
      final logName = ft.replaceAll('/', '__').replaceAll('\\', '__');
      stdout.writeln('    ${C.red}✗${C.nc} $ft');
      stdout.writeln('      ${C.dim}→ $logDir${Platform.pathSeparator}tests${Platform.pathSeparator}$logName.log${C.nc}');
    }
  }

  stdout.writeln('');
  stdout.writeln('  ${C.dim}Full logs:     $logDir${Platform.pathSeparator}${C.nc}');
  stdout.writeln('  ${C.dim}Worker logs:   $logDir${Platform.pathSeparator}worker_N.log${C.nc}');
  stdout.writeln('  ${C.dim}Per-test logs: $logDir${Platform.pathSeparator}tests${Platform.pathSeparator}<name>.log${C.nc}');
  stdout.writeln('');

  if (totalFailed == 0) {
    stdout.writeln('  ${C.green}All tests passed!${C.nc}');
    // macOS notification
    if (Platform.isMacOS) {
      try {
        await Process.run('osascript', [
          '-e',
          'display notification "✅ All $totalPassed tests passed (${overallTime}s)" with title "Flutter Integration Tests" sound name "Glass"',
        ]);
      } catch (_) {}
    }
  } else {
    stdout.writeln('  ${C.red}$totalFailed test(s) failed.${C.nc}');
    // macOS notification
    if (Platform.isMacOS) {
      try {
        await Process.run('osascript', [
          '-e',
          'display notification "❌ $totalFailed failed, $totalPassed passed (${overallTime}s)" with title "Flutter Integration Tests" sound name "Basso"',
        ]);
      } catch (_) {}
    }
  }

  exit(totalFailed);
}
