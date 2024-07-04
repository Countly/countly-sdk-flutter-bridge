/// This class holds SDK internal limits (https://support.count.ly/hc/en-us/articles/360037753291-SDK-development-guide#01H821RTQ7AZ6J858BHP4883ZC) specific configurations to be used with CountlyConfig class and serves as an interface.
/// You can chain multiple configurations.
class CountlyConfigSDKInternalLimits {
  /// private variables.
  int _maxKeyLength = 0;
  int _maxValueSize = 0;
  int _maxSegmentationValues = 0;
  int _maxBreadcrumbCount = 0;
  int _maxStackTraceLinesPerThread = 0;
  int _maxStackTraceLineLength = 0;

  /// getters
  int get maxKeyLength => _maxKeyLength;
  int get maxValueSize => _maxValueSize;
  int get maxSegmentationValues => _maxSegmentationValues;
  int get maxBreadcrumbCount => _maxBreadcrumbCount;
  int get maxStackTraceLinesPerThread => _maxStackTraceLinesPerThread;
  int get maxStackTraceLineLength => _maxStackTraceLineLength;

  /// setters / methods

  /// Limits the maximum size of all string keys
  ///
  /// [keyLengthLimit] is the maximum char size of all string keys (default 128 chars)
  CountlyConfigSDKInternalLimits setMaxKeyLength(int keyLengthLimit) {
    _maxKeyLength = keyLengthLimit;
    return this;
  }

  /// Limits the size of all values in segmentation key-value pairs
  ///
  /// [valueSizeLimit] is the maximum char size of all values in our key-value pairs (default 256 chars)
  CountlyConfigSDKInternalLimits setMaxValueSize(int valueSizeLimit) {
    _maxValueSize = valueSizeLimit;
    return this;
  }

  /// Limits the max amount of custom segmentation in one event
  ///
  /// [segmentationAmountLimit] is the max amount of custom segmentation in one event (default 100 key-value pairs)
  CountlyConfigSDKInternalLimits setMaxSegmentationValues(int segmentationAmountLimit) {
    _maxSegmentationValues = segmentationAmountLimit;
    return this;
  }

  /// Limits the max amount of breadcrumbs that can be recorded before the oldest one is deleted
  ///
  /// [breadcrumbCountLimit] is the max amount of breadcrumbs that can be recorded before the oldest one is deleted (default 100)
  CountlyConfigSDKInternalLimits setMaxBreadcrumbCount(int breadcrumbCountLimit) {
    _maxBreadcrumbCount = breadcrumbCountLimit;
    return this;
  }

  /// Limits the max amount of stack trace lines to be recorded per thread
  ///
  /// [stackTraceLinesPerThreadLimit] is the max amount of stack trace lines to be recorded per thread (default 30)
  CountlyConfigSDKInternalLimits setMaxStackTraceLinesPerThread(int stackTraceLinesPerThreadLimit) {
    _maxStackTraceLinesPerThread = stackTraceLinesPerThreadLimit;
    return this;
  }

  /// Limits the max characters allowed per stack trace lines. Also limits the crash message length
  ///
  /// [stackTraceLineLengthLimit] is the max length of each stack trace line (default 200)
  CountlyConfigSDKInternalLimits setMaxStackTraceLineLength(int stackTraceLineLengthLimit) {
    _maxStackTraceLineLength = stackTraceLineLengthLimit;
    return this;
  }
}
