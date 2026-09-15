import 'dart:io';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('test_eventSaveScenario_sessionCallsTriggersSave_M', (WidgetTester tester) async {
    // Initialize the SDK
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).enableManualSessionHandling().setLoggingEnabled(true);
    await Countly.initWithConfig(config); // generates 0.begin_session
    await Future.delayed(Duration(seconds: 1));

    await Countly.instance.userProfile.setProperty('beforeBeginSession', true);
    await Countly.instance.sessions.beginSession();

    await Countly.instance.userProfile.setProperty('beforeUpdateSession', true);
    await Future.delayed(Duration(seconds: 2));
    await Countly.instance.sessions.updateSession();

    await Countly.instance.userProfile.setProperty('beforeEndSession', true);
    await Future.delayed(Duration(seconds: 2)); // wait for session to end
    await Countly.instance.sessions.endSession();

    // Get request queue from native side
    List<Map<String, List<String>>> requestList = (await getRequestQueue()).map((e) => Uri.parse("?" + e).queryParametersAll).toList();

    // Currently
    // 0- user properties: beforeBeginSession
    // 1- begin_session
    // 2- orientation
    // 3- user properties: beforeUpdateSession
    // 4- session_duration
    // 5- user properties: beforeEndSession
    // 6- end_session
    expect(requestList.length, 7);

    testCommonRequestParams(requestList[0]);
    expect(requestList[0]['user_details']?[0], '{"custom":{"beforeBeginSession":${Platform.isAndroid ? '"true"' : 'true'}}}');

    testCommonRequestParams(requestList[1]); // tests
    checkBeginSession(requestList[1]);

    expect(requestList[2]['events']?[0].contains('[CLY]_orientation'), true);

    testCommonRequestParams(requestList[3]);
    expect(requestList[3]['user_details']?[0], '{"custom":{"beforeUpdateSession":${Platform.isAndroid ? '"true"' : 'true'}}}');

    testCommonRequestParams(requestList[4]);
    expect(requestList[4]['session_duration']?[0], '2');

    testCommonRequestParams(requestList[5]);
    expect(requestList[5]['user_details']?[0], '{"custom":{"beforeEndSession":${Platform.isAndroid ? '"true"' : 'true'}}}');

    testCommonRequestParams(requestList[6]);
    checkEndSession(requestList[6]);
  });
}
