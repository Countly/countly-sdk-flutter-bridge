import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// 9.Checking temporary device ID mode is correctly recognised after init if set with "setId"
/// This would make sure that temp ID mode is verified mainly with the id string value
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('9.Checking temporary device ID mode is correctly recognised after init if set with "setId"', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setDeviceId('test');
    await Countly.initWithConfig(config);

    // Get the device ID type
    String? id = await Countly.instance.deviceId.getID();
    DeviceIdType? type = await Countly.instance.deviceId.getIDType();
    // Verify the device ID type
    expect(id, 'test');
    expect(type, isNot(DeviceIdType.TEMPORARY_ID));

    await Countly.instance.deviceId.setID('');
    // Get the device ID type
    String? id1 = await Countly.instance.deviceId.getID();
    DeviceIdType? type1 = await Countly.instance.deviceId.getIDType();
    // Verify the device ID type
    expect(id1, 'test');
    expect(type1, isNot(DeviceIdType.TEMPORARY_ID));

    await Countly.instance.deviceId.setID('ff');
    // Get the device ID type
    String? id2 = await Countly.instance.deviceId.getID();
    DeviceIdType? type2 = await Countly.instance.deviceId.getIDType();
    // Verify the device ID type
    expect(id2, 'ff');
    expect(type2, isNot(DeviceIdType.TEMPORARY_ID));

    await Countly.instance.deviceId.setID('12');
    // Get the device ID type
    String? id3 = await Countly.instance.deviceId.getID();
    DeviceIdType? type3 = await Countly.instance.deviceId.getIDType();
    // Verify the device ID type
    expect(id3, '12');
    expect(type3, isNot(DeviceIdType.TEMPORARY_ID));

    await Countly.instance.deviceId.setID('34');
    // Get the device ID type
    String? id4 = await Countly.instance.deviceId.getID();
    DeviceIdType? type4 = await Countly.instance.deviceId.getIDType();
    // Verify the device ID type
    expect(id4, '34');
    expect(type4, isNot(DeviceIdType.TEMPORARY_ID));

    await Countly.instance.deviceId.setID(Countly.deviceIDType['TemporaryDeviceID']!);
    // Get the device ID type
    String? id5 = await Countly.instance.deviceId.getID();
    DeviceIdType? type5 = await Countly.instance.deviceId.getIDType();
    // Verify the device ID type
    expect(id5, Countly.deviceIDType['TemporaryDeviceID']!);
    expect(type5, DeviceIdType.TEMPORARY_ID);
  });
}
