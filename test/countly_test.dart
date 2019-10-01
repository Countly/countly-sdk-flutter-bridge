import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:countly/countly.dart';

void main() {
  const MethodChannel channel = MethodChannel('countly');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('start', () async {
    expect(await Countly.start(), '42');
  });
}
