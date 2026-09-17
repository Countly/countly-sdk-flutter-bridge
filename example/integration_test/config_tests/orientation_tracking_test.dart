import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';
import '../web_utils_stub.dart' if (dart.library.html) '../web_utils.dart';

/// Checks that orientation reporting can be turned off, and stays on by default.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await Countly.instance.halt();
    clearWebLocalStorage();
  });

  testWidgets('Orientation reporting is off when it is disabled', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setTrackOrientationChanges(false);
    await Countly.initWithConfig(config);

    await Countly.instance.views.startAutoStoppedView('orientationOff');
    await Future.delayed(const Duration(seconds: 2));

    final keys = await getEventKeys();
    expect(keys, isNot(contains('[CLY]_orientation')));
    expect(keys, contains('[CLY]_view'));
  });

  testWidgets('Orientation reporting is on by default', (WidgetTester tester) async {
    CountlyConfig config = CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true);
    await Countly.initWithConfig(config);

    await Countly.instance.views.startAutoStoppedView('orientationOn');
    await Future.delayed(const Duration(seconds: 2));

    final keys = await getEventKeys();
    expect(keys, contains('[CLY]_orientation'));
  });
}
