/// This class holds Experimental features specific configurations to be used with CountlyConfig class and serves as an interface.
/// You can chain multiple configurations.
class CountlyConfigExperimental {
  /// private variables.
  bool _visibilityTracking = false;
  bool _previousNameRecording = false;

  /// getters
  bool get visibilityTracking => _visibilityTracking;
  bool get previousNameRecording => _previousNameRecording;

  /// setters / methods

  /// Enables visibility tracking of application.
  CountlyConfigExperimental enableVisibilityTracking() {
    _visibilityTracking = true;
    return this;
  }

  /// Enables recording previous event/view and current view names.
  CountlyConfigExperimental enablePreviousNameRecording() {
    _previousNameRecording = true;
    return this;
  }
}
