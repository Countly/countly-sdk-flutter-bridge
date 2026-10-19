import 'dart:convert';

import 'countly_flutter.dart';
import 'countly_state.dart';
import 'events.dart';

class EventsInternal implements Events {
  EventsInternal(this._countlyState);

  final CountlyState _countlyState;

  @override
  Future<void> recordEvent(String key, [Map<String, Object>? segmentation, int? count, double? sum, int? duration]) async {
    await _internalEventMethodCall(key, 'recordEvent', segmentation, count ?? 1, sum ?? 0, duration ?? 0);
  }

  @override
  Future<void> startEvent(String key) async {
    await _internalEventMethodCall(key, 'startEvent');
  }

  @override
  Future<void> endEvent(String key, [Map<String, Object>? segmentation, int? count, double? sum]) async {
    await _internalEventMethodCall(key, 'endEvent', segmentation, count ?? 1, sum ?? 0);
  }

  @override
  Future<void> cancelEvent(String key) async {
    await _internalEventMethodCall(key, 'cancelEvent');
  }

  Future<void> _internalEventMethodCall(String key, String method, [Map<String, Object>? segmentation, int? count, double? sum, int? duration]) async {
    List<Object?> args = [];

    // Another engine or an init still in flight may have initialized the native SDK, so it decides.
    if (!_countlyState.isInitialized && !await Countly.isInitialized()) {
      Countly.log('[EventsInternal] $method, "initWithConfig" must be called before "$method", ignoring the call', logLevel: LogLevel.ERROR);
      return;
    }

    Countly.log('[EventsInternal] $method, key:[$key] segmentation:[$segmentation] count:[$count] sum:[$sum] duration:[$duration]');

    if (key.isEmpty) {
      Countly.log('[EventsInternal] $method, key name is required, ignoring the call', logLevel: LogLevel.ERROR);
      return;
    }

    args.add(key);
    args.add(count?.toString());
    args.add(sum?.toString());
    args.add(duration?.toString());
    args.add(segmentation);

    final String? result = await _countlyState.channel.invokeMethod(method, <String, dynamic>{'data': json.encode(args.where((item) => item != null).toList())});
    Countly.log('[EventsInternal] $method, result:[$result]');
  }
}
