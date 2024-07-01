typedef GlobalCrashFilterCallback = CrashData? Function(CrashData crashData);

class CrashData {
  CrashData({required this.breadcrumbs, required this.crashMetrics, required this.crashSegmentation, required this.fatal, required this.stackTrace});

  List<String> breadcrumbs;
  Map<String, dynamic> crashMetrics;
  Map<String, dynamic> crashSegmentation;
  bool fatal;
  String stackTrace;

  /// Convience method provided for easy manipulation of CrashData.
  /// This will return a new instance of CrashData and change only the data passed
  CrashData copyWith({List<String>? breadcrumbs, Map<String,dynamic>? crashMetrics, Map<String, Object>? crashSegmentation, bool? fatal, String? stackTrace}) {
    return CrashData(
      breadcrumbs: breadcrumbs ?? this.breadcrumbs,
      crashMetrics: crashMetrics ?? this.crashMetrics,
      fatal: fatal ?? this.fatal,
      stackTrace: stackTrace ?? this.stackTrace,
      crashSegmentation: crashSegmentation ?? this.crashSegmentation,
    );
  }
}
