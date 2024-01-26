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

  /// Enables the tracking of app start time. (For iOS after this call you will have to call [enableManualAppLoadedTrigger])
  CountlyConfigApm enableAppStartTimeTracking() {
    _trackAppStartTime = true;
    return this;
  }

  /// Enables the usage of manual trigger [Countly.appLoadingFinished] to determine app start finish time.
  CountlyConfigApm enableManualAppLoadedTrigger() {
    _enableManualAppLoaded = true;
    return this;
  }

  /// Gives you the ability to override the app start initial timestamp.
  ///
  /// [timestamp] is the timestamp (in milliseconds)
  CountlyConfigApm setAppStartTimestampOverride(int timestamp) {
    if (timestamp > 0) {
      _startTSOverride = timestamp;
    }
    return this;
  }
}
