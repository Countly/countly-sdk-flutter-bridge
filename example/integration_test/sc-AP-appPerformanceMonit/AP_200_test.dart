import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// Goal of this test is to check if no apm configuration is set, no requests are sent to the server regarding apm
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Check no apm configuration', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    // set no apm config options
    await Countly.initWithConfig(config);

    // wait for 5 seconds. Go to background and come back to foreground manually.
    // TODO(turtledreams): automate this
    print('Waiting for 5 seconds...');
    await tester.pump(Duration(seconds: 5));

    // check if there are no apm related requests in the queue
    // should be 2 begin session and 1 end session (because we manually went to background and came back to foreground)
    // if you did not go to background and come back to foreground, there should be 1 begin session
    // and 1 orientation event if you did F/B action
    List<String> apmRequests = await getAndPrintWantedElementsWithParamFromAllQueues('apm');
    expect(apmRequests.length, 0);
  });
}
