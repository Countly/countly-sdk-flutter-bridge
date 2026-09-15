import 'dart:convert';
import 'dart:io';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('test_eventSaveScenario_sessionCallsTriggersSave_A', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setUserProperties({'beforeBeginSession': true}).setUpdateSessionTimerDelay(3);
    await Countly.initWithConfig(config); // generates 0.begin_session
    await Future.delayed(Duration(seconds: 1));

    await Countly.instance.userProfile.setProperty('beforeUpdateSession', true);
    await Future.delayed(Duration(seconds: 2));

    await Countly.instance.userProfile.setProperty('beforeEndSession', true);
    FlutterForegroundTask.minimizeApp(); // go to background
    await Future.delayed(Duration(seconds: 2)); // wait for session to end

    // Get request queue from native side
    List<Map<String, List<String>>> requestList = (await getRequestQueue()).map((e) => Uri.parse("?" + e).queryParametersAll).toList();

    // Currently
    // 0- user properties: beforeBeginSession
    // 1- begin_session
    // 2- user properties: beforeUpdateSession
    // 3- session_duration
    // 4- user properties: beforeEndSession
    // 5- end_session
    expect(requestList.length, Platform.isAndroid ? 7 : 6);

    testCommonRequestParams(requestList[0]);
    expect(requestList[0]['user_details']?[0], '{"custom":{"beforeBeginSession":true}}');

    testCommonRequestParams(requestList[1]); // tests
    checkBeginSession(requestList[1]);

    int i = 2;
    if (Platform.isAndroid) {
      expect(requestList[i]['events']?[0].contains('[CLY]_orientation'), true);
      i++;
    }

    testCommonRequestParams(requestList[i]);
    expect(requestList[i]['user_details']?[0], '{"custom":{"beforeUpdateSession":${Platform.isAndroid ? '"true"' : 'true'}}}');
    i++;

    testCommonRequestParams(requestList[i]);
    expect(requestList[i]['session_duration']?[0], '3');
    i++;

    testCommonRequestParams(requestList[i]);
    expect(requestList[i]['user_details']?[0], '{"custom":{"beforeEndSession":${Platform.isAndroid ? '"true"' : 'true'}}}');
    i++;

    testCommonRequestParams(requestList[i]);
    checkEndSession(requestList[i]);
  });
}
