import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../utils.dart';

const String _instanceA = 'instance_a';
const String _instanceB = 'instance_b';

/// Checks that named instances keep their data, device IDs and lifecycle apart from the default one.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await Countly.haltAllInstances();
  });

  testWidgets('A named instance records into its own queues', (WidgetTester tester) async {
    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true));
    final Countly namedInstance = Countly.instanceWithName(_instanceA);
    await namedInstance.initialize(CountlyConfig(SERVER_URL, '${APP_KEY}_a').setLoggingEnabled(true));

    expect(Countly.instance.isStarted, isTrue);
    expect(namedInstance.isStarted, isTrue);

    await Countly.instance.events.recordEvent('default_event');
    await namedInstance.events.recordEvent('named_event');
    await Future<void>.delayed(const Duration(seconds: 2));

    final defaultKeys = await getEventKeys();
    final namedKeys = await getEventKeys(instanceName: _instanceA);

    expect(defaultKeys, contains('default_event'));
    expect(defaultKeys, isNot(contains('named_event')));
    expect(namedKeys, contains('named_event'));
    expect(namedKeys, isNot(contains('default_event')));
  });

  testWidgets('Each instance resolves its own device ID', (WidgetTester tester) async {
    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true));
    final Countly namedInstance = Countly.instanceWithName(_instanceA);
    await namedInstance.initialize(CountlyConfig(SERVER_URL, '${APP_KEY}_a').setLoggingEnabled(true).setDeviceId('provided_a'));

    final String? defaultID = await Countly.instance.deviceId.getID();
    final String? namedID = await namedInstance.deviceId.getID();

    expect(namedID, 'provided_a');
    expect(defaultID, isNot('provided_a'));
    expect(await namedInstance.deviceId.getIDType(), DeviceIdType.DEVELOPER_SUPPLIED);
    expect(await Countly.instance.deviceId.getIDType(), DeviceIdType.SDK_GENERATED);
  });

  testWidgets('The registry hands back the same handle and lists what was created', (WidgetTester tester) async {
    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true));

    expect(Countly.getInstance(_instanceA), isNull);
    final Countly first = Countly.instanceWithName(_instanceA);
    expect(identical(Countly.instanceWithName(_instanceA), first), isTrue);
    expect(identical(Countly.getInstance(_instanceA), first), isTrue);
    expect(identical(Countly.instanceWithName(''), Countly.instance), isTrue);

    Countly.instanceWithName(_instanceB);
    expect(Countly.listInstances(), containsAll(<String>[Countly.defaultInstanceName, _instanceA, _instanceB]));

    await Countly.removeInstance(_instanceA);
    expect(Countly.getInstance(_instanceA), isNull);
    expect(Countly.listInstances(), isNot(contains(_instanceA)));

    // The default instance can not be removed, and stays usable.
    await Countly.removeInstance(Countly.defaultInstanceName);
    expect(Countly.listInstances(), contains(Countly.defaultInstanceName));
    expect(Countly.instance.isStarted, isTrue);
  });

  testWidgets('Consent is given per instance', (WidgetTester tester) async {
    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setRequiresConsent(true));
    final Countly namedInstance = Countly.instanceWithName(_instanceA);
    await namedInstance.initialize(CountlyConfig(SERVER_URL, '${APP_KEY}_a').setLoggingEnabled(true).setRequiresConsent(true));

    await namedInstance.consent.giveConsent([CountlyConsent.events]);
    await Countly.instance.events.recordEvent('default_event');
    await namedInstance.events.recordEvent('named_event');
    await Future<void>.delayed(const Duration(seconds: 2));

    final defaultKeys = await getEventKeys();
    final namedKeys = await getEventKeys(instanceName: _instanceA);

    expect(namedKeys, contains('named_event'));
    expect(defaultKeys, isNot(contains('default_event')));
  });

  testWidgets('Location, traces and attribution are recorded on the instance they are called on', (WidgetTester tester) async {
    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true));
    final Countly namedInstance = Countly.instanceWithName(_instanceA);
    await namedInstance.initialize(CountlyConfig(SERVER_URL, '${APP_KEY}_a').setLoggingEnabled(true));

    await namedInstance.location.setLocation(countryCode: 'TR', city: 'Istanbul');
    await namedInstance.apm.startTrace('named_trace');
    await namedInstance.apm.endTrace('named_trace', {'steps': 3});
    if (!kIsWeb) {
      await namedInstance.attribution.recordDirectAttribution('countly', '{"cid":"campaign_a"}');
    }
    await Future<void>.delayed(const Duration(seconds: 2));

    final namedRequests = (await getRequestQueue(instanceName: _instanceA)).map((request) => Uri.parse('?$request').queryParametersAll).toList();
    final defaultRequests = (await getRequestQueue()).map((request) => Uri.parse('?$request').queryParametersAll).toList();

    expect(namedRequests.where((params) => params.containsKey('location') || params.containsKey('city')), isNotEmpty);
    expect(namedRequests.where((params) => params.containsKey('apm')), isNotEmpty);
    if (!kIsWeb) {
      expect(namedRequests.where((params) => params.containsKey('campaign_id') || params.containsKey('attribution_data')), isNotEmpty);
    }
    expect(defaultRequests.where((params) => params.containsKey('apm')), isEmpty);
    expect(defaultRequests.where((params) => params.containsKey('campaign_id') || params.containsKey('attribution_data')), isEmpty);
  });

  testWidgets('The default instance is not affected by consent given to a named one', (WidgetTester tester) async {
    await Countly.initWithConfig(CountlyConfig(SERVER_URL, APP_KEY).setLoggingEnabled(true).setRequiresConsent(true));
    final Countly namedInstance = Countly.instanceWithName(_instanceA);
    await namedInstance.initialize(CountlyConfig(SERVER_URL, '${APP_KEY}_a').setLoggingEnabled(true).setRequiresConsent(true));

    await namedInstance.consent.giveAllConsent();
    await Countly.instance.crashes.recordException('default_crash', true);
    await namedInstance.crashes.recordException('named_crash', true);
    await Future<void>.delayed(const Duration(seconds: 2));

    final namedRequests = (await getRequestQueue(instanceName: _instanceA)).map((request) => Uri.parse('?$request').queryParametersAll).toList();
    final defaultRequests = (await getRequestQueue()).map((request) => Uri.parse('?$request').queryParametersAll).toList();

    expect(namedRequests.where((params) => params.containsKey('crash')), isNotEmpty);
    expect(defaultRequests.where((params) => params.containsKey('crash')), isEmpty);
  });
}
