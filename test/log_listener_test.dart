@TestOn('vm')
library log_listener_test;

import 'dart:async';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'config_test_utils.dart';

/// Sends a log message of the native SDK to the Dart side, as the platform side does.
Future<void> sendNativeLog(Map<String, Object?> arguments) async {
  final ByteData message = const StandardMethodCodec().encodeMethodCall(MethodCall('logListener', arguments));
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage('countly_flutter', message, (ByteData? reply) {});
}

/// Runs [body] and returns what it printed.
Future<List<String>> printedBy(FutureOr<void> Function() body) async {
  final List<String> printed = <String>[];
  await runZoned(body, zoneSpecification: ZoneSpecification(print: (Zone self, ZoneDelegate parent, Zone zone, String line) => printed.add(line)));
  return printed;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<String> received = <String>[];
  late Map<String, dynamic> sent;
  late List<String> printedDuringInit;

  setUpAll(() async {
    final CountlyConfig config = CountlyConfig('https://example.com', 'app_key')
      ..setLogListener((String message, LogLevel level) {
        if (message.contains('please throw')) {
          throw StateError('listener failure');
        }
        received.add('$level $message');
      });
    printedDuringInit = await printedBy(() async {
      sent = await initConfigSentFor(config);
    });
  });

  test('init tells the platform side that a log listener is set', () {
    expect(sent['logListener'], isTrue);
  });

  test('Flutter log messages reach the listener with their level while logging is disabled', () async {
    expect(received, contains('LogLevel.INFO [CountlyFlutter] "_configToJson", a log listener is provided'));
    expect(printedDuringInit, isEmpty);

    received.clear();
    final List<String> printed = await printedBy(() => Countly.log('dart message', logLevel: LogLevel.WARNING));
    expect(received, <String>['LogLevel.WARNING [CountlyFlutter] dart message']);
    expect(printed, isEmpty);
  });

  test('native log messages reach the listener with their level and add no message of their own', () async {
    received.clear();
    await sendNativeLog(<String, Object?>{'message': '[ModuleEvents] recordEventInternal, key:[test]', 'level': 'INFO'});
    await sendNativeLog(<String, Object?>{'message': '[Countly] [Verbose] native verbose line', 'level': 'VERBOSE'});
    await sendNativeLog(<String, Object?>{'message': 'line of an unknown level', 'level': 'NOT_A_LEVEL'});
    expect(received, <String>[
      'LogLevel.INFO [ModuleEvents] recordEventInternal, key:[test]',
      'LogLevel.VERBOSE [Countly] [Verbose] native verbose line',
      'LogLevel.DEBUG line of an unknown level',
    ]);
  });

  test('a throwing listener does not break logging, and its error is printed only while logging is enabled', () async {
    received.clear();
    final List<String> printedWhileDisabled = await printedBy(() => Countly.log('please throw while disabled'));
    expect(printedWhileDisabled, isEmpty);

    final List<String> printedWhileEnabled = await printedBy(() async {
      await Countly.setLoggingEnabled(true);
      Countly.log('please throw while enabled', logLevel: LogLevel.ERROR);
      Countly.log('line after the throwing one');
    });
    expect(printedWhileEnabled, contains('[CountlyFlutter] ERROR: [log] the log listener threw an error: Bad state: listener failure'));
    expect(printedWhileEnabled, contains('[CountlyFlutter] ERROR: please throw while enabled'));
    expect(received, contains('LogLevel.DEBUG [CountlyFlutter] line after the throwing one'));
  });
}
