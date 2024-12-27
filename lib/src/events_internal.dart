import 'dart:convert';

import 'countly_flutter.dart';
import 'countly_state.dart';
import 'events.dart';

class EventsInternal implements Events {
  EventsInternal(this._countlyState);

  final CountlyState _countlyState;

  @override
  Future<String?> recordEvent(String key, [Map<String, Object>? segmentation, int? count, double? sum, int? duration]) async {
    return _internalEventMethodCall(key, 'recordEvent', segmentation, count ?? 1, sum ?? 0, duration ?? 0);
  }

  @override
  Future<String?> startEvent(String key) async {
    return _internalEventMethodCall(key, 'startEvent');
  }

  @override
  Future<String?> endEvent(String key, [Map<String, Object>? segmentation, int? count, double? sum]) async {
    return _internalEventMethodCall(key, 'endEvent', segmentation, count ?? 1, sum ?? 0);
  }

  @override
  Future<String?> cancelEvent(String key) async {
    return _internalEventMethodCall(key, 'cancelEvent');
  }

  Future<String?> _internalEventMethodCall(String key, String method, [Map<String, Object>? segmentation, int? count, double? sum, int? duration]) async {
    List<Object?> args = [];

    if (!_countlyState.isInitialized) {
      String message = '"initWithConfig" must be called before "$method"';
      Countly.log('[EventsInternal] $method, $message', logLevel: LogLevel.ERROR);
      return message;
    }

    Countly.log('[EventsInternal] $method, key:[$key] segmentation:[$segmentation] count:[$count] sum:[$sum] duration:[$duration]');

    if (key.isEmpty) {
      String error = '$method, key name is required';
      Countly.log('[EventsInternal] $method, $error');
      return 'Error : $error';
    }

    args.add(key);
    args.add(count?.toString());
    args.add(sum?.toString());
    args.add(duration?.toString());
    args.add(segmentation);

    final String? result = await _countlyState.channel.invokeMethod(method, <String, dynamic>{'data': json.encode(args.where((item) => item != null).toList())});

    return result;
  }
}
