abstract class Views {
  void stopViewById(String viewID, [Map<String, Object>? segmentation]);

  void stopViewByName(String viewName, [Map<String, Object>? segmentation]);

  String startView(String viewName, [Map<String, Object>? segmentation]);

  void setGlobalViewSegmentation(Map<String, Object> segmentation);

  void updateGlobalViewSegmentation(Map<String, Object> segmentation);
}
