@TestOn('vm')
library request_scenarios_test;

import 'dart:convert';
import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// In each request scenario the plugin hands the native SDK the calls api/requests/<scenario>.json records, each with
// its method and arguments. The scenarios make the calls the other Countly SDKs make in their own request tests; the
// native SDKs' own records hold the requests those calls send. A deliberate change: run
// COUNTLY_UPDATE_REQUESTS=1 flutter test test/request_scenarios_test.dart, which writes the records, check the
// difference and add a line to CHANGELOG.md.

const int maxInt = 2147483647;

/// Stands in for the native plugin: keeps every call with its decoded arguments and answers the way the plugin does.
class _RecordingPlatform {
  final List<Map<String, Object?>> calls = <Map<String, Object?>>[];

  /// Keeps the call and answers it.
  Future<Object?> handle(MethodCall call) async {
    final Object? arguments = call.arguments;
    final Object? args = arguments is Map && arguments['data'] is String ? jsonDecode(arguments['data'] as String) : arguments;
    calls.add(<String, Object?>{'method': call.method, 'args': _sorted(args)});
    if (call.method == 'init') {
      return 'initialized.';
    }
    if (call.method == 'isInitialized') {
      return 'true';
    }
    return null;
  }
}

/// A copy of a JSON value with the keys of every object sorted, so that the order they are written in does not count.
Object? _sorted(Object? value) {
  if (value is List) {
    return value.map(_sorted).toList();
  }
  if (value is Map) {
    final List<String> keys = value.keys.map((Object? key) => key.toString()).toList()..sort();
    return <String, Object?>{for (final String key in keys) key: _sorted(value[key])};
  }
  return value;
}

/// The init config every scenario starts from: the parity server, app key and device ID, with manual sessions.
CountlyConfig _config() {
  return CountlyConfig('https://parity.example', 'parity-app-key')
    ..setDeviceId('parity-device-001')
    ..enableManualSessionHandling();
}

/// Runs a scenario on a new SDK instance and compares the calls it handed the native SDK with the record of the
/// scenario, or writes the record when COUNTLY_UPDATE_REQUESTS is set.
Future<void> _checkCalls(String name, CountlyConfig config, Future<void> Function() scenario) async {
  final _RecordingPlatform platform = _RecordingPlatform();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('countly_flutter'), platform.handle);
  await Countly.initWithConfig(config);
  await scenario();

  final String current = '${const JsonEncoder.withIndent('  ').convert(platform.calls)}\n';
  final File file = File('api/requests/$name.json');
  if (Platform.environment.containsKey('COUNTLY_UPDATE_REQUESTS')) {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(current);
    return;
  }
  final String committed = file.existsSync() ? file.readAsStringSync().replaceAll('\r\n', '\n') : '(no api/requests/$name.json)\n';
  expect(current, committed,
      reason: 'the calls of the $name scenario differ from api/requests/$name.json. If that is deliberate, run '
          'COUNTLY_UPDATE_REQUESTS=1 flutter test test/request_scenarios_test.dart, check the difference and add a line to CHANGELOG.md.');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await Countly.instance.halt();
  });

  test('parity: a session with an event of every segmentation value type, the user details and a session update', () async {
    await _checkCalls('parity', _config(), () async {
      await Countly.instance.sessions.beginSession();
      await Countly.instance.events.recordEvent(
          'purchase',
          <String, Object>{
            'nar': 'uto',
            'sasuke': maxInt,
            'sakura': false,
            'itachi': double.maxFinite,
            'kakaski': double.minPositive,
            'hashirama': -maxInt,
            'tobi': <String, Object>{'obito': 'uchiha', 'zetsu': 'white'},
            'stringList': <String>['value1', 'value2', 'value3'],
            'intList': <int>[1, 2, 3],
            'doubleList': <double>[1.1, 2.2, 3.3],
            'boolList': <bool>[true, false, true],
            'mixedList': <Object>['value1', 2, 3.3, true],
            'mapList': <Map<String, Object>>[
              <String, Object>{'key1': 'value1', 'key2': 2},
              <String, Object>{'key1': 'value2', 'key2': 3},
              <String, Object>{'key1': 'value3', 'key2': 4},
            ],
          },
          2,
          9.99,
          5);
      await Countly.instance.userProfile.setUserProperties(<String, Object>{
        'name': 'John Doe',
        'username': 'john_d',
        'email': 'john@example.com',
        'organization': 'Countly',
        'phone': '1234567890',
        'picture': 'https://example.com/picture.jpg',
        'gender': 'M',
        'byear': 1980,
        'tier': 'gold',
        'age': 30,
      });
      await Countly.instance.userProfile.save();
      await Countly.instance.sessions.updateSession();
      await Countly.instance.sessions.endSession();
    });
  });

  test('views: two views in a session, the first with segmentation', () async {
    await _checkCalls('views', _config(), () async {
      await Countly.instance.sessions.beginSession();
      await Countly.instance.views.startView('Home', <String, Object>{'source': 'scenario'});
      await Countly.instance.views.stopViewWithName('Home');
      await Countly.instance.views.startView('Settings');
      await Countly.instance.sessions.endSession();
    });
  });

  test('crash: a handled exception with a breadcrumb and segmentation', () async {
    await _checkCalls('crash', _config(), () async {
      await Countly.addCrashLog('breadcrumb one');
      await Countly.logException('parity crash', true, <String, Object>{'tier': 'gold'});
    });
  });

  test('consent: given for sessions and events, then taken back for events', () async {
    await _checkCalls('consent', _config()..setRequiresConsent(true), () async {
      await Countly.giveConsent(<String>['sessions', 'events']);
      await Countly.instance.sessions.beginSession();
      await Countly.instance.events.recordEvent('consented');
      await Countly.removeConsent(<String>['events']);
      await Countly.instance.events.recordEvent('not_consented');
      await Countly.instance.sessions.endSession();
    });
  });

  test('device-id: a change with merge, then one without', () async {
    await _checkCalls('device-id', _config(), () async {
      await Countly.instance.sessions.beginSession();
      await Countly.instance.deviceId.changeWithMerge('parity-device-002');
      await Countly.instance.events.recordEvent('after_merge');
      await Countly.instance.deviceId.changeWithoutMerge('parity-device-003');
      await Countly.instance.events.recordEvent('after_new_id');
      await Countly.instance.sessions.endSession();
    });
  });
}
