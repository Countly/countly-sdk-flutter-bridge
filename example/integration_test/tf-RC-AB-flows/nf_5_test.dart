import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('rc_ab tests with CR_CNG', (WidgetTester tester) async {
    rcCounter = 0;
    rcCounterInternal = 0;
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL_RC, APP_KEY_RC)
      ..setLoggingEnabled(true)
      ..setRequiresConsent(true)
      ..remoteConfigRegisterGlobalCallback(rcCallback);
    await Countly.initWithConfig(config);

    // check rc values
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    // ========= Consent Tests =========
    await testConsentForRC(isCG: false);

    // ========= Manual Calls Tests =========
    // ========= Manual Calls Tests =========
    // ========= Manual Calls Tests =========
    // clear all stored rc values
    await Countly.instance.remoteConfig.clearAll();
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    // update for 1 key
    await Countly.instance.remoteConfig.downloadSpecificKeys(['rc_1']);
    await Future.delayed(Duration(seconds: 3));
    var storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isEmpty, true);

    // clear all stored rc values
    await Countly.instance.remoteConfig.clearAll();
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    // update for all but 1 key
    await Countly.instance.remoteConfig.downloadOmittingKeys(['rc_1']);
    await Future.delayed(Duration(seconds: 3));
    storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    expect(storedRCVals.isEmpty, true);

    // clear all stored rc values
    await Countly.instance.remoteConfig.clearAll();
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    // update for all rc values
    await Countly.instance.remoteConfig.downloadAllKeys();
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    // ========= Enroll/Exit Tests =========
    // ========= Enroll/Exit Tests =========
    // ========= Enroll/Exit Tests =========
    // opt out of remote config
    // await Countly.instance.remoteConfig.exitABTestsForKeys([]); //TODO: this is not working, how to exit all AB tests?
    await Countly.instance.remoteConfig.exitABTestsForKeys(['key']);
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    // opt in to remote config
    await Countly.instance.remoteConfig.enrollIntoABTestsForKeys(['key']);
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    // opt out of remote
    await Countly.instance.remoteConfig.exitABTestsForKeys(['key']);
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    // opt in to remote config
    await Countly.instance.remoteConfig.enrollIntoABTestsForKeys(['key']);
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    await Countly.instance.remoteConfig.testingEnrollIntoABExperiment('test_periment');
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    await Countly.instance.remoteConfig.testingEnrollIntoVariant('key', 'Variant A', ((rResult, error) => {expect(rResult, RequestResult.success)}));
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    await Countly.instance.remoteConfig.testingExitABExperiment('test_periment');
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    await Countly.instance.remoteConfig.getAllValuesAndEnroll();
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    await Countly.instance.remoteConfig.getValueAndEnroll('key');
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    // ========= Device ID Tests =========
    // ========= Device ID Tests =========
    // ========= Device ID Tests =========
    // enter temp id mode
    Countly.changeDeviceId(Countly.deviceIDType["TemporaryDeviceID"]!, false);
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    // TODO: this distrubs the test flow, check later
    // Countly.giveAllConsent();
    // await Future.delayed(Duration(seconds: 3));
    // storedRCVals = await Countly.instance.remoteConfig.getAllValues();
    // expect(storedRCVals.isEmpty, true);

    // enter temp id mode
    Countly.changeDeviceId(Countly.deviceIDType["TemporaryDeviceID"]!, true);
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    // change device id with merge
    Countly.changeDeviceId("merge_id", true);
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    // enter temp id mode
    Countly.changeDeviceId(Countly.deviceIDType["TemporaryDeviceID"]!, true);
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    // change device id with out~ merge
    Countly.changeDeviceId("non_merge_id", false);
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    // give consent
    await Countly.giveConsent([CountlyConsent.remoteConfig]);
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    // change device id with merge
    Countly.changeDeviceId("merge_id", true);
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues(isEmpty: true);

    // change device id with out~ merge
    Countly.changeDeviceId("non_merge_id", false);
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues(isEmpty: true);

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
    expect(variants.isEmpty, true);
    expect(variant.isEmpty, true);

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
    expect(experiments.isEmpty, true);

    // ========= Callback Tests =========
    // ========= Callback Tests =========
    // ========= Callback Tests =========

    // remove a random callback
    Countly.instance.remoteConfig.removeDownloadCallback((rResult, error, fullValueUpdate, downloadedValues) {});
    await Countly.instance.remoteConfig.downloadAllKeys();
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues(isEmpty: true);
    // our initial callback is still there

    // gester two callbacks
    Countly.instance.remoteConfig.registerDownloadCallback((rResult, error, fullValueUpdate, downloadedValues) {});
    Countly.instance.remoteConfig.registerDownloadCallback((rResult, error, fullValueUpdate, downloadedValues) {});
    await Countly.instance.remoteConfig.downloadAllKeys();
    await Future.delayed(Duration(seconds: 3));
    await getAndValidateAllRecordedRCValues(isEmpty: true);
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
    await getAndValidateAllRecordedRCValues(isEmpty: true);
  });
}
