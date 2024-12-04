import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// 6. Init with no device ID in config
/// set ID (with merge)
/// set ID (without merge)
/// enter temporary ID mode
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('6.Device ID interface test', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    await Countly.initWithConfig(config);

    final id = await testDeviceID(isNot('test'));
    await testDeviceIDType(DeviceIdType.SDK_GENERATED);
    await testLastRequestParams({'device_id': id});

    await Countly.instance.deviceId.setID('test');
    
    await testDeviceID('test');
    await testDeviceIDType(DeviceIdType.DEVELOPER_SUPPLIED);
    await testLastRequestParams({'old_device_id': id, 'device_id': 'test'});

    await Countly.instance.deviceId.setID('');
    await Countly.instance.deviceId.setID('test2');
    await Countly.instance.deviceId.setID('');

    await Countly.instance.userProfile.setOnce('test10', 'test20');
    await Countly.instance.userProfile.save();

    await testDeviceID('test2');
    await testDeviceIDType(DeviceIdType.DEVELOPER_SUPPLIED);
    await testLastRequestParams({'device_id': 'test2'});

    await Countly.instance.deviceId.changeWithMerge('');
    await Countly.instance.deviceId.changeWithMerge('test');
    await Countly.instance.deviceId.changeWithMerge('');

    await testDeviceID('test');
    await testDeviceIDType(DeviceIdType.DEVELOPER_SUPPLIED);
    await testLastRequestParams({'old_device_id': 'test2', 'device_id': 'test'});

    await Countly.instance.deviceId.changeWithoutMerge('');
    await Countly.instance.deviceId.changeWithoutMerge('test2');
    await Countly.instance.deviceId.changeWithoutMerge('');

    await Countly.instance.userProfile.setOnce('test10', 'test20');
    await Countly.instance.userProfile.save();

    await testDeviceID('test2');
    await testDeviceIDType(DeviceIdType.DEVELOPER_SUPPLIED);
    await testLastRequestParams({'device_id': 'test2'});

    await Countly.instance.deviceId.enableTemporaryIDMode();

    await Countly.instance.userProfile.setOnce('test10', 'test20');
    await Countly.instance.userProfile.save();

    await testDeviceID(Countly.temporaryDeviceID);
    await testDeviceIDType(DeviceIdType.TEMPORARY_ID);
    await testLastRequestParams({'device_id': Countly.temporaryDeviceID});
  });
}
