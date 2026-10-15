import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math';

import 'package:countly_flutter/countly_flutter.dart' as cly;
import 'package:countly_flutter/src/web/countly_sdk_web_interop.dart';

/// Views on the web. The Web SDK runs one view at a time and ends it when the next one starts, so
/// this keeps the ID of the view it started last, and the segmentation added to every view.
class WebViews {
  /// Creates the view state with [globalSegmentation] added to every view.
  WebViews(Map<String, dynamic> globalSegmentation) : _globalSegmentation = {...globalSegmentation};

  final Random _random = Random();

  /// Segmentation added to every view this plugin starts.
  Map<String, dynamic> _globalSegmentation;

  /// The ID returned for the view started last, which the Web SDK may have ended since.
  String? _lastViewId;

  /// The name of the view started last.
  String? _lastViewName;

  /// Replaces the segmentation added to every view.
  void setGlobalSegmentation(Map<String, dynamic> segmentation) {
    _globalSegmentation = {...segmentation};
  }

  /// Adds [segmentation] to the segmentation added to every view, replacing values with the same key.
  void updateGlobalSegmentation(Map<String, dynamic> segmentation) {
    _globalSegmentation.addAll(segmentation);
  }

  /// Starts the view [name] with [segmentation] over the global segmentation, and returns its ID.
  /// The Web SDK ends the view that ran before.
  String start(CountlyWeb countly, String name, Map<String, dynamic> segmentation) {
    final Map<String, dynamic> segments = {..._globalSegmentation, ...segmentation};
    countly.track_pageview(name, null, segments.jsify());
    final String viewId = _newViewId();
    _lastViewId = viewId;
    _lastViewName = name;
    return viewId;
  }

  /// Ends the view [name] when it is the running one.
  void stopWithName(CountlyWeb countly, String name, Map<String, dynamic> segmentation) {
    if (_runningViewName(countly) != name) {
      cly.Countly.log('[CountlyFlutterPluginWeb] stopViewWithName, No running view is called [$name]', logLevel: cly.LogLevel.WARNING);
      return;
    }
    _endRunningView(countly, segmentation);
  }

  /// Ends the view with [viewId] when it is the running one.
  void stopWithId(CountlyWeb countly, String viewId, Map<String, dynamic> segmentation) {
    final String? name = _lastViewName;
    if (viewId != _lastViewId || name == null || _runningViewName(countly) != name) {
      cly.Countly.log('[CountlyFlutterPluginWeb] stopViewWithID, No running view has the ID [$viewId]', logLevel: cly.LogLevel.WARNING);
      return;
    }
    _endRunningView(countly, segmentation);
  }

  /// Ends the running view, if there is one.
  void stopAll(CountlyWeb countly, Map<String, dynamic> segmentation) {
    if (_runningViewName(countly) != null) {
      _endRunningView(countly, segmentation);
    }
  }

  /// The name of the view the Web SDK runs, or null when it runs none or cannot tell.
  String? _runningViewName(CountlyWeb countly) {
    if (!_hasInternal(countly, 'getLastView')) {
      return null;
    }
    final JSAny? name = countly.internals.getLastView();
    if (name != null && name.typeofEquals('string')) {
      return (name as JSString).toDart;
    }
    return null;
  }

  /// Ends the running view and reports its duration. The Web SDK reports only the view name with it,
  /// so [segmentation] cannot be sent.
  void _endRunningView(CountlyWeb countly, Map<String, dynamic> segmentation) {
    if (!_hasInternal(countly, 'reportViewDuration')) {
      cly.Countly.log('[CountlyFlutterPluginWeb] This Countly Web SDK version cannot end a view before the next one starts', logLevel: cly.LogLevel.WARNING);
      return;
    }
    if (segmentation.isNotEmpty) {
      cly.Countly.log('[CountlyFlutterPluginWeb] The segmentation of a stopped view is not sent on web', logLevel: cly.LogLevel.WARNING);
    }
    countly.internals.reportViewDuration();
  }

  /// Whether the Web SDK instance has the internal function [name]. These are not part of its public
  /// API, so a self-hosted Web SDK may lack them.
  bool _hasInternal(CountlyWeb countly, String name) {
    final JSAny? internals = (countly as JSObject)['_internals'];
    if (internals == null || !internals.typeofEquals('object')) {
      return false;
    }
    final JSAny? function = (internals as JSObject)[name];
    return function != null && function.typeofEquals('function');
  }

  /// A random view ID in the shape the native SDKs use.
  String _newViewId() {
    const String characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List<String>.generate(21, (int index) => characters[_random.nextInt(characters.length)]).join();
  }
}
