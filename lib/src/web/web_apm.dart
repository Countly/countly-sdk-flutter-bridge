import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:countly_flutter/countly_flutter.dart' as cly;
import 'package:countly_flutter/src/web/countly_sdk_web_interop.dart';

/// Performance monitoring on the web: custom traces, network traces, the app start time and the time
/// the page spends in the foreground and the background. Everything is reported through the Web
/// SDK's report_trace, in the format and with the checks of the native SDKs.
class WebApm {
  /// Creates the APM state from the APM options of the Dart config. The app start is measured from
  /// [appStartOverride], in milliseconds since the epoch, or else from when the page started loading.
  WebApm({required bool trackAppStartTime, required bool manualAppLoadedTrigger, int? appStartOverride})
      : _trackAppStartTime = trackAppStartTime,
        _manualAppLoadedTrigger = manualAppLoadedTrigger,
        _appStartTimestamp = appStartOverride ?? _pageLoadStart();

  /// Metric names the server reserves for its own measurements.
  static const List<String> reservedMetricKeys = ['response_time', 'response_payload_size', 'response_code', 'request_payload_size', 'duration', 'slow_rendering_frames', 'frozen_frames'];

  /// The longest custom metric name the server accepts.
  static const int maxMetricKeyLength = 32;

  final bool _trackAppStartTime;
  final bool _manualAppLoadedTrigger;

  /// When the app started, in milliseconds since the epoch, or null when the browser does not say.
  final int? _appStartTimestamp;

  bool _appStartRecorded = false;

  /// When each running custom trace started, in milliseconds since the epoch.
  final Map<String, int> _traceStarts = {};

  /// The visibilitychange listener while foreground and background time is tracked.
  JSFunction? _visibilityListener;

  bool _inForeground = true;

  /// When the page last became visible or hidden, in milliseconds since the epoch.
  int _lastVisibilityChange = 0;

  /// The current time in milliseconds since the epoch.
  static int _now() => DateTime.now().millisecondsSinceEpoch;

  /// When the browser started loading the page, in milliseconds since the epoch, or null when the
  /// browser does not report it.
  static int? _pageLoadStart() {
    final JSAny? performance = globalContext['performance'];
    if (performance == null || !performance.typeofEquals('object')) {
      return null;
    }
    final JSAny? timeOrigin = (performance as JSObject)['timeOrigin'];
    if (timeOrigin == null || !timeOrigin.typeofEquals('number')) {
      return null;
    }
    return (timeOrigin as JSNumber).toDartDouble.round();
  }

  /// Starts timing the custom trace [key], restarting it when it already runs.
  void startTrace(String key) {
    if (key.isEmpty) {
      cly.Countly.log('[CountlyFlutterPluginWeb] startTrace, The trace key must not be empty', logLevel: cly.LogLevel.ERROR);
      return;
    }
    _traceStarts[key] = _now();
  }

