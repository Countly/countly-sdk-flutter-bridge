abstract class Views {
  void stopViewWithId(String viewID, [Map<String, Object> segmentation]);

  void stopViewWithName(String viewName, [Map<String, Object> segmentation]);

  Future<String?> startView(String viewName, [Map<String, Object> segmentation]);

  void setGlobalViewSegmentation(Map<String, Object> segmentation);

  void updateGlobalViewSegmentation(Map<String, Object> segmentation);
}
