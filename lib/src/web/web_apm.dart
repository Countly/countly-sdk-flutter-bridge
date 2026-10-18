import 'dart:js_interop';

import 'package:countly_flutter/countly_flutter.dart' as cly;
import 'package:countly_flutter/src/web/countly_sdk_web_interop.dart';

/// Performance monitoring on the web: custom traces and network traces, reported through the Web
/// SDK's report_trace.
class WebApm {
  /// When each running custom trace started, in milliseconds since the epoch.
  final Map<String, int> _traceStarts = {};

  /// The current time in milliseconds since the epoch.
  static int _now() => DateTime.now().millisecondsSinceEpoch;

  /// Starts timing the custom trace [key], restarting it when it already runs.
  void startTrace(String key) {
    if (key.isEmpty) {
      cly.Countly.log('[CountlyFlutterPluginWeb] startTrace, The trace key must not be empty', logLevel: cly.LogLevel.ERROR);
      return;
    }
    _traceStarts[key] = _now();
  }

  /// Ends the custom trace [key] and reports its duration with [customMetrics].
  void endTrace(CountlyWeb countly, String key, Map<String, int> customMetrics) {
    final int end = _now();
    final int? start = _traceStarts.remove(key);
    if (start == null) {
      cly.Countly.log('[CountlyFlutterPluginWeb] endTrace, No trace with the key [$key] was started', logLevel: cly.LogLevel.WARNING);
      return;
    }
    _report(countly, 'device', key, start, end, {...customMetrics, 'duration': end - start});
  }

  /// Drops the custom trace [key] without reporting it.
  void cancelTrace(String key) {
    if (_traceStarts.remove(key) == null) {
      cly.Countly.log('[CountlyFlutterPluginWeb] cancelTrace, No trace with the key [$key] was started', logLevel: cly.LogLevel.WARNING);
    }
  }

  /// Drops every running custom trace without reporting them.
  void clearAllTraces() {
    _traceStarts.clear();
  }

  /// Reports a network request that took from [startTime] to [endTime], both in milliseconds since
  /// the epoch.
  void recordNetworkTrace(CountlyWeb countly, String key, int responseCode, int requestPayloadSize, int responsePayloadSize, int startTime, int endTime) {
    if (key.isEmpty) {
      cly.Countly.log('[CountlyFlutterPluginWeb] recordNetworkTrace, The trace key must not be empty', logLevel: cly.LogLevel.ERROR);
      return;
    }
    _report(countly, 'network', key, startTime, endTime, {
      'response_time': endTime - startTime,
      'response_payload_size': responsePayloadSize,
      'response_code': responseCode,
      'request_payload_size': requestPayloadSize,
    });
  }

  /// Hands a trace to the Web SDK, which sends it when the "apm" consent is given.
  void _report(CountlyWeb countly, String type, String name, int start, int end, Map<String, int> metrics) {
    countly.report_trace({'type': type, 'name': name, 'stz': start, 'etz': end, 'apm_metrics': metrics}.jsify()!);
  }
}
