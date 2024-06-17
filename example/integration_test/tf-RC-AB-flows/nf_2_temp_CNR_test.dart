import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL_RC, APP_KEY_RC).setLoggingEnabled(true).enableRemoteConfigAutomaticTriggers().remoteConfigRegisterGlobalCallback(rcCallback);
    await Countly.initWithConfig(config);
    await Future.delayed(Duration(seconds: 3));

    // no stored rc values
    var storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    var rcCount = storedRCVals.length;
    expect(storedRCVals, isA<Map<String, RCData>>());
    expect(storedRCVals.isNotEmpty, true);
    expect(rcCount, 5);

    // enter temp id mode
    Countly.changeDeviceId(Countly.deviceIDType["TemporaryDeviceID"]!, false);
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isEmpty, true);

    // enter temp id mode
    Countly.changeDeviceId(Countly.deviceIDType["TemporaryDeviceID"]!, true);
    await Future.delayed(Duration(seconds: 3));
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isEmpty, true);

    // change device id with merge
    Countly.changeDeviceId("merge_id", true);
    await Future.delayed(Duration(seconds: 3));
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals, isA<Map<String, RCData>>());
    expect(storedRCVals.isNotEmpty, true);
    expect(rcCount, 5);

    // change device id with out~ merge
    Countly.changeDeviceId("non_merge_id", false);
    await Future.delayed(Duration(seconds: 3));
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals, isA<Map<String, RCData>>());
    expect(storedRCVals.isNotEmpty, true);
    expect(rcCount, 5);
  });
}
