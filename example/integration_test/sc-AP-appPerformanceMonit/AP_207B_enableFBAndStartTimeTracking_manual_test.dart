import 'dart:io';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// Goal of this test is to check legacy apm configuration working correctly
/// for Android this should create 1 apm request (app_start)
/// for iOS this should create 3 apm requests (app_start, app_in_foreground, app_in_background)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Check legacy apm config', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setRecordAppStartTime(true);
    await Countly.initWithConfig(config);

    // trigger app loaded
    await Countly.appLoadingFinished();

    // go foreground and background
    // TODO: this automation is Android only, iOS automation is not supported yet
    goBackgroundAndForeground();

    // check if there is 3 apm related requests in the queue
    List<String> apmRequests = await getAndPrintWantedElementsWithParamFromAllQueues('apm');
    expect(apmRequests.length, Platform.isIOS ? 3 : 1);

    Map<String, dynamic> apmRequest_1 = await getApmParamsFromRequest(apmRequests[0]);
    expect(apmRequest_1['name'], 'app_start');

    if (Platform.isIOS) {
      Map<String, dynamic> apmRequest_2 = await getApmParamsFromRequest(apmRequests[1]);
      Map<String, dynamic> apmRequest_3 = await getApmParamsFromRequest(apmRequests[2]);
      expect(apmRequest_2['name'], 'app_in_foreground');
      expect(apmRequest_3['name'], 'app_in_background');
    }
  });
}
