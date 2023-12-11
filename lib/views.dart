abstract class Views {
  Future<String?> startAutoStoppedView(String viewName, [Map<String, Object> segmentation]);

  Future<String?> startView(String viewName, [Map<String, Object> segmentation]);

  void stopViewWithID(String viewID, [Map<String, Object> segmentation]);

  void stopViewWithName(String viewName, [Map<String, Object> segmentation]);

  void pauseViewWithID(String viewID);

  void resumeViewWithID(String viewID);

  void setGlobalViewSegmentation(Map<String, Object> segmentation);

  void updateGlobalViewSegmentation(Map<String, Object> segmentation);

  void stopAllViews([Map<String, Object> segmentation]);

  Future<void> addSegmentationToViewWithID(String viewID, Map<String, Object> segmentation);

  Future<void> addSegmentationToViewWithName(String viewName, Map<String, Object> segmentation);
}
