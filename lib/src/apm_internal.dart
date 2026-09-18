import 'dart:convert';

import 'apm.dart';
import 'countly_flutter.dart';
import 'countly_state.dart';

class ApmInternal implements Apm {
  ApmInternal(this._countlyState);

  final CountlyState _countlyState;

  @override
  Future<String?> startTrace(String traceKey) => _sendTraceCall('startTrace', traceKey);

  @override
  Future<String?> cancelTrace(String traceKey) => _sendTraceCall('cancelTrace', traceKey);

  @override
  Future<String?> cancelAllTraces() => _sendTraceCall('clearAllTraces');

  @override
  Future<String?> setAppIsLoaded() => _sendTraceCall('appLoadingFinished');

  @override
  Future<String?> endTrace(String traceKey, [Map<String, int>? customMetrics]) async {
    final String? notReady = _countlyState.requireInit('ApmInternal', 'endTrace');
    if (notReady != null) {
      return notReady;
    }
    if (traceKey.isEmpty) {
      const String error = 'endTrace, traceKey cannot be empty';
      Countly.log('[ApmInternal] $error', logLevel: LogLevel.WARNING);
      return 'Error : $error';
    }
    Countly.log('[ApmInternal] endTrace, traceKey:[$traceKey] metrics count:[${customMetrics?.length ?? 0}]');
    final List<String> args = [traceKey];
    customMetrics?.forEach((key, value) {
      args.add(key);
      args.add(value.toString());
    });
    return _countlyState.channel.invokeMethod('endTrace', _countlyState.arguments(json.encode(args)));
  }

  @override
  Future<String?> recordNetworkTrace(String networkTraceKey, int responseCode, int requestPayloadSize, int responsePayloadSize, int startTime, int endTime) async {
    final String? notReady = _countlyState.requireInit('ApmInternal', 'recordNetworkTrace');
    if (notReady != null) {
      return notReady;
    }
    if (networkTraceKey.isEmpty) {
      const String error = 'recordNetworkTrace, networkTraceKey cannot be empty';
      Countly.log('[ApmInternal] $error', logLevel: LogLevel.WARNING);
      return 'Error : $error';
    }
    Countly.log('[ApmInternal] recordNetworkTrace, networkTraceKey:[$networkTraceKey] responseCode:[$responseCode]');
    final List<String> args = [networkTraceKey, responseCode.toString(), requestPayloadSize.toString(), responsePayloadSize.toString(), startTime.toString(), endTime.toString()];
    return _countlyState.channel.invokeMethod('recordNetworkTrace', _countlyState.arguments(json.encode(args)));
  }

  /// Sends a trace call that takes at most the trace key, and hands back what the native side reported,
  /// or the reason the call was not made.
  /// [String method]: the method channel name of the call
  /// [String? traceKey]: the trace the call is about, if the call takes one
  Future<String?> _sendTraceCall(String method, [String? traceKey]) async {
    final String? notReady = _countlyState.requireInit('ApmInternal', method);
    if (notReady != null) {
      return notReady;
    }
    if (traceKey != null && traceKey.isEmpty) {
      final String error = '$method, traceKey cannot be empty';
      Countly.log('[ApmInternal] $error', logLevel: LogLevel.WARNING);
      return 'Error : $error';
    }
    Countly.log('[ApmInternal] $method${traceKey == null ? '' : ', traceKey:[$traceKey]'}');
    return _countlyState.channel.invokeMethod(method, _countlyState.arguments(traceKey == null ? null : json.encode([traceKey])));
  }
}
