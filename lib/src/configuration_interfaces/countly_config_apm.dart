/// This class holds APM specific configurations to be used with CountlyConfig class and serves as an interface.
/// You can chain multiple configurations.
class CountlyConfigApm {
  /// private variables.
  bool _enableForegroundBackground = false;
  bool _trackAppStartTime = false;
  bool _enableManualAppLoaded = false;
  int _startTSOverride = 0;

  /// getters
  bool get enableForegroundBackground => _enableForegroundBackground;
  bool get trackAppStartTime => _trackAppStartTime;
  bool get enableManualAppLoaded => _enableManualAppLoaded;
  int get startTSOverride => _startTSOverride;

  /// setters / methods

  /// Enables the automatic tracking of app foreground and background durations.
  CountlyConfigApm enableForegroundBackgroundTracking() {
    _enableForegroundBackground = true;
    return this;
  }

  /// Enables the automatic tracking of app start time.
  CountlyConfigApm enableAppStartTimeTracking() {
    _trackAppStartTime = true;
    return this;
  }

  /// Enables manual trigger of the moment when the app has finished loading.
  CountlyConfigApm enableManualAppLoadedTrigger() {
    _enableManualAppLoaded = true;
    return this;
  }

  /// Gives you the ability to override the automatic app start timestamp.
  /// [timestamp] is the timestamp (in milliseconds)
  CountlyConfigApm setAppStartTimestampOverride(int timestamp) {
    if (timestamp > 0) {
      _startTSOverride = timestamp;
    }
    return this;
  }
}
