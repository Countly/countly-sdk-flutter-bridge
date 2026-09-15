import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';
import 'sbs_utils.dart';

/// Currently it is not possible to test SCUI, we only test its value validations
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('SBS_200B_test', (WidgetTester tester) async {
    List<Map<String, List<String>>> requestArray = <Map<String, List<String>>>[];
    createServerWithConfig(requestArray, {
      'v': 1,
      't': 1750748806695,
      'c': {'tracking': false, 'scui': 1},
    });

    // Initialize the SDK
    CountlyConfig config = CountlyConfig(TEST_SERVER_URL, APP_KEY).enableManualSessionHandling().setLoggingEnabled(true);

    await Countly.initWithConfig(config);
    await Future.delayed(const Duration(seconds: 2));

    await callAllFeatures(disableSend: true);
    List<String> RQ = await getRequestQueue();
    List<String> EQ = await getEventQueue();
    expect(RQ.length, 0);
    expect(EQ.length, 0);

    await Countly.instance.attemptToSendStoredRequests();
    // check queues are empty and all requests are sent
    await Future.delayed(const Duration(seconds: 10));

    validateRequestCounts({'events': 0, 'location': 0, 'crash': 0, 'begin_session': 0, 'end_session': 0, 'session_duration': 0, 'apm': 0, 'user_details': 0, 'consent': 0}, requestArray);
    validateInternalEventCounts({}, requestArray); // 6 android
    // enter content zone is not called, but a content zone request is sent it is because server config is set cz to true
    validateImmediateCounts({'hc': 1, 'sc': 1, 'feedback': 1, 'queue': 2, 'rc': 1}, requestArray); // ab and ab_opt_out are not called because they are not immediate methods

    expect(await getServerConfig(), {
      'v': 1,
      't': 1750748806695,
      'c': {'tracking': false, 'scui': 1},
    });

    await Future.delayed(const Duration(seconds: 60));
    // wait one minute and ensure no sc requests sent
    validateImmediateCounts({'hc': 1, 'sc': 1, 'feedback': 1, 'queue': 4, 'rc': 1}, requestArray);
  });
}
