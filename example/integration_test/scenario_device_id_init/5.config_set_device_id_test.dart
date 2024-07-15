import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// 5.Test setDeviceID - Developer sets the ID in config
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('5.Test setDeviceID - Developer sets the ID in config', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setDeviceId('test');
    await Countly.initWithConfig(config);

    // Get the device ID type and current device ID
    DeviceIdType? type = await Countly.instance.deviceId.getIDType();
    String? id = await Countly.instance.deviceId.getID();

    // Verify that the device ID type is set to DEVELOPER_SUPPLIED
    expect(type, DeviceIdType.DEVELOPER_SUPPLIED);
    // Verify that the current device ID matches the set ID
    expect(id, 'test');

    // Check that deviceID parameter is set correctly in request queue
    await testCustomRequestParams({'device_id': 'test'});
  });
}
