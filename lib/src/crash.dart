typedef GlobalCrashFilterCallback = CrashData? Function(CrashData crashData);

class CrashData {
  CrashData(this.exception, this.nonFatal, this.segmentation);

  String exception;
  bool nonFatal;
  Map<String, Object>? segmentation;

  /// Convience method provided for easy manipulation of CrashData.
  /// This will return a new instance of CrashData and change only the data passed
  CrashData copyWith({String? exception, bool? nonFatal, Map<String, Object>? segmentation}) {
    return CrashData(
      exception ?? this.exception,
      nonFatal ?? this.nonFatal,
      segmentation ?? this.segmentation,
    );
  }
}
