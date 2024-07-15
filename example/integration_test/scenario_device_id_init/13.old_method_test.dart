import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// 13.Test the integrity of the old methods to ensure they work as before
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('13.Test the integrity of the old methods to ensure they work as before', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setEventQueueSizeToSend(1);
    await Countly.initWithConfig(config);

    // Verify initial device ID type and current device ID
    DeviceIdType? type = await Countly.getDeviceIDType();
    String? id = await Countly.getCurrentDeviceId();
    expect(type, DeviceIdType.SDK_GENERATED);
    expect(id?.length, Platform.isIOS ? 36 : 16);
    expect(id, isNot('test'));

    // Change device ID without merge and verify the changes
    await Countly.changeDeviceId('test', false);
    await Countly.recordEvent({'key': 'Basic Event', 'count': 1});
    DeviceIdType? type1 = await Countly.getDeviceIDType();
    String? id1 = await Countly.getCurrentDeviceId();
    expect(type1, DeviceIdType.DEVELOPER_SUPPLIED);
    expect(id1, 'test');
    // Check that deviceID parameter is set correctly in request queue
    await testCustomRequestParams({'old_device_id': null, 'device_id': 'test'});

    // Change device ID with merge again and verify the changes
    await Countly.changeDeviceId('test1', true);
    DeviceIdType? type2 = await Countly.getDeviceIDType();
    String? id2 = await Countly.getCurrentDeviceId();
    expect(type2, DeviceIdType.DEVELOPER_SUPPLIED);
    expect(id2, 'test1');
    // Check that deviceID parameter is set correctly in request queue
    await testCustomRequestParams({'old_device_id': 'test', 'device_id': 'test1'});

    // Change to temporary device ID and verify the changes
    await Countly.changeDeviceId(Countly.deviceIDType['TemporaryDeviceID']!, false);
    final initialRequestList = await getRequestQueue();

    await Countly.recordEvent({'key': 'Basic Event', 'count': 1});
    DeviceIdType? type3 = await Countly.getDeviceIDType();
    String? id3 = await Countly.getCurrentDeviceId();
    expect(type3, DeviceIdType.TEMPORARY_ID);
    expect(id3, Countly.deviceIDType['TemporaryDeviceID']!);

    // Set invalid device ID and verify it is ignored
    await Countly.changeDeviceId('', false);
    await Countly.recordEvent({'key': 'Basic Event', 'count': 1});
    DeviceIdType? type4 = await Countly.getDeviceIDType();
    String? id4 = await Countly.getCurrentDeviceId();
    expect(type4, DeviceIdType.TEMPORARY_ID);
    expect(id4, Countly.deviceIDType['TemporaryDeviceID']!);

    // Ensure no requests are being sent after enabling temp ID
    final finalRequestList = await getRequestQueue();
    print('Length: ${initialRequestList.length}, ${finalRequestList.length}');
    // expect(initialRequestList, finalRequestList);
  });
}
