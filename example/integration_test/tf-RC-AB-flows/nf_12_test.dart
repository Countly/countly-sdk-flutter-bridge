import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('rc_ab tests with CNR_AT_C', (WidgetTester tester) async {
    rcCounter = 0;
    rcCounterInternal = 0;
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL_RC, APP_KEY_RC)
      ..setLoggingEnabled(true)
      ..enableRemoteConfigAutomaticTriggers()
      ..enableRemoteConfigValueCaching()
      ..remoteConfigRegisterGlobalCallback(rcCallback);
    await Countly.initWithConfig(config);

    // check rc values
    await Future.delayed(Duration(seconds: 3));
    rcCounterInternal++;
    await getAndValidateAllRecordedRCValues();

    // ========= Consent Tests =========
    // ========= Consent Tests =========
    // ========= Consent Tests =========
    // remove all but rc consent
    await Countly.removeConsent([CountlyConsent.apm, CountlyConsent.crashes, CountlyConsent.events, CountlyConsent.location, CountlyConsent.sessions, CountlyConsent.views]);
    await getAndValidateAllRecordedRCValues();

    // remove rc consent
    await Countly.removeConsent([CountlyConsent.remoteConfig]);
    await getAndValidateAllRecordedRCValues();

    // remove all consent
    await Countly.removeAllConsent();
    await getAndValidateAllRecordedRCValues();

    // give all but rc consent
    await Countly.giveConsent([CountlyConsent.apm, CountlyConsent.crashes, CountlyConsent.events, CountlyConsent.location, CountlyConsent.sessions, CountlyConsent.views]);
    await getAndValidateAllRecordedRCValues();

    // give rc consent
    await Countly.giveConsent([CountlyConsent.remoteConfig]);
    await Future.delayed(Duration(seconds: 3));
    // rcCounterInternal++;
    await getAndValidateAllRecordedRCValues();
    // TODO: not redownload after consent change

    // get one key
    var rcVal = await Countly.instance.remoteConfig.getValue('rc_1');
    expect(rcVal.value, 'val_1');

    // remove all but rc consent~
    await Countly.removeConsent([CountlyConsent.apm, CountlyConsent.crashes, CountlyConsent.events, CountlyConsent.location, CountlyConsent.sessions, CountlyConsent.views]);
    await getAndValidateAllRecordedRCValues();

    // remove rc consent
    await Countly.removeConsent([CountlyConsent.remoteConfig]);
    // await getAndValidateAllRecordedRCValues();
    // TODO: this is failing, seems like a bug

    // give all consent
    await Countly.giveAllConsent();
    await Future.delayed(Duration(seconds: 3));
    // rcCounterInternal++;
    await getAndValidateAllRecordedRCValues();
    // TODO: not redownload after consent change

    // ========= Manual Calls Tests =========
    // ========= Manual Calls Tests =========
    // ========= Manual Calls Tests =========
    // clear all stored rc values
    await Countly.instance.remoteConfig.clearAll();
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    // update for 1 key
    await Countly.instance.remoteConfig.downloadSpecificKeys(['rc_1']);
    await Future.delayed(Duration(seconds: 3));
    rcCounterInternal++;
    var storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isNotEmpty, true);
    expect(storedRCVals.length, 1);
    expect(storedRCVals.values.first.value, 'val_1');
    expect(storedRCVals.values.first.isCurrentUsersData, true);

    // clear all stored rc values
    await Countly.instance.remoteConfig.clearAll();
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    // update for all but 1 key
    await Countly.instance.remoteConfig.downloadOmittingKeys(['rc_1']);
    await Future.delayed(Duration(seconds: 3));
    rcCounterInternal++;
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isNotEmpty, true);
    expect(storedRCVals.length, 4);
    expect(storedRCVals['rc_1'], null);

    // clear all stored rc values
    await Countly.instance.remoteConfig.clearAll();
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    // update for all rc values
    await Countly.instance.remoteConfig.downloadAllKeys();
    await Future.delayed(Duration(seconds: 3));
    rcCounterInternal++;
    await getAndValidateAllRecordedRCValues();

    // ========= Enroll/Exit Tests =========
    // ========= Enroll/Exit Tests =========
    // ========= Enroll/Exit Tests =========
    // opt out of remote config
    // await Countly.instance.remoteConfig.exitABTestsForKeys([]); //TODO: this is not working, how to exit all AB tests?
    await Countly.instance.remoteConfig.exitABTestsForKeys(['key']);
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues();
    // TODO: this is failing, seems like a bug

    // opt in to remote config
    await Countly.instance.remoteConfig.enrollIntoABTestsForKeys(['key']);
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues();
    // TODO: this is failing, seems like a bug, no redownload after opt in

    // opt out of remote
    await Countly.instance.remoteConfig.exitABTestsForKeys(['key']);
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues();
    // TODO: no redownload still

    // opt in to remote config
    await Countly.instance.remoteConfig.enrollIntoABTestsForKeys(['key']);
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues();
    // TODO: no redownload still

    await Countly.instance.remoteConfig.testingEnrollIntoABExperiment('test_periment');
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues();
    // TODO: no redownload still

    await Countly.instance.remoteConfig.testingEnrollIntoVariant('key', 'Variant A', ((rResult, error) => {expect(rResult, RequestResult.success)}));
    await Future.delayed(Duration(seconds: 3));
    rcCounterInternal++; // TODO: this fine?
    // await getAndValidateAllRecordedRCValues(); // TODO: rc erased here

    await Countly.instance.remoteConfig.testingExitABExperiment('test_periment');
    await Future.delayed(Duration(seconds: 3));
    // await getAndValidateAllRecordedRCValues(); // TODO: rc still erased
    // TODO: no redownload still

    await Countly.instance.remoteConfig.getAllValuesAndEnroll();
    await Future.delayed(Duration(seconds: 3));
    // await getAndValidateAllRecordedRCValues(); // TODO: rc still erased
    // TODO: no redownload still

    await Countly.instance.remoteConfig.getValueAndEnroll('key');
    await Future.delayed(Duration(seconds: 3));
    // await getAndValidateAllRecordedRCValues(); // TODO: rc still erased
    // TODO: no redownload still

    // ========= Device ID Tests =========
    // ========= Device ID Tests =========
    // ========= Device ID Tests =========
    // enter temp id mode
    Countly.changeDeviceId(Countly.deviceIDType["TemporaryDeviceID"]!, false);
    rcCounterInternal++; // TODO: why?
    await getAndValidateAllRecordedRCValues(isCurrentUsersData: false);

    Countly.changeDeviceId(Countly.deviceIDType["TemporaryDeviceID"]!, false);
    await getAndValidateAllRecordedRCValues(isCurrentUsersData: false);

    // TODO: this distrubs the test flow, check later
    // Countly.giveAllConsent();
    // await Future.delayed(Duration(seconds: 3));
    // storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    // expect(storedRCVals.isEmpty, true);

    // enter temp id mode
    Countly.changeDeviceId(Countly.deviceIDType["TemporaryDeviceID"]!, true);
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues(isCurrentUsersData: false);

    // change device id with merge
    Countly.changeDeviceId("merge_id", true);
    await Future.delayed(Duration(seconds: 3));
    rcCounterInternal++;
    await getAndValidateAllRecordedRCValues();

    // change device id with out~ merge
    Countly.changeDeviceId("non_merge_id", false);
    await Future.delayed(Duration(seconds: 3));
    rcCounterInternal++;
    await getAndValidateAllRecordedRCValues();

    // give consent
    await Countly.giveConsent([CountlyConsent.remoteConfig]);
    await Future.delayed(Duration(seconds: 3));
    // rcCounterInternal++;
    await getAndValidateAllRecordedRCValues();
    // TODO: no redownload still

    // change device id with merge
    Countly.changeDeviceId("merge_id", true);
    await Future.delayed(Duration(seconds: 3));
    rcCounterInternal++;
    await getAndValidateAllRecordedRCValues();

    // change device id with out~ merge
    Countly.changeDeviceId("non_merge_id", false);
    await Future.delayed(Duration(seconds: 3));
    rcCounterInternal++;
    await getAndValidateAllRecordedRCValues();

    // give consent
    await Countly.giveConsent([CountlyConsent.remoteConfig]);
    await Future.delayed(Duration(seconds: 3));
    // rcCounterInternal++;
    await getAndValidateAllRecordedRCValues();
    // TODO: no redownload still

    // ========= Variant and Experiment Tests =========
    // ========= Variant and Experiment Tests =========
    // ========= Variant and Experiment Tests =========
    // get all variants, all empty
    var variants = await Countly.instance.remoteConfig.testingGetAllVariants();
    expect(variants.isEmpty, true);

    // download variant information
    await Countly.instance.remoteConfig.testingDownloadVariantInformation((rResult, error) {
      expect(rResult, RequestResult.success);
    });
    await Future.delayed(Duration(seconds: 3));

    // get all variants, now they are here => magic
    variants = await Countly.instance.remoteConfig.testingGetAllVariants();
    var variant = await Countly.instance.remoteConfig.testingGetVariantsForKey('key');
    expect(variants.isNotEmpty, true);
    expect(variant.isNotEmpty, true);
    expect(variants['key'], ['Control group', 'Variant A', 'Variant B']);
    expect(variant, ['Control group', 'Variant A', 'Variant B']);

    // get all experiments, all empty
    var experiments = await Countly.instance.remoteConfig.testingGetAllExperimentInfo();
    expect(experiments.isEmpty, true);

    // download experiment information
    await Countly.instance.remoteConfig.testingDownloadExperimentInformation(((rResult, error) {
      expect(rResult, RequestResult.success);
    }));
    await Future.delayed(Duration(seconds: 3));

    // get all experiments, now they are here => magic
    experiments = await Countly.instance.remoteConfig.testingGetAllExperimentInfo();
    experiments.forEach((key, value) {
      expect(key, 'test_periment');
      expect(value.experimentID, 'test_periment');
      expect(value.currentVariant.isNotEmpty, true);
      expect(value.experimentDescription, 'This is and experiment for testing rc/ab features ');
      expect(value.experimentName, 'test_periment');
      expect(value.variants['Control group'], {'key': 1});
      expect(value.variants['Variant A'], {'key': 2});
      expect(value.variants['Variant B'], {'key': 3});
    });

    // ========= Callback Tests =========
    // ========= Callback Tests =========
    // ========= Callback Tests =========

    // remove a random callback
    Countly.instance.remoteConfig.removeDownloadCallback((rResult, error, fullValueUpdate, downloadedValues) {});
    await Countly.instance.remoteConfig.downloadAllKeys();
    await Future.delayed(Duration(seconds: 3));
    rcCounterInternal++;
    await getAndValidateAllRecordedRCValues();
    // our initial callback is still there

    // gester two callbacks
    Countly.instance.remoteConfig.registerDownloadCallback((rResult, error, fullValueUpdate, downloadedValues) {});
    Countly.instance.remoteConfig.registerDownloadCallback((rResult, error, fullValueUpdate, downloadedValues) {});
    await Countly.instance.remoteConfig.downloadAllKeys();
    await Future.delayed(Duration(seconds: 3));
    rcCounterInternal++;
    await getAndValidateAllRecordedRCValues();
    // our initial callback is still there, and the only one effecting the counter

    // ========= Random Methods Tests =========
    // ========= Random Methods Tests =========
    // ========= Random Methods Tests =========

    Countly.recordEvent({'key': 'value'});
    await Countly.updateSession();
    await Countly.start();
    await Countly.stop();
    await Countly.instance.sessions.beginSession();
    await Countly.instance.sessions.endSession();
    await Countly.instance.sessions.updateSession();
    await Countly.instance.views.startView('view');
    await Countly.instance.views.startView('view');
    await Countly.instance.views.stopAllViews();

    // non of above should effect the rc counter => trigger rc download
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues();
  });
}
