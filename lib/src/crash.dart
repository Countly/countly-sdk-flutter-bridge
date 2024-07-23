typedef GlobalCrashFilterCallback = CrashData? Function(CrashData crashData);

class CrashData {
  CrashData({required this.segmentation, required this.nonfatal, required this.exception});

  Map<String, dynamic>? segmentation;
  bool nonfatal;
  String exception;

  /// Convience method provided for easy manipulation of CrashData.
  /// This will return a new instance of CrashData and change only the data passed
  CrashData copyWith({Map<String, Object>? segmentation, bool? nonfatal, String? exception}) {
    return CrashData(
      nonfatal: nonfatal ?? this.nonfatal,
      exception: exception ?? this.exception,
      segmentation: segmentation ?? this.segmentation,
    );
  }
}
