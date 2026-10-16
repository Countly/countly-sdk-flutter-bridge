@TestOn('browser')
library sessions_test;

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'web_test_utils.dart';

void main() {
  setUpWebPlugin();

  test('An automatic session begins at init and identifies the Flutter web SDK', () async {
    await Countly.initWithConfig(testConfig());
    await waitForHeartbeat();

    final List<Map<String, dynamic>> begins = await requestsWith('begin_session');
    expect(begins, hasLength(1));
    expect(begins.single['app_key'], 'web_test_app');
    expect(begins.single['sdk_name'], 'dart-flutterb-web');
    expect(begins.single['sdk_version'], isNotEmpty);
    expect(begins.single['metrics'], contains('_ua'));
  });

  test('Session calls are ignored without manual session handling', () async {
    await Countly.initWithConfig(testConfig());
    await Countly.instance.sessions.updateSession();
    await Countly.instance.sessions.endSession();
    await waitForHeartbeat();

    expect(await requestsWith('begin_session'), hasLength(1));
    expect(await requestsWith('end_session'), isEmpty);
  });

  // Runs last, as the Dart side keeps manual session handling enabled after halt.
  test('Manual sessions report only when asked, and end with an end_session request', () async {
    await Countly.initWithConfig(testConfig()
      ..enableManualSessionHandling()
      ..setUpdateSessionTimerDelay(1));
    await waitForHeartbeat();
    expect(await requestsWith('begin_session'), isEmpty);

    await Countly.instance.sessions.beginSession();
    await Future<void>.delayed(const Duration(seconds: 3));
    // With a 1 second update delay, an automatic session would have reported by now.
    expect(await requestsWith('session_duration'), isEmpty);

    await Countly.instance.sessions.updateSession();
    await Future<void>.delayed(const Duration(seconds: 2));
    await Countly.instance.sessions.endSession();
    await waitForHeartbeat();

    expect(await requestsWith('begin_session'), hasLength(1));
    final List<Map<String, dynamic>> durations = await requestsWith('session_duration');
    expect(durations, hasLength(2));
    expect(durations[0].containsKey('end_session'), isFalse);
    expect(durations[0]['session_duration'], inInclusiveRange(2, 4));
    expect(durations[1]['end_session'], 1);
    expect(durations[1]['session_duration'], inInclusiveRange(1, 3));
  });

  test('A device ID change without merge ends the manual session without recounting it and begins one for the new ID', () async {
    await Countly.initWithConfig(testConfig()
      ..enableManualSessionHandling()
      ..setDeviceId('first_user'));
    await Countly.instance.sessions.beginSession();
    await Future<void>.delayed(const Duration(seconds: 2));
    await Countly.instance.sessions.updateSession();
    await Countly.instance.deviceId.changeWithoutMerge('second_user');
    await waitForHeartbeat();

    final List<Map<String, dynamic>> requests = await requestQueue();
    final List<Map<String, dynamic>> ends = requests.where((r) => r['end_session'] == 1).toList();
    expect(ends, hasLength(1));
    expect(ends.single['device_id'], 'first_user');
    expect(ends.single['session_duration'], 1);
    expect(requests.where((r) => r['begin_session'] == 1).map((r) => r['device_id']).toList(), ['first_user', 'second_user']);
  });

  test('setID replaces a developer supplied ID like a change without merge, without recounting the manual session', () async {
    await Countly.initWithConfig(testConfig()
      ..enableManualSessionHandling()
      ..setDeviceId('first_user'));
    await Countly.instance.sessions.beginSession();
    await Future<void>.delayed(const Duration(seconds: 2));
    await Countly.instance.sessions.updateSession();
    await Countly.instance.deviceId.setID('second_user');
    await waitForHeartbeat();

    final List<Map<String, dynamic>> requests = await requestQueue();
    expect(requests.where((r) => r.containsKey('old_device_id')), isEmpty);
    final List<Map<String, dynamic>> ends = requests.where((r) => r['end_session'] == 1).toList();
    expect(ends, hasLength(1));
    expect(ends.single['device_id'], 'first_user');
    expect(ends.single['session_duration'], 1);
    expect(requests.where((r) => r['begin_session'] == 1).map((r) => r['device_id']).toList(), ['first_user', 'second_user']);
  });

  test('setID merges a generated ID into the new one and keeps the manual session running', () async {
    await Countly.initWithConfig(testConfig()..enableManualSessionHandling());
    final String? generatedId = await Countly.instance.deviceId.getID();
    await Countly.instance.sessions.beginSession();
    await Countly.instance.deviceId.setID('merged_user');
    await waitForHeartbeat();

    final List<Map<String, dynamic>> requests = await requestQueue();
    final Map<String, dynamic> merge = requests.singleWhere((r) => r.containsKey('old_device_id'));
    expect(merge['old_device_id'], generatedId);
    expect(merge['device_id'], 'merged_user');
    expect(requests.where((r) => r['end_session'] == 1), isEmpty);
    expect(await Countly.instance.deviceId.getIDType(), DeviceIdType.DEVELOPER_SUPPLIED);
  });
}
