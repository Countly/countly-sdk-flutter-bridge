import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:countly_flutter/countly_state.dart';

class ViewsInternal implements Views {
  ViewsInternal(this._cly, this._countlyState);
  final Countly _cly;
  final CountlyState _countlyState;

  @override
  Future<void> stopViewWithId(String viewID, [Map<String, Object> segmentation = const {}]) async {
    if (!_countlyState.isInitialized) {
      Countly.log('views_stopViewWithId, "initWithConfig" must be called before "views_stopViewWithId"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "views_stopViewWithId"');
    final List<Object> args = [];
    args.add(viewID);
    args.add(segmentation);
    await _countlyState.channel.invokeMethod('stopViewWithId', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> stopViewWithName(String viewName, [Map<String, Object> segmentation = const {}]) async {
    if (!_countlyState.isInitialized) {
      Countly.log('views_stopViewWithName, "initWithConfig" must be called before "views_stopViewWithName"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "views_stopViewWithName"');
    final List<Object> args = [];
    args.add(viewName);
    args.add(segmentation);
    await _countlyState.channel.invokeMethod('stopViewWithName', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<String?> startView(String viewName, [Map<String, Object> segmentation = const {}]) async {
    if (!_countlyState.isInitialized) {
      Countly.log('views_startView, "initWithConfig" must be called before "views_startView"', logLevel: LogLevel.ERROR);
      return null;
    }
    Countly.log('Calling "views_startView"');
    final List<Object> args = [];
    args.add(viewName);
    args.add(segmentation);
    final String viewId = await _countlyState.channel.invokeMethod('startView', <String, dynamic>{'data': json.encode(args)});
    return viewId;
  }

  @override
  Future<void> setGlobalViewSegmentation(Map<String, Object> segmentation) async {
    if (!_countlyState.isInitialized) {
      Countly.log('views_setGlobalViewSegmentation, "initWithConfig" must be called before "views_setGlobalViewSegmentation"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "views_setGlobalViewSegmentation"');
    final List<Object> args = [];
    args.add(segmentation);
    await _countlyState.channel.invokeMethod('setGlobalViewSegmentation', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> updateGlobalViewSegmentation(Map<String, Object> segmentation) async {
    if (!_countlyState.isInitialized) {
      Countly.log('views_updateGlobalViewSegmentation, "initWithConfig" must be called before "views_updateGlobalViewSegmentation"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "views_updateGlobalViewSegmentation"');
    final List<Object> args = [];
    args.add(segmentation);
    await _countlyState.channel.invokeMethod('updateGlobalViewSegmentation', <String, dynamic>{'data': json.encode(args)});
  }
}
