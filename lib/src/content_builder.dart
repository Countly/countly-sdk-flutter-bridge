//indicates the content status
enum ContentStatus { completed, closed }

/// Defines how the webview content should be displayed
enum WebViewDisplayOption { immersive, safeArea }

typedef ContentCallback = void Function(ContentStatus contentStatus, Map<String, dynamic> contentData);

abstract class ContentBuilder {
  /// Enables content fetching and updates for the user.
  /// This method opts the user into receiving content updates
  /// and ensures that relevant data is fetched accordingly.
  Future<void> enterContentZone();

  /// Disables content fetching and updates for the user.
  /// This method opts the user out of receiving content updates
  /// and stops any ongoing content retrieval processes.
  Future<void> exitContentZone();

  /// Triggers a manual refresh of the content zone.
  /// This method forces an update by fetching the latest content,
  /// ensuring the user receives the most up-to-date information.
  Future<void> refreshContentZone();

  ///  This is an experimental feature and it can have breaking changes
  /// Previews the content associated with the given [contentId].
  /// This method fetches and displays the content for preview purposes.
  Future<void> previewContent(String contentId);

  /// This is an experimental feature and it can have breaking changes
  /// Sets a segmentation recorded with every content event and with the events of NPS, survey and
  /// rating feedback widgets, in place of the one set before. An empty map clears it.
  /// It is kept while the app runs and is not restored after a restart (Only for iOS and Web).
  /// [Map<String, Object> segmentation] - the segmentation to record
  Future<void> setGlobalContentSegmentation(Map<String, Object> segmentation);
}
