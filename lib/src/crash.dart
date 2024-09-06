typedef GlobalCrashFilterCallback = CrashData? Function(CrashData crashData);

class CrashData {
  CrashData({required this.breadcrumbs, required this.crashMetrics, required this.crashSegmentation, required this.fatal, required this.stackTrace});

  List<dynamic> breadcrumbs;
  Map<dynamic, dynamic> crashMetrics;
  Map<dynamic, dynamic> crashSegmentation;
  bool fatal;
  String stackTrace;

  /// Convience method provided for easy manipulation of CrashData.
  /// This will return a new instance of CrashData and change only the data passed
  CrashData copyWith({List<dynamic>? breadcrumbs, Map<dynamic, dynamic>? crashMetrics, Map<dynamic, dynamic>? crashSegmentation, bool? fatal, String? stackTrace}) {
    return CrashData(
      breadcrumbs: breadcrumbs ?? this.breadcrumbs,
      crashMetrics: crashMetrics ?? this.crashMetrics,
      fatal: fatal ?? this.fatal,
      stackTrace: stackTrace ?? this.stackTrace,
      crashSegmentation: crashSegmentation ?? this.crashSegmentation,
    );
  }

  factory CrashData.fromJson(Map<String, dynamic> json) {
    return CrashData(breadcrumbs: json['b'], crashMetrics: json['m'], crashSegmentation: json['cs'], fatal: json['f'], stackTrace: json['s']);
  }

  Map<String, dynamic> toJson() {
    return {'b': breadcrumbs, 'm': crashMetrics, 'cs': crashSegmentation, 'f': fatal, 's': stackTrace};
  }
}
