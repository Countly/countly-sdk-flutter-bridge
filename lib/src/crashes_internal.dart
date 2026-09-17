import 'dart:convert';

import 'countly_flutter.dart';
import 'countly_state.dart';
import 'crashes.dart';

class CrashesInternal implements Crashes {
  CrashesInternal(this._countlyState);

  final CountlyState _countlyState;

  /// Set from the config at init, so the global Dart error handlers know which instances asked for crashes.
  bool unhandledCrashReportingEnabled = false;

  @override
  Future<String?> recordException(String exception, bool nonfatal, [Map<String, Object>? segmentation]) async {
    final String? notReady = _countlyState.requireInit('CrashesInternal', 'logException');
    if (notReady != null) {
      return notReady;
    }
    Countly.log('[CrashesInternal] recordException, exception:[$exception] nonfatal:[$nonfatal] segmentation count:[${segmentation?.length ?? 0}]');

    final List<String> args = [exception, nonfatal.toString()];
    segmentation?.forEach((key, value) {
      args.add(key.toString());
      args.add(value.toString());
    });
    return _countlyState.channel.invokeMethod('logException', _countlyState.arguments(json.encode(args)));
  }

  @override
  Future<String?> recordError(dynamic exception, StackTrace? stacktrace, {bool nonfatal = true, Map<String, Object>? segmentation}) {
    return recordException('${exception.toString()}\n${stacktrace ?? StackTrace.current}', nonfatal, segmentation);
  }

  @override
  Future<String?> addCrashBreadcrumb(String record) async {
    final String? notReady = _countlyState.requireInit('CrashesInternal', 'addCrashLog');
    if (notReady != null) {
      return notReady;
    }
    if (record.isEmpty) {
      const String error = "addCrashLog, Can't add a null or empty crash logs";
      Countly.log('[CrashesInternal] $error', logLevel: LogLevel.WARNING);
      return 'Error : $error';
    }
    Countly.log('[CrashesInternal] addCrashBreadcrumb, record:[$record]');
    return _countlyState.channel.invokeMethod('addCrashLog', _countlyState.arguments(json.encode([record])));
  }

}
