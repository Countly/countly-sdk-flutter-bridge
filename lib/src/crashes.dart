abstract class Crashes {
  /// Record a handled or unhandled exception.
  /// [String exception]: the exception message or stack trace to report
  /// [bool nonfatal]: "true" for a handled exception, "false" for one that ended the application
  /// [Map<String, Object>? segmentation]: segmentation to attach to this crash only
  Future<void> recordException(String exception, bool nonfatal, [Map<String, Object>? segmentation]);

  /// Record a Dart error together with its stack trace.
  /// [dynamic exception]: the caught error or exception
  /// [StackTrace? stacktrace]: the stack trace it was caught with
  /// [bool nonfatal]: "true" for a handled error, "false" for one that ended the application
  /// [Map<String, Object>? segmentation]: segmentation to attach to this crash only
  Future<void> recordError(dynamic exception, StackTrace? stacktrace, {bool nonfatal = true, Map<String, Object>? segmentation});

  /// Add a breadcrumb that is sent with the next crash report.
  /// [String record]: the breadcrumb text
  Future<void> addCrashBreadcrumb(String record);

}
