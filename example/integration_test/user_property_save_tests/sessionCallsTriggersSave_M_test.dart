import 'dart:io';
import 'package:countly_flutter/countly_flutter.dart';
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

    print('RQ: $requestList');

    // Currently
    // 0- user properties: beforeBeginSession (iOS: orientation)
    // 1- begin_session (iOS: user properties: beforeBeginSession)
    // 2- orientation (iOS: begin_session)
    // 3- user properties: beforeUpdateSession
    // 4- session_duration
    // 5- user properties: beforeEndSession
    // 6- end_session
    // The orientation event: iOS SDK 26.8.1 records it once, when the SDK starts, while the SDK guide and Android record it at begin_session. iOS sends it with the recorded events before the first user properties.
    final int beforeBeginSession = Platform.isIOS ? 1 : 0;
    final int beginSession = Platform.isIOS ? 2 : 1;
    final int orientation = Platform.isIOS ? 0 : 2;
    expect(requestList.length, 7);

    testCommonRequestParams(requestList[beforeBeginSession]);
    expect(requestList[beforeBeginSession]['user_details']?[0], '{"custom":{"beforeBeginSession":true}}');

    testCommonRequestParams(requestList[beginSession]); // tests
    checkBeginSession(requestList[beginSession]);

    expect(requestList[orientation]['events']?[0].contains('[CLY]_orientation'), true);

    testCommonRequestParams(requestList[3]);
    expect(requestList[3]['user_details']?[0], '{"custom":{"beforeUpdateSession":true}}');

    testCommonRequestParams(requestList[4]);
    expect(requestList[4]['session_duration']?[0], '2');

    testCommonRequestParams(requestList[5]);
    expect(requestList[5]['user_details']?[0], '{"custom":{"beforeEndSession":true}}');

    testCommonRequestParams(requestList[6]);
    checkEndSession(requestList[6]);
  });
}
