@TestOn('browser')
library content_unavailable_test;

import 'dart:async';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'web_test_utils.dart';

/// The content requests the Web SDK made so far.
int contentRequestCount() {
  return generatedRequests().where((Map<String, dynamic> request) => (request['url'] as String).endsWith('/o/sdk/content')).length;
}

void main() {
  setUpWebPlugin();

  test('The content zone fetches content on entry and on refresh, and stops on exit', () async {
    final CountlyConfig config = testConfig();
    config.content.setZoneTimerInterval(15);
    await Countly.initWithConfig(config);

    await Countly.instance.content.enterContentZone();
    // The Web SDK waits 4 seconds after init before its first content request.
    await Future<void>.delayed(const Duration(milliseconds: 4500));
    expect(contentRequestCount(), 1);

    // A refresh leaves the zone and enters it again a second later.
    await Countly.instance.content.refreshContentZone();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(contentRequestCount(), 2);

    await Countly.instance.content.exitContentZone();
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('With consent required, the content zone waits for the content consent', () async {
    final CountlyConfig config = testConfig()..setRequiresConsent(true);
    config.content.setZoneTimerInterval(15);
    await Countly.initWithConfig(config);

    await Countly.instance.content.enterContentZone();
    await Future<void>.delayed(const Duration(milliseconds: 4500));
    expect(contentRequestCount(), 0);

    await Countly.giveConsent([CountlyConsent.content]);
    for (int second = 0; second < 20 && contentRequestCount() == 0; second++) {
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    expect(contentRequestCount(), 1);

    await Countly.instance.content.exitContentZone();
  }, timeout: const Timeout(Duration(seconds: 45)));

  test('Calls the Web SDK has no equivalent for answer without failing', () async {
    await Countly.initWithConfig(testConfig());

    final String? viewId = await Countly.instance.views.startView('Paused');
    await Countly.instance.views.pauseViewWithID(viewId!);
    await Countly.instance.views.resumeViewWithID(viewId);
    await Countly.instance.views.addSegmentationToViewWithName('Paused', {'a': 1});
    await Countly.instance.content.previewContent('content_id');
    await Countly.instance.remoteConfig.clearAll();
    expect(await Countly.instance.remoteConfig.testingGetAllVariants(), isEmpty);
    expect(await Countly.instance.remoteConfig.testingGetVariantsForKey('key'), isEmpty);
    expect(await Countly.instance.remoteConfig.testingGetAllExperimentInfo(), isEmpty);

    final Completer<List<Object?>> variants = Completer<List<Object?>>();
    await Countly.instance.remoteConfig.testingDownloadVariantInformation((RequestResult result, String? error) {
      variants.complete([result, error]);
    });
    final List<Object?> reply = await variants.future.timeout(const Duration(seconds: 5));
    expect(reply[0], RequestResult.error);
    expect(reply[1], contains('not available on web'));
  });
}