  /// Ends the custom trace [key] and reports its duration with the valid ones of [customMetrics].
  void endTrace(CountlyWeb countly, String key, Map<String, int> customMetrics) {
    final int end = _now();
    final int? start = _traceStarts.remove(key);
    if (start == null) {
      cly.Countly.log('[CountlyFlutterPluginWeb] endTrace, No trace with the key [$key] was started', logLevel: cly.LogLevel.WARNING);
      return;
    }
    _report(countly, 'device', key, start, end, {'duration': end - start, ..._validMetrics(customMetrics)});
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
  /// the epoch. Values the server rejects are corrected the way the native SDKs correct them.
  void recordNetworkTrace(CountlyWeb countly, String key, int responseCode, int requestPayloadSize, int responsePayloadSize, int startTime, int endTime) {
    if (key.isEmpty) {
      cly.Countly.log('[CountlyFlutterPluginWeb] recordNetworkTrace, The trace key must not be empty', logLevel: cly.LogLevel.ERROR);
      return;
    }
    int code = responseCode;
    if (code < 100 || code >= 600) {
      cly.Countly.log('[CountlyFlutterPluginWeb] recordNetworkTrace, Invalid response code [$code], recording 0', logLevel: cly.LogLevel.ERROR);
      code = 0;
    }
    int start = startTime;
    int end = endTime;
    if (start > end) {
      cly.Countly.log('[CountlyFlutterPluginWeb] recordNetworkTrace, The end time is before the start time, swapping them', logLevel: cly.LogLevel.ERROR);
      start = endTime;
      end = startTime;
    }
    _report(countly, 'network', key, start, end, {
      'response_time': end - start,
      'response_payload_size': responsePayloadSize < 0 ? 0 : responsePayloadSize,
      'response_code': code,
      'request_payload_size': requestPayloadSize < 0 ? 0 : requestPayloadSize,
    });
  }

  /// Records the app start at init, unless the app reports itself when it finished loading.
  void recordAutomaticAppStart(CountlyWeb countly) {
    if (_trackAppStartTime && !_manualAppLoadedTrigger) {
      _recordAppStart(countly, _now());
    }
  }

  /// Records the app start now, as the app reported that it finished loading.
  void appLoaded(CountlyWeb countly) {
    if (!_manualAppLoadedTrigger) {
      cly.Countly.log('[CountlyFlutterPluginWeb] appLoadingFinished, The manual app loaded trigger is not enabled in the config', logLevel: cly.LogLevel.WARNING);
      return;
    }
    _recordAppStart(countly, _now());
  }

  /// Reports how long the app took to start, once per page load.
  void _recordAppStart(CountlyWeb countly, int loadedAt) {
    final int? start = _appStartTimestamp;
    if (!_trackAppStartTime) {
      cly.Countly.log('[CountlyFlutterPluginWeb] App start tracking is not enabled in the config', logLevel: cly.LogLevel.DEBUG);
    } else if (_appStartRecorded) {
      cly.Countly.log('[CountlyFlutterPluginWeb] The app start was already recorded', logLevel: cly.LogLevel.WARNING);
    } else if (start == null) {
      cly.Countly.log('[CountlyFlutterPluginWeb] The browser does not report when the page started loading, so the app start is not recorded', logLevel: cly.LogLevel.WARNING);
    } else if (loadedAt <= start) {
      cly.Countly.log('[CountlyFlutterPluginWeb] The app start duration is not positive, so it is not recorded', logLevel: cly.LogLevel.ERROR);
    } else {
      _report(countly, 'device', 'app_start', start, loadedAt, {'duration': loadedAt - start});
      _appStartRecorded = true;
    }
  }

  /// Reports the time the page spends visible as foreground time and hidden as background time,
  /// whenever its visibility changes.
  void startForegroundBackgroundTracking(CountlyWeb countly) {
    final JSObject document = globalContext['document'] as JSObject;
    _inForeground = _isVisible(document);
    _lastVisibilityChange = _now();
    final JSFunction listener = ((JSAny? event) {
      _onVisibilityChange(countly, document);
    }).toJS;
    _visibilityListener = listener;
    document.callMethod('addEventListener'.toJS, 'visibilitychange'.toJS, listener);
  }

  /// Stops tracking foreground and background time and drops the running custom traces.
  void stop() {
    final JSFunction? listener = _visibilityListener;
    if (listener != null) {
      (globalContext['document'] as JSObject).callMethod('removeEventListener'.toJS, 'visibilitychange'.toJS, listener);
      _visibilityListener = null;
    }
    _traceStarts.clear();
  }

  /// Reports the time since the last visibility change when the page turned visible or hidden.
  void _onVisibilityChange(CountlyWeb countly, JSObject document) {
    final bool visible = _isVisible(document);
    if (visible == _inForeground) {
      return;
    }
    final int now = _now();
    final String name = _inForeground ? 'app_in_foreground' : 'app_in_background';
    _report(countly, 'device', name, _lastVisibilityChange, now, {'duration': now - _lastVisibilityChange});
    _inForeground = visible;
    _lastVisibilityChange = now;
  }

  /// Whether [document] is visible. A browser without the Page Visibility API counts as visible.
  bool _isVisible(JSObject document) {
    final JSAny? state = document['visibilityState'];
    if (state == null || !state.typeofEquals('string')) {
      return true;
    }
    return (state as JSString).toDart != 'hidden';
  }

  /// [metrics] without the reserved names and the names the server rejects.
  Map<String, int> _validMetrics(Map<String, int> metrics) {
    final Map<String, int> valid = {};
    metrics.forEach((String key, int value) {
      if (key.isEmpty || key.length > maxMetricKeyLength) {
        cly.Countly.log('[CountlyFlutterPluginWeb] endTrace, Dropping the metric [$key]: names must have 1 to $maxMetricKeyLength characters', logLevel: cly.LogLevel.WARNING);
      } else if (reservedMetricKeys.contains(key)) {
        cly.Countly.log('[CountlyFlutterPluginWeb] endTrace, Dropping the metric [$key]: the name is reserved', logLevel: cly.LogLevel.WARNING);
      } else {
        valid[key] = value;
      }
    });
    return valid;
  }

  /// Hands a trace to the Web SDK, which sends it when the "apm" consent is given.
  void _report(CountlyWeb countly, String type, String name, int start, int end, Map<String, int> metrics) {
    countly.report_trace({'type': type, 'name': name, 'stz': start, 'etz': end, 'apm_metrics': metrics}.jsify()!);
  }
}
