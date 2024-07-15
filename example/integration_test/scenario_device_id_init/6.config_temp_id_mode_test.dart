import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// 6.Check if enableTemporaryDeviceIDMode() sets the device ID correctly before init
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('6.Check if enableTemporaryDeviceIDMode() sets the device ID correctly before init', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).enableTemporaryDeviceIDMode();
    await Countly.initWithConfig(config);

    // Get the device ID type
    DeviceIdType? type = await Countly.instance.deviceId.getIDType();
    // Get the device ID
    String? id = await Countly.instance.deviceId.getID();

    // Verify the device ID type
    expect(type, DeviceIdType.TEMPORARY_ID);
    // Verify the device ID
    expect(id, Countly.deviceIDType['TemporaryDeviceID']);

    // Get request and event queues from native side
    List<String> requestList = await getRequestQueue(); // List of strings
    expect(requestList.length, 0);
  });
}
