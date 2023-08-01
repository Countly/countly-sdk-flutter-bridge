abstract class Views {
  void stopViewWithID(String viewID, [Map<String, Object> segmentation]);

  void stopViewWithName(String viewName, [Map<String, Object> segmentation]);

  void pauseViewWithID(String viewID);

  void resumeViewWithID(String viewID);

  Future<String?> startView(String viewName, [Map<String, Object> segmentation]);

  void setGlobalViewSegmentation(Map<String, Object> segmentation);

  void updateGlobalViewSegmentation(Map<String, Object> segmentation);
}
