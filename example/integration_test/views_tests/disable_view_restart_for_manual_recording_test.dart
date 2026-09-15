import 'dart:convert';
import 'dart:io';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';
import 'view_utils.dart';

///
/// This test verifies that when disableViewRestartForManualRecording is enabled,
/// manual views are NOT stopped and restarted when the app goes to background
/// and returns to foreground.
///
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Background and foreground with manual view restart disabled', (WidgetTester tester) async {
    // Initialize the SDK with disableViewRestartForManualRecording
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    config.disableViewRestartForManualRecording();
    await Countly.initWithConfig(config);

    await Countly.instance.views.startView("View1");

    goBackgroundAndForeground();

    // With disableViewRestartForManualRecording, View1 should NOT be ended or restarted
    List<String> requestList = await getRequestQueue();
    List<String> eventList = await getEventQueue();

    printQueues(requestList, eventList);

    // REQUESTS: begin session, events (View1 start only), end session
    // Android also gets a foreground begin session
    expect(requestList.length, Platform.isAndroid ? 4 : 3);

    validateBeginSessionRequest(requestList[0]);

    // Validate flushed events contain View1 start but NO View1 end
    Map<String, List<String>> queryParams = Uri.parse('?${requestList[1]}').queryParametersAll;
    var rqEvents = jsonDecode(queryParams['events']![0]);
    expect(rqEvents.length, Platform.isAndroid ? 2 : 1);

    int index = 0;
    if (Platform.isAndroid) {
      validateEvent("[CLY]_orientation", <String, dynamic>{'mode': 'portrait'}, eventGiven: rqEvents[index++]);
    }
    // View1 start: first view of session so start=true, visit=true
    validateView("View1", true, true, viewGiven: rqEvents[index++]);

    validateEndSessionRequest(requestList[2]);
    if (Platform.isAndroid) {
      validateBeginSessionRequest(requestList[3]);
    }

    // Event queue should contain no view events
    for (String eventStr in eventList) {
      Map<String, dynamic> event = jsonDecode(eventStr);
      expect(event['key'], isNot('[CLY]_view'), reason: 'No view events should be queued after bg/fg with restart disabled');
    }
    if (Platform.isAndroid) {
      expect(eventList.length, 1);
      validateEvent("[CLY]_orientation", <String, dynamic>{'mode': 'portrait'}, eventStr: eventList[0]);
    } else {
      expect(eventList.length, 0);
    }
  });
}
