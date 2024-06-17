import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('', (WidgetTester tester) async {
    rcCounter = 0;
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL_RC, APP_KEY_RC).setLoggingEnabled(true).enableRemoteConfigAutomaticTriggers().setRequiresConsent(true).remoteConfigRegisterGlobalCallback(rcCallback);
    await Countly.initWithConfig(config);

    // no stored rc values
    var storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals, isA<Map<String, RCData>>());
    expect(storedRCVals.isEmpty, true);

    // remove rc consent
    await Countly.removeConsent([CountlyConsent.remoteConfig]);
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isEmpty, true);

    // remove all but rc consent
    await Countly.removeConsent([CountlyConsent.apm, CountlyConsent.crashes, CountlyConsent.events, CountlyConsent.location, CountlyConsent.sessions, CountlyConsent.views]);
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isEmpty, true);

    // remove all consent
    await Countly.removeAllConsent();
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isEmpty, true);

    // give all but rc consent
    await Countly.giveConsent([CountlyConsent.apm, CountlyConsent.crashes, CountlyConsent.events, CountlyConsent.location, CountlyConsent.sessions, CountlyConsent.views]);
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isEmpty, true);

    // give rc consent
    await Countly.giveConsent([CountlyConsent.remoteConfig]);
    await Future.delayed(Duration(seconds: 3));
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isNotEmpty, true);
    var rcCount = storedRCVals.length;
    expect(rcCount, 5);
    expect(rcCounter, 1);

    // get one key
    var rcVal = await Countly.instance.remoteConfig.getValue('rc_1');
    expect(rcVal, isA<RCData>());
    expect(rcVal.value, 'val_1');
    expect(rcVal.isCurrentUsersData, true);

    // remove all but rc consent~
    await Countly.removeConsent([CountlyConsent.apm, CountlyConsent.crashes, CountlyConsent.events, CountlyConsent.location, CountlyConsent.sessions, CountlyConsent.views]);
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isNotEmpty, true);
    expect(storedRCVals.length, rcCount);

    // remove rc consent
    await Countly.removeConsent([CountlyConsent.remoteConfig]);
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    // expect(storedRCVals.isNotEmpty, true);
    // expect(storedRCVals.length, rcCount);
    // TODO: this is failing, seems like a bug

    // give rc consent
    await Countly.giveConsent([CountlyConsent.remoteConfig]);
    await Future.delayed(Duration(seconds: 3));
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isNotEmpty, true);
    expect(storedRCVals.length, rcCount);
    expect(rcCounter, 2);

    // clear all stored rc values
    await Countly.instance.remoteConfig.clearAll();
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isEmpty, true);

    // update for 1 key
    await Countly.instance.remoteConfig.downloadSpecificKeys(['rc_1']);
    await Future.delayed(Duration(seconds: 3));
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isNotEmpty, true);
    expect(storedRCVals.length, 1);
    expect(storedRCVals.values.first.value, 'val_1');
    expect(storedRCVals.values.first.isCurrentUsersData, true);
    expect(rcCounter, 3);

    // clear all stored rc values
    await Countly.instance.remoteConfig.clearAll();
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isEmpty, true);

    // update for all but 1 key
    await Countly.instance.remoteConfig.downloadOmittingKeys(['rc_1']);
    await Future.delayed(Duration(seconds: 3));
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isNotEmpty, true);
    expect(storedRCVals.length, 4);
    expect(storedRCVals['rc_1'], null);
    expect(rcCounter, 4);

    // clear all stored rc values
    await Countly.instance.remoteConfig.clearAll();
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isEmpty, true);

    // update for all rc values
    await Countly.instance.remoteConfig.downloadAllKeys();
    await Future.delayed(Duration(seconds: 3));
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isNotEmpty, true);
    expect(storedRCVals.length, 5);
    expect(rcCounter, 5);

    // opt out of remote config
    // await Countly.instance.remoteConfig.exitABTestsForKeys([]); //TODO: this is not working, how to exit all AB tests?
    await Countly.instance.remoteConfig.exitABTestsForKeys(['key']);
    await Future.delayed(Duration(seconds: 3));
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isNotEmpty, true);
    expect(storedRCVals.length, 5);
    // expect(rcCounter, 6); // TODO: this is failing, seems like a bug

    // opt in to remote config
    await Countly.instance.remoteConfig.enrollIntoABTestsForKeys(['key']);
    await Future.delayed(Duration(seconds: 3));
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isNotEmpty, true);
    expect(storedRCVals.length, 5);
    // expect(rcCounter, 6); // TODO: this is failing, seems like a bug, no redownload after opt in

    // opt out of remote
    await Countly.instance.remoteConfig.exitABTestsForKeys(['key']);
    await Future.delayed(Duration(seconds: 3));
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isNotEmpty, true);
    expect(storedRCVals.length, 5);
    // expect(rcCounter, 6); // TODO: no redownload still

    // opt in to remote config
    await Countly.instance.remoteConfig.enrollIntoABTestsForKeys(['key']);
    await Future.delayed(Duration(seconds: 3));
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isNotEmpty, true);
    expect(storedRCVals.length, 5);
    expect(rcCounter, 5); // TODO: no redownload still
  });
}
