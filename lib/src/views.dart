import 'package:flutter/material.dart';

abstract class Views {
  Future<String?> startAutoStoppedView(String viewName, [Map<String, Object> segmentation]);

  Future<String?> startView(String viewName, [Map<String, Object> segmentation]);

  Future<void> stopViewWithID(String viewID, [Map<String, Object> segmentation]);

  Future<void> stopViewWithName(String viewName, [Map<String, Object> segmentation]);

  Future<void> pauseViewWithID(String viewID);

  Future<void> resumeViewWithID(String viewID);

  Future<void> setGlobalViewSegmentation(Map<String, Object> segmentation);

  Future<void> updateGlobalViewSegmentation(Map<String, Object> segmentation);

  Future<void> stopAllViews([Map<String, Object> segmentation]);

  Future<void> addSegmentationToViewWithID(String viewID, Map<String, Object> segmentation);

  Future<void> addSegmentationToViewWithName(String viewName, Map<String, Object> segmentation);

  void trackWidget();
  void trackWidgetKey(GlobalKey key, String name);
  bool trackScroll(ScrollNotification notification);
}
