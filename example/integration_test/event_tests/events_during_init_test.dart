import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils.dart';

/// An event recorded right after an "initWithConfig" call that was not awaited is recorded once the
/// init finishes, and the calls made after the init keep working. The iOS plugin starts the native
/// SDK in a block it queues on the main queue, so this covers the ordering of those blocks too.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Events recorded while init runs are kept, and later calls go through', (WidgetTester tester) async {
    // Names are unique per run because the queues survive between runs on a device.
    final String run = DateTime.now().millisecondsSinceEpoch.toString();

    final Future<String?> init = Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true));
    final Future<void> event = Countly.instance.events.recordEvent('during_init_$run');
    await init;
    await event;
    await Countly.instance.views.startView('after_init_$run');

    final List<String> eventQueue = await getEventQueue();
    final List<String> requestQueue = await getRequestQueue();
    final String queued = [...eventQueue, ...requestQueue].join('\n');
    print('EQ: $eventQueue');

    expect(await Countly.isInitialized(), isTrue);
    expect(queued, contains('during_init_$run'));
    expect(queued, contains('after_init_$run'));
  });
}
