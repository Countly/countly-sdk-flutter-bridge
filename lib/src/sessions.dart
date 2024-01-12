abstract class Sessions {
  /// Starts session for manual session handling.
  /// This method needs to be called for starting a session only
  /// if manual session handling is enabled by calling the 'enableManualSessionHandling' method of 'CountlyConfig'.
  Future<void> beginSession();

  /// Update session for manual session handling.
  /// This method needs to be called for starting a session only
  /// if manual session handling is enabled by calling the 'enableManualSessionHandling' method of 'CountlyConfig'.
  Future<void> updateSession();

  /// End session for manual session handling.
  /// This method needs to be called for starting a session only
  /// if manual session handling is enabled by calling the 'enableManualSessionHandling' method of 'CountlyConfig'.
  Future<void> endSession();
}
