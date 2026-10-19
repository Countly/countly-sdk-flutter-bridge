import 'dart:convert';
import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

/// With the backoff mechanism disabled, a slow server does not hold back the requests after a slow
/// response, so the queue that BM_201A keeps for over a minute is sent as fast as the server answers.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('BM_203_backoffDisabled', (WidgetTester tester) async {
    List<Map<String, List<String>>> requestArray = <Map<String, List<String>>>[];
    // The SDKs apply the developer's backoff choice once the server has sent behavior settings, so those answer at once.
    createServer(requestArray, customHandler: (HttpRequest request, Map<String, List<String>> params, HttpResponse response) async {
      response.headers.contentType = ContentType.json;
      if (params['method']?.contains('sc') ?? false) {
        response.write(jsonEncode({
          'v': 1,
          't': DateTime.now().millisecondsSinceEpoch,
          'c': {'tracking': true, 'networking': true},
        }));
        return;
      }
      await Future.delayed(const Duration(seconds: 11));
      response.write(jsonEncode({'result': 'Success'}));
    });

    CountlyConfig config = CountlyConfig(TEST_SERVER_URL, APP_KEY).enableManualSessionHandling().setLoggingEnabled(true).disableBackoffMechanism();
    await Countly.initWithConfig(config);

    Countly.instance.sessions.beginSession();
    await Future.delayed(const Duration(seconds: 2));
    Countly.instance.sessions.updateSession();
    await Future.delayed(const Duration(seconds: 2));
    Countly.instance.sessions.endSession();

    // A backoff after the first slow response would keep requests queued for 60 more seconds.
    await Future.delayed(const Duration(seconds: 70));
    final List<String> requestList = await getRequestQueue();
    final List<String> eventList = await getEventQueue();
    printQueues(requestList, eventList);
    expect(requestList, isEmpty);
    expect(eventList, isEmpty);

    expect(requestArray.where((request) => request.containsKey('begin_session')).length, 1);
    expect(requestArray.where((request) => request.containsKey('session_duration') && !request.containsKey('end_session')).length, 1);
    expect(requestArray.where((request) => request.containsKey('end_session')).length, 1);
  });
}
