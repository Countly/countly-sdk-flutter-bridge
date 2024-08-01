import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// 7. Init with no device ID in config
/// A.Change device ID with merge
/// B.Change device ID without merge
/// C.Enter temporary ID mode
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('7.Old device ID methods test', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    await Countly.initWithConfig(config);

    final id = await testDeviceID(isNot('test'));
    await testDeviceIDType(DeviceIdType.SDK_GENERATED);
    await testLastRequestParams({'device_id': id});

    /// A.Change device ID with merge
    await Countly.changeDeviceId('test', true);

    await testDeviceID('test');
    await testDeviceIDType(DeviceIdType.DEVELOPER_SUPPLIED);
    await testLastRequestParams({'old_device_id': id, 'device_id': 'test'});

    await Countly.changeDeviceId('', false);

    /// B.Change device ID without merge
    await Countly.changeDeviceId('test2', false);
    await Countly.changeDeviceId('', false);

    await Countly.instance.userProfile.setOnce('test10', 'test20');
    await Countly.instance.userProfile.save();

    await testDeviceID('test2');
    await testDeviceIDType(DeviceIdType.DEVELOPER_SUPPLIED);
    await testLastRequestParams({'device_id': 'test2'});

    /// C.Enter temporary ID mode
    await Countly.changeDeviceId(Countly.deviceIDType['TemporaryDeviceID']!, false);

    await Countly.instance.userProfile.setOnce('test10', 'test20');
    await Countly.instance.userProfile.save();

    await testDeviceID(Countly.temporaryDeviceID);
    await testDeviceIDType(DeviceIdType.TEMPORARY_ID);
    await testLastRequestParams({'device_id': Countly.deviceIDType['TemporaryDeviceID']!});
  });
}
