@TestOn('browser')
library consent_device_id_test;

import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'web_test_utils.dart';

void main() {
  setUpWebPlugin();

  test('Events follow the events consent as it is given and removed', () async {
    await Countly.initWithConfig(testConfig()..setRequiresConsent(true));

    await Countly.instance.events.recordEvent('before_consent');
    await Countly.giveConsent(['events']);
    await Countly.instance.events.recordEvent('with_consent');
    await waitForHeartbeat();
    await Countly.removeConsent(['events']);
    await Countly.instance.events.recordEvent('after_removal');
    await waitForHeartbeat();

    expect((await queuedEvents()).map((e) => e['key']).toList(), ['with_consent']);
    // Only the given consent is checked: Web SDK 26.1.3 queues no request when consent is removed.
    final List<Map<String, dynamic>> consents = (await requestsWith('consent')).map((r) => jsonDecode(r['consent'] as String) as Map<String, dynamic>).toList();
    expect(consents.where((c) => c['events'] == true), isNotEmpty);
  });

  test('Device ID changes with and without merge, and temporary ID mode', () async {
    await Countly.initWithConfig(testConfig()..setDeviceId('developer_1'));
    expect(await Countly.instance.deviceId.getID(), 'developer_1');
    expect(await Countly.instance.deviceId.getIDType(), DeviceIdType.DEVELOPER_SUPPLIED);

    await Countly.instance.deviceId.changeWithMerge('developer_2');
    await waitForHeartbeat();
    expect(await Countly.instance.deviceId.getID(), 'developer_2');
    final Map<String, dynamic> merge = (await requestsWith('old_device_id')).single;
    expect(merge['old_device_id'], 'developer_1');
    expect(merge['device_id'], 'developer_2');

    await Countly.instance.deviceId.changeWithoutMerge('developer_3');
    expect(await Countly.instance.deviceId.getID(), 'developer_3');
    expect(await requestsWith('old_device_id'), hasLength(1));

    await Countly.instance.deviceId.enableTemporaryIDMode();
    expect(await Countly.instance.deviceId.getIDType(), DeviceIdType.TEMPORARY_ID);
  });

  test('A generated device ID is reported as SDK generated', () async {
    await Countly.initWithConfig(testConfig());
    expect(await Countly.instance.deviceId.getID(), isNotEmpty);
    expect(await Countly.instance.deviceId.getIDType(), DeviceIdType.SDK_GENERATED);
  });
}
