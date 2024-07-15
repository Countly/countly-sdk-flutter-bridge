import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// 11.Testing changeWithoutMerge
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('11.Testing changeWithoutMerge.', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setEventQueueSizeToSend(1);
    await Countly.initWithConfig(config);
    await Countly.instance.deviceId.changeWithoutMerge('test');

    // trigger a event so we can check the ID
    await Countly.recordEvent({'key': 'Basic Event', 'count': 1});

    // Get the device ID type
    DeviceIdType? type = await Countly.instance.deviceId.getIDType();
    String? id = await Countly.instance.deviceId.getID();
    // Verify the device ID type
    expect(type, DeviceIdType.DEVELOPER_SUPPLIED);
    expect(id, 'test');

    // Check that deviceID parameter is set correctly in request queue
    await testCustomRequestParams({'device_id': 'test'});
  });
}
