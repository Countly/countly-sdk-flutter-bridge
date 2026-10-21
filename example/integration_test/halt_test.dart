import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'utils.dart';

/// "halt", which the tests use to start every case from a clean SDK, stops the native SDK on every
/// platform, and a later init starts it again with a working event queue.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('halt stops the SDK and a later init starts it again', (WidgetTester tester) async {
    // Names are unique per run because the queues survive between runs on a device.
    final String run = DateTime.now().millisecondsSinceEpoch.toString();

    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true));
    expect(await Countly.isInitialized(), isTrue);

    await Countly.instance.halt();
    expect(await Countly.isInitialized(), isFalse);

    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true));
    await Countly.instance.events.recordEvent('after_halt_$run');

    expect(await Countly.isInitialized(), isTrue);
    expect((await getEventQueue()).join('\n'), contains('after_halt_$run'));
  });
}
