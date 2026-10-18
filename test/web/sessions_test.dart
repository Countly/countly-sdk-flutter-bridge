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

  test('setID replaces a developer supplied ID without merging', () async {
    await Countly.initWithConfig(testConfig()..setDeviceId('first_user'));
    await Countly.instance.deviceId.setID('second_user');
    await waitForHeartbeat();

    expect(await Countly.instance.deviceId.getID(), 'second_user');
    expect(await requestsWith('old_device_id'), isEmpty);
  });

  test('setID merges a generated ID into the new one', () async {
    await Countly.initWithConfig(testConfig());
    final String? generatedId = await Countly.instance.deviceId.getID();
    await Countly.instance.deviceId.setID('merged_user');
    await waitForHeartbeat();

    final Map<String, dynamic> merge = (await requestsWith('old_device_id')).single;
    expect(merge['old_device_id'], generatedId);
    expect(merge['device_id'], 'merged_user');
    expect(await Countly.instance.deviceId.getIDType(), DeviceIdType.DEVELOPER_SUPPLIED);
  });

  // Runs last, as the Dart side keeps manual session handling enabled after halt.
  test('Manual sessions begin with the Web SDK call, and updateSession sends nothing on web', () async {
    await Countly.initWithConfig(testConfig()..enableManualSessionHandling());
    await waitForHeartbeat();
    expect(await requestsWith('begin_session'), isEmpty);

    await Countly.instance.sessions.beginSession();
    await Countly.instance.sessions.updateSession();
    await waitForHeartbeat();

    expect(await requestsWith('begin_session'), hasLength(1));
    expect(await requestsWith('session_duration'), isEmpty);
    await Countly.instance.sessions.endSession();
  });
}
