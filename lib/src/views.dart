abstract class Views {
  /// Start a view that will be automatically stopped when another view is started.
  /// [String viewName] - Name of view
  /// [Map<String, Object> segmentation] - segmentation data for this view
  /// Returns the view id
  Future<String?> startAutoStoppedView(String viewName, [Map<String, Object> segmentation]);

  /// Start a view.
  /// [String viewName] - Name of view
  /// [Map<String, Object> segmentation] - segmentation data for this view
  /// Returns the view id
  Future<String?> startView(String viewName, [Map<String, Object> segmentation]);

  /// Stop a view using the ID.
  /// [String viewID] - ID for the view
  /// [Map<String, Object> segmentation] - segmentation data for this view
  Future<void> stopViewWithID(String viewID, [Map<String, Object> segmentation]);

  /// Stop a view using the name.
  /// [String viewName] - Name of view
  /// [Map<String, Object> segmentation] - segmentation data for this view
  Future<void> stopViewWithName(String viewName, [Map<String, Object> segmentation]);

  /// Pause a view using the ID.
  /// [String viewID] - ID for the view
  Future<void> pauseViewWithID(String viewID);

  /// Resume a view using the ID.
  /// [String viewID] - ID for the view
  Future<void> resumeViewWithID(String viewID);

  /// Set global segmentation data for all views.
  /// [Map<String, Object> segmentation] - segmentation data for this view
  Future<void> setGlobalViewSegmentation(Map<String, Object> segmentation);

  /// Modify previously set global segmentation data.
  /// [Map<String, Object> segmentation] - segmentation data for this view
  Future<void> updateGlobalViewSegmentation(Map<String, Object> segmentation);

  /// Stop all views.
  /// [Map<String, Object> segmentation] - segmentation data for this view
  Future<void> stopAllViews([Map<String, Object> segmentation]);

  /// Set segmentation data for view using ID.
  /// [String viewID] - ID for the view
  /// [Map<String, Object> segmentation] - segmentation data for this view
  Future<void> addSegmentationToViewWithID(String viewID, Map<String, Object> segmentation);

  /// Set segmentation data for view using name of view.
  /// [String viewName] - Name of view
  /// [Map<String, Object> segmentation] - segmentation data for this view
  Future<void> addSegmentationToViewWithName(String viewName, Map<String, Object> segmentation);
}
