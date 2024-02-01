import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// Goal of this test is to check if no apm configuration is set, no requests are sent to the server regarding apm
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Check no apm configuration', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    config.apm.setAppStartTimestampOverride(1620000000000); // set app start timestamp and it should be ignored
    await Countly.initWithConfig(config);

    // go foreground and background
    // TODO: this automation is Android only, iOS automation is not supported yet
    goBackgroundAndForeground();

    Countly.appLoadingFinished(); // this should be ignored

    // check if there are no apm related requests in the queue
    // should be 2 begin session and 1 end session (because we manually went to background and came back to foreground)
    // if you did not go to background and come back to foreground, there should be 1 begin session
    // and 1 orientation event if you did F/B action
    List<String> apmRequests = await getAndPrintWantedElementsWithParamFromAllQueues('apm');
    expect(apmRequests.length, 0);
  });
}
