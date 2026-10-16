@TestOn('browser')
library remote_config_feedback_test;

import 'dart:async';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'web_test_utils.dart';

/// The remote config downloads the Web SDK requested from the server.
List<Map<String, dynamic>> remoteConfigRequests() {
  return generatedRequests().where((Map<String, dynamic> request) => (request['params'] as Map)['method'] == 'rc').toList();
}

void main() {
  setUpWebPlugin();

  test('A remote config download without its consent reports an error and requests nothing', () async {
    await Countly.initWithConfig(testConfig()
      ..setRequiresConsent(true)
      ..setConsentEnabled(['events']));

    final Completer<List<Object?>> result = Completer<List<Object?>>();
    await Countly.instance.remoteConfig.downloadAllKeys((RequestResult requestResult, String? error, bool fullValueUpdate, Map<String, RCData> downloadedValues) {
      result.complete([requestResult, error, fullValueUpdate, downloadedValues]);
    });
    final List<Object?> reply = await result.future.timeout(const Duration(seconds: 5));

    expect(reply[0], RequestResult.error);
    expect(reply[1], isNotEmpty);
    expect(reply[2], isTrue);
    expect(reply[3], isEmpty);
    expect(await Countly.instance.remoteConfig.getAllValues(), isEmpty);
    expect(remoteConfigRequests(), isEmpty);
  });

  test('A remote config download asks the server for the requested keys', () async {
    await Countly.initWithConfig(testConfig());

    await Countly.instance.remoteConfig.downloadSpecificKeys(['color', 'size']);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final Map<Object?, Object?> params = remoteConfigRequests().single['params'] as Map<Object?, Object?>;
    expect(params['keys'], '["color","size"]');
    expect(params.containsKey('omit_keys'), isFalse);
  });

  test('Feedback widgets report why they are unavailable instead of waiting', () async {
    await Countly.initWithConfig(testConfig()..enableTemporaryDeviceIDMode());

    final FeedbackWidgetsResponse widgets = await Countly.getAvailableFeedbackWidgets().timeout(const Duration(seconds: 5));
    expect(widgets.presentableFeedback, isEmpty);
    expect(widgets.error, contains('temporary device ID'));

    final CountlyPresentableFeedback unknown = CountlyPresentableFeedback('missing_id', 'nps', 'Missing');
    final String? presentResult = await Countly.presentFeedbackWidget(unknown, 'Close');
    expect(presentResult, contains('missing_id'));

    String? dataError;
    await expectLater(
      Countly.getFeedbackWidgetData(unknown, onFinished: (Map<String, dynamic> data, String? error) => dataError = error),
      anyOf(completes, throwsA(isA<PlatformException>())),
    );
    expect(dataError, contains('missing_id'));
  });
}
