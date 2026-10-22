import 'dart:convert';
import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

/// The global content segmentation is recorded with the events of a feedback widget reported
/// manually, the widget's own answers keep their values, and an empty map clears it. The Android
/// SDK has no global content segmentation, so there the events carry only the widget's answers.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Global content segmentation is recorded with feedback widget events', (WidgetTester tester) async {
    List<Map<String, List<String>>> requestArray = <Map<String, List<String>>>[];
    createServer(requestArray, customHandler: (HttpRequest request, Map<String, List<String>> queryParams, HttpResponse response) async {
      Object answer = {'result': 'Success'};
      if (queryParams['method']?.first == 'feedback') {
        answer = {
          'result': [
            {'_id': 'npsID', 'type': 'nps', 'name': 'NPS Feedback'}
          ]
        };
      }
      response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(answer));
    });

    await Countly.initWithConfig(CountlyConfig(TEST_SERVER_URL, APP_KEY).setLoggingEnabled(true));
    await Countly.instance.content.setGlobalContentSegmentation({'campaign': 'spring', 'rating': 9});

    FeedbackWidgetsResponse widgets = await Countly.getAvailableFeedbackWidgets();
    expect(widgets.presentableFeedback.length, 1);
    await Countly.reportFeedbackWidgetManually(widgets.presentableFeedback[0], {}, {'rating': 3, 'comment': 'ok'});
    await Future.delayed(const Duration(seconds: 2));

    await Countly.instance.content.setGlobalContentSegmentation({});
    await Countly.reportFeedbackWidgetManually(widgets.presentableFeedback[0], {}, {'rating': 4});
    await Future.delayed(const Duration(seconds: 3));

    // A request the queue sent twice carries the same events string, so each one is counted once.
    Set<String> eventBatches = <String>{};
    List<Map<String, dynamic>> npsEvents = <Map<String, dynamic>>[];
    for (Map<String, List<String>> request in requestArray) {
      String? events = request['events']?.first;
      if (events != null && eventBatches.add(events)) {
        npsEvents.addAll((jsonDecode(events) as List<dynamic>).cast<Map<String, dynamic>>().where((Map<String, dynamic> event) => event['key'] == '[CLY]_nps'));
      }
    }

    expect(npsEvents.length, 2);
    expect(npsEvents[0]['segmentation']['rating'], 3);
    expect(npsEvents[0]['segmentation']['comment'], 'ok');
    expect(npsEvents[0]['segmentation']['campaign'], Platform.isIOS ? 'spring' : isNull);
    expect(npsEvents[1]['segmentation']['rating'], 4);
    expect(npsEvents[1]['segmentation'].containsKey('campaign'), isFalse);
  });
}
