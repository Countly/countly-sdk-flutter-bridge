import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// 9.Checking that temporary device ID mode works from setID
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('9.Checking that temporary device ID mode works from setID', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setDeviceId('test');
    await Countly.initWithConfig(config);

    await Countly.instance.deviceId.setID(Countly.deviceIDType['TemporaryDeviceID']!);
    final requestList = await getRequestQueue();
    await Countly.recordEvent({'key': 'Basic Event', 'count': 1});

    // Get the device ID type
    String? id1 = await Countly.instance.deviceId.getID();
    DeviceIdType? type1 = await Countly.instance.deviceId.getIDType();
    // Verify the device ID type
    expect(id1, Countly.deviceIDType['TemporaryDeviceID']!);
    expect(type1, DeviceIdType.TEMPORARY_ID);

    final requestList1 = await getRequestQueue();
    expect(requestList, requestList1);
  });
}
