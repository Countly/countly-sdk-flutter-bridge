import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';
import 'dart:io';

/// Goal of this test is to check if F/B tracking is working correctly
/// 2 apm requests should be sent
/// 1 for foreground and 1 for background
/// Currently this test is not automated and F/B actions should be done manually
/// TODO: automate this for iOS
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Check F/B tracking', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    config.apm.enableForegroundBackgroundTracking();
    await Countly.initWithConfig(config);

    // go foreground and background
    // TODO: this automation is Android only, iOS automation is not supported yet
    FlutterForegroundTask.minimizeApp();
    if (Platform.isIOS) {
      printMessageMultipleTimes('will now go to background, get ready to go foreground manually', 3);
    }
    await tester.pump(Duration(seconds: 3));

    // foreground apm request should be sent
    List<String> apmReqs = await getAndPrintWantedElementsWithParamFromAllQueues('apm');
    expect(apmReqs.length, 1);

    FlutterForegroundTask.launchApp();
    if (Platform.isIOS) {
      printMessageMultipleTimes('waiting for 3 seconds, now go to foreground', 3);
    }
    await tester.pump(Duration(seconds: 3));

    // background apm request should be sent
    apmReqs = await getAndPrintWantedElementsWithParamFromAllQueues('apm');
    expect(apmReqs.length, 2);
  });
}
