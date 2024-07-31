import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// Init with no device ID in config
/// A.Enable temporary ID (new module)
/// B.Set ID (without merge - new module)
/// C.Enable temporary ID (new module)
/// D.Change ID with merge (new module)
/// E.Enable temporary ID (new module)
/// F.Change ID without merge (new module)
/// G.Enable temporary ID (old method)
/// H.Change ID with merge (old method)
/// I.Enable temporary ID (old method)
/// J.Change ID without merge (old method)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('8.Exit temporary ID mode test', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    await Countly.initWithConfig(config);
    String id = await testDeviceID(isNot('test'));
    await testDeviceIDType(DeviceIdType.SDK_GENERATED);
    await testLastRequestParams({'device_id': id});

    /// A.Enable temporary ID (new module)
    await Countly.instance.deviceId.enableTemporaryIDMode();
    await Countly.instance.userProfile.setOnce('test10', 'test20');
    await Countly.instance.userProfile.save();
    await testDeviceID(Countly.temporaryDeviceID);
    await testDeviceIDType(DeviceIdType.TEMPORARY_ID);
    await testLastRequestParams({'device_id': Countly.temporaryDeviceID});

    /// B.Set ID (without merge - new module)
    await Countly.instance.deviceId.setID('test');
    await testDeviceID('test');
    await testDeviceIDType(DeviceIdType.DEVELOPER_SUPPLIED);
    await testLastRequestParams({'old_device_id': null, 'device_id': 'test'});

    /// C.Enable temporary ID (new module)
    await Countly.instance.deviceId.enableTemporaryIDMode();
    await Countly.instance.userProfile.setOnce('test10', 'test20');
    await Countly.instance.userProfile.save();
    await testDeviceID(Countly.temporaryDeviceID);
    await testDeviceIDType(DeviceIdType.TEMPORARY_ID);
    await testLastRequestParams({'device_id': Countly.temporaryDeviceID});

    /// D.Change ID with merge (new module)
    await Countly.instance.deviceId.changeWithMerge('');
    await Countly.instance.deviceId.changeWithMerge('test');
    await Countly.instance.deviceId.changeWithMerge('');
    await testDeviceID('test');
    await testDeviceIDType(DeviceIdType.DEVELOPER_SUPPLIED);
    await testLastRequestParams({'old_device_id': null, 'device_id': 'test'});

    /// E.Enable temporary ID (new module)
    await Countly.instance.deviceId.enableTemporaryIDMode();
    await Countly.instance.userProfile.setOnce('test10', 'test20');
    await Countly.instance.userProfile.save();
    await testDeviceID(Countly.temporaryDeviceID);
    await testDeviceIDType(DeviceIdType.TEMPORARY_ID);
    await testLastRequestParams({'device_id': Countly.temporaryDeviceID});

    /// F.Change ID without merge (new module)
    await Countly.instance.deviceId.changeWithoutMerge('');
    await Countly.instance.deviceId.changeWithoutMerge('test2');
    await Countly.instance.deviceId.changeWithoutMerge('');
    await Countly.instance.userProfile.setOnce('test10', 'test20');
    await Countly.instance.userProfile.save();
    await testDeviceID('test2');
    await testDeviceIDType(DeviceIdType.DEVELOPER_SUPPLIED);
    await testLastRequestParams({'device_id': 'test2'});

    /// G.Enable temporary ID (old method)
    await Countly.changeDeviceId(Countly.deviceIDType['TemporaryDeviceID']!, false);
    await Countly.instance.userProfile.setOnce('test10', 'test20');
    await Countly.instance.userProfile.save();
    await testDeviceID(Countly.temporaryDeviceID);
    await testDeviceIDType(DeviceIdType.TEMPORARY_ID);
    await testLastRequestParams({'device_id': Countly.deviceIDType['TemporaryDeviceID']!});

    /// H.Change ID with merge (old method)
    await Countly.changeDeviceId('test', true);
    await testDeviceID('test');
    await testDeviceIDType(DeviceIdType.DEVELOPER_SUPPLIED);
    await testLastRequestParams({'old_device_id': null, 'device_id': 'test'});

    /// I.Enable temporary ID (old method)
    await Countly.changeDeviceId(Countly.deviceIDType['TemporaryDeviceID']!, false);
    await Countly.instance.userProfile.setOnce('test10', 'test20');
    await Countly.instance.userProfile.save();
    await testDeviceID(Countly.temporaryDeviceID);
    await testDeviceIDType(DeviceIdType.TEMPORARY_ID);
    await testLastRequestParams({'device_id': Countly.deviceIDType['TemporaryDeviceID']!});

    /// J.Change ID without merge (old method)
    await Countly.changeDeviceId('', false);
    await Countly.changeDeviceId('test2', false);
    await Countly.changeDeviceId('', false);
    await Countly.instance.userProfile.setOnce('test10', 'test20');
    await Countly.instance.userProfile.save();
    await testDeviceID('test2');
    await testDeviceIDType(DeviceIdType.DEVELOPER_SUPPLIED);
    await testLastRequestParams({'device_id': 'test2'});
  });
}
