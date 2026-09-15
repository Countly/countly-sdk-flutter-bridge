import 'dart:convert';
import 'dart:io';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';
import 'view_utils.dart';

///
/// This test is to check the start parameter is only added to the first views of a session
///
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Start auto stopped views and stop views start parameter', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY);
    config.enableManualSessionHandling();
    await Countly.initWithConfig(config);

    await Countly.instance.views.startAutoStoppedView("V1");
    await Countly.instance.sessions.beginSession();
    sleep(Duration(seconds: 2));
    await Countly.instance.views.startAutoStoppedView("V2");
    await Countly.instance.sessions.endSession();
    await Countly.instance.views.startView("V3");
    await Countly.instance.sessions.beginSession();
    await Countly.instance.views.startAutoStoppedView("V4");

    List<String> requestList = await getRequestQueue();
    List<String> eventList = await getEventQueue();
    Map<String, List<String>> queryParams = Uri.parse('?${requestList[1]}').queryParametersAll;
    var rqEvents = jsonDecode(queryParams['events']![0]);

    printQueues(requestList, eventList);
    expect(4, requestList.length);
    expect(Platform.isAndroid ? 4 : 3, eventList.length);
    expect(4, rqEvents.length);

    validateBeginSessionRequest(requestList[0]); // validate begin session on 0th idx
    validateEndSessionRequest(requestList[2]); // validate end session on 1st idx
    validateBeginSessionRequest(requestList[3]); // validate begin session on 2nd idx

    int index = 0;
    validateView("V1", false, true, viewGiven: rqEvents[index++]); // begin session not called
    validateEvent("[CLY]_orientation", <String, dynamic>{'mode': 'portrait'}, eventGiven: rqEvents[index++]);
    validateView("V1", false, false, viewGiven: rqEvents[index++]); // it is because auto view
    validateView("V2", true, true, viewGiven: rqEvents[index++]); // after begin session called
    index = 0;
    validateView("V2", false, false, viewStr: eventList[index++]); // it is because auto view
    validateView("V3", false, true, viewStr: eventList[index++]); // begin session not called
    if (Platform.isAndroid) {
      validateEvent("[CLY]_orientation", <String, dynamic>{'mode': 'portrait'}, eventStr: eventList[index++]);
    }
    validateView("V4", true, true, viewStr: eventList[index++]); // after begin session called
  });
}
