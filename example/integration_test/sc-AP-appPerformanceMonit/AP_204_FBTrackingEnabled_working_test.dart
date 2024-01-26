import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

/// Goal of this test is to check if F/B tracking is working correctly
/// 2 apm requests should be sent
/// 1 for foreground and 1 for background
/// Currently this test is not automated and F/B actions should be done manually
/// TODO: automate this
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Check F/B tracking', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    config.apm.enableForegroundBackgroundTracking();
    await Countly.initWithConfig(config);

    // wait for 5 seconds. go to background manually
    print('Waiting for 5 seconds... Go background');
    await tester.pump(Duration(seconds: 5));

    // foreground apm request should be sent
    List<String> apmReqs = await getAndPrintWantedElementsWithParamFromAllQueues('apm');
    expect(apmReqs.length, 1);

    print('Waiting for 5 seconds... Back to foreground');
    await tester.pump(Duration(seconds: 5));

    // background apm request should be sent
    apmReqs = await getAndPrintWantedElementsWithParamFromAllQueues('apm');
    expect(apmReqs.length, 2);
  });
}
