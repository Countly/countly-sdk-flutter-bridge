import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// 10.Testing changeWithMerge forces merge on the server.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('10.Testing changeWithMerge forces merge on the server.', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setDeviceId('test');
    await Countly.initWithConfig(config);
    await Countly.instance.deviceId.changeWithMerge('test1');
    // Get the device ID type
    DeviceIdType? type = await Countly.instance.deviceId.getIDType();
    String? id = await Countly.instance.deviceId.getID();
    // Verify the device ID type
    expect(type, DeviceIdType.DEVELOPER_SUPPLIED);
    expect(id, 'test1');

    // Check that deviceID parameter is set correctly in request queue
    await testCustomRequestParams({'old_device_id': 'test', 'device_id': 'test1'});
  });
}
