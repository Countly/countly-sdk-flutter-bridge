class CountlyConfig {
  String _appKey;
  String _serverURL;
  String? _deviceID;
  Map<String, dynamic> _customCrashSegment = {};

  CountlyConfig(this._serverURL, this._appKey, [this._deviceID]);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> countlyConfig = {};
    countlyConfig['appKey'] = _appKey;
    countlyConfig['serverURL'] = _serverURL;
    if (_customCrashSegment != null) {
      countlyConfig['customCrashSegment'] = {};
      _customCrashSegment!.forEach((key, value) {
        countlyConfig['customCrashSegment'][key] = value.toString();
      });
    }
    countlyConfig['deviceID'] = _deviceID;
    return countlyConfig;
  }

  CountlyConfig setCustomCrashSegment(Map<String, dynamic> customCrashSegment){
    _customCrashSegment = customCrashSegment;
    return this;
  }
}
