@TestOn('vm')
library init_state_test;

import 'dart:async';
import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for a native plugin and keeps every call it gets. Like the iOS plugin, it answers
/// "init" at once but starts the native SDK in a task that runs after the calls already sent.
class _FakePlatform {
  _FakePlatform({this.nativeInitialized = false, this.initFails = false});

  bool nativeInitialized;
  final bool initFails;
  final List<MethodCall> calls = <MethodCall>[];

  /// The names of the calls received so far, in order.
  List<String> get methods => calls.map((MethodCall call) => call.method).toList();

  /// The first argument the Dart side sent with the call at [index].
  Object? firstArgument(int index) {
    final Object? arguments = calls[index].arguments;
    if (arguments is Map && arguments['data'] is String) {
      return (jsonDecode(arguments['data'] as String) as List<dynamic>).first;
    }
    return null;
  }

  /// Answers a call the way the native plugin would.
  Future<Object?> handle(MethodCall call) async {
    calls.add(call);
    if (call.method == 'init') {
      if (initFails) {
        throw PlatformException(code: 'init Failed', message: 'valid context is required in Countly init');
      }
      Timer.run(() => nativeInitialized = true);
      return 'initialized.';
    }
    if (call.method == 'isInitialized') {
      return nativeInitialized ? 'true' : 'false';
    }
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakePlatform platform;

  /// Routes the Countly channel to [fake].
  void usePlatform(_FakePlatform fake) {
    platform = fake;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('countly_flutter'), fake.handle);
  }

  tearDown(() async {
    await Countly.instance.halt();
  });

  test('An event recorded right after an init that was not awaited is recorded, and the calls after init go through', () async {
    usePlatform(_FakePlatform());

    final Future<String?> init = Countly.initWithConfig(CountlyConfig('https://example.com', 'app_key'));
    final Future<void> event = Countly.instance.events.recordEvent('during_init');
    await init;
    await event;
    await Countly.instance.views.startView('home');
    await Countly.instance.userProfile.setProperty('plan', 'pro');

    expect(platform.methods, ['init', 'recordEvent', 'startView', 'userProfile_setProperty']);
    expect(platform.firstArgument(1), 'during_init');
    expect(platform.firstArgument(2), 'home');
  });

  test('In an engine whose native SDK another engine started, an event before init is recorded and init still runs', () async {
    usePlatform(_FakePlatform(nativeInitialized: true));

    await Countly.instance.events.recordEvent('from_background');
    expect(await Countly.instance.views.startView('before_init'), isNull);
    final String? result = await Countly.initWithConfig(CountlyConfig('https://example.com', 'app_key'));
    await Countly.instance.views.startView('home');

    expect(result, 'initialized.');
    expect(platform.methods, ['isInitialized', 'recordEvent', 'init', 'startView']);
    expect(platform.firstArgument(1), 'from_background');
    expect(platform.firstArgument(3), 'home');
  });

  test('Events recorded before init are dropped, and so is an event that waited for an init that failed', () async {
    usePlatform(_FakePlatform());
    await Countly.instance.events.recordEvent('too_early');
    await Countly.instance.events.startEvent('too_early_timed');
    expect(platform.methods, ['isInitialized', 'isInitialized']);

    usePlatform(_FakePlatform(initFails: true));
    final Future<String?> init = Countly.initWithConfig(CountlyConfig('https://example.com', 'app_key'));
    final Future<void> event = Countly.instance.events.recordEvent('waiting');
    await expectLater(init, throwsA(isA<PlatformException>()));
    await event;

    expect(platform.methods, ['init', 'isInitialized']);
    expect(await Countly.isInitialized(), isFalse);
  });
}
