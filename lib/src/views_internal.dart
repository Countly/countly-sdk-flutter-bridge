import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:countly_flutter/src/countly_state.dart';

class ViewsInternal implements Views {
  ViewsInternal(this._countlyState);
  final CountlyState _countlyState;

  @override
  Future<void> stopViewWithID(String viewID, [Map<String, Object> segmentation = const {}]) async {
    if (!_countlyState.isInitialized) {
      Countly.log('[Views] stopViewWithID, "initWithConfig" must be called before "[Views] stopViewWithID"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "[Views] stopViewWithID"');
    final List<Object> args = [];
    args.add(viewID);
    args.add(segmentation);
    await _countlyState.channel.invokeMethod('stopViewWithID', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> stopViewWithName(String viewName, [Map<String, Object> segmentation = const {}]) async {
    if (!_countlyState.isInitialized) {
      Countly.log('[Views] stopViewWithName, "initWithConfig" must be called before "[Views] stopViewWithName"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "[Views] stopViewWithName"');
    final List<Object> args = [];
    args.add(viewName);
    args.add(segmentation);
    await _countlyState.channel.invokeMethod('stopViewWithName', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> pauseViewWithID(String viewID, [Map<String, Object> segmentation = const {}]) async {
    if (!_countlyState.isInitialized) {
      Countly.log('[Views] pauseViewWithID, "initWithConfig" must be called before "[Views] pauseViewWithID"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "[Views] pauseViewWithID"');
    final List<Object> args = [];
    args.add(viewID);
    args.add(segmentation);
    await _countlyState.channel.invokeMethod('pauseViewWithID', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> resumeViewWithID(String viewID, [Map<String, Object> segmentation = const {}]) async {
    if (!_countlyState.isInitialized) {
      Countly.log('[Views] resumeViewWithID, "initWithConfig" must be called before "[Views] resumeViewWithID"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "[Views] resumeViewWithID"');
    final List<Object> args = [];
    args.add(viewID);
    args.add(segmentation);
    await _countlyState.channel.invokeMethod('resumeViewWithID', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<String?> startView(String viewName, [Map<String, Object> segmentation = const {}]) async {
    if (!_countlyState.isInitialized) {
      Countly.log('[Views] startView, "initWithConfig" must be called before "[Views] startView"', logLevel: LogLevel.ERROR);
      return null;
    }
    Countly.log('Calling "[Views] startView"');
    final List<Object> args = [];
    args.add(viewName);
    args.add(segmentation);
    final String? viewId = await _countlyState.channel.invokeMethod('startView', <String, dynamic>{'data': json.encode(args)});
    return viewId;
  }

  @override
  Future<void> setGlobalViewSegmentation(Map<String, Object> segmentation) async {
    if (!_countlyState.isInitialized) {
      Countly.log('[Views] setGlobalViewSegmentation, "initWithConfig" must be called before "[Views] setGlobalViewSegmentation"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "[Views] setGlobalViewSegmentation"');
    final List<Object> args = [];
    args.add(segmentation);
    await _countlyState.channel.invokeMethod('setGlobalViewSegmentation', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> updateGlobalViewSegmentation(Map<String, Object> segmentation) async {
    if (!_countlyState.isInitialized) {
      Countly.log('[Views] updateGlobalViewSegmentation, "initWithConfig" must be called before "[Views] updateGlobalViewSegmentation"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "[Views] updateGlobalViewSegmentation"');
    final List<Object> args = [];
    args.add(segmentation);
    await _countlyState.channel.invokeMethod('updateGlobalViewSegmentation', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<String?> startAutoStoppedView(String viewName, [Map<String, Object> segmentation = const {}]) async {
    if (!_countlyState.isInitialized) {
      Countly.log('[Views] startAutoStoppedView, "initWithConfig" must be called before "[Views] startAutoStoppedView"', logLevel: LogLevel.ERROR);
      return null;
    }
    Countly.log('Calling "[Views] startAutoStoppedView"');
    final List<Object> args = [];
    args.add(viewName);
    args.add(segmentation);
    final String? viewId = await _countlyState.channel.invokeMethod('startAutoStoppedView', <String, dynamic>{'data': json.encode(args)});
    return viewId;
  }

  @override
  Future<void> stopAllViews([Map<String, Object> segmentation = const {}]) async {
    if (!_countlyState.isInitialized) {
      Countly.log('[Views] stopAllViews, "initWithConfig" must be called before "[Views] stopAllViews"', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "[Views] stopAllViews"');
    final List<Object> args = [];
    args.add(segmentation);
    await _countlyState.channel.invokeMethod('stopAllViews', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> addSegmentationToViewWithID(String viewID, Map<String, Object> segmentation) async {
    if (!_countlyState.isInitialized) {
      Countly.log('[Views] addSegmentationToViewWithID, "initWithConfig" must be called before "[Views] addSegmentationToViewWithID"', logLevel: LogLevel.ERROR);
      return;
    }
    if (viewID.isEmpty) {
      Countly.log('[Views] addSegmentationToViewWithID, "viewID" must not be empty', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "[Views] addSegmentationToViewWithID" with view ID:[$viewID]');
    final List<Object> args = [];
    args.add(viewID);
    args.add(segmentation);
    await _countlyState.channel.invokeMethod('addSegmentationToViewWithID', <String, dynamic>{'data': json.encode(args)});
  }

  @override
  Future<void> addSegmentationToViewWithName(String viewName, Map<String, Object> segmentation) async {
    if (!_countlyState.isInitialized) {
      Countly.log('[Views] addSegmentationToViewWithName, "initWithConfig" must be called before "[Views] addSegmentationToViewWithName"', logLevel: LogLevel.ERROR);
      return;
    }
    if (viewName.isEmpty) {
      Countly.log('[Views] addSegmentationToViewWithName, "viewName" must not be empty', logLevel: LogLevel.ERROR);
      return;
    }
    Countly.log('Calling "[Views] addSegmentationToViewWithName" with view ID:[$viewName]');
    final List<Object> args = [];
    args.add(viewName);
    args.add(segmentation);
    await _countlyState.channel.invokeMethod('addSegmentationToViewWithName', <String, dynamic>{'data': json.encode(args)});
  }
}
