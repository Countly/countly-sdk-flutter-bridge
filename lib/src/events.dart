abstract class Events {
  /// Records a custom event with the specified values.
  ///
  /// [key]: Name of the custom event, required, must not be an empty string.
  /// [segmentation]: Segmentation map to associate with the event, can be null. (optional)
  /// [count]: Count to associate with the event, should be more than zero. (optional)
  /// [sum]: Sum to associate with the event. (optional)
  /// [duration]: Duration of the event. (optional)
  ///
  /// Returns a future that resolves to the result of the operation whether success or not.
  Future<String?> recordEvent(String key, [Map<String, Object>? segmentation, int? count, double? sum, int? duration]);

  /// Start timed event with a specified key
  ///
  /// [key]: Name of the custom event, required, must not be an empty string.
  ///
  /// Returns a future that resolves to the result of the operation whether success or not.
  Future<String?> startEvent(String key);

  /// Ends a timed event with a specified key.
  ///
  /// [key]: Name of the custom event, required, must not be an empty string.
  /// [segmentation]: Segmentation map to associate with the event, can be null. (optional)
  /// [count]: Count to associate with the event, should be more than zero. Default value is 1. (optional)
  /// [sum]: Sum to associate with the event. Default value is 0. (optional)
  ///
  /// Returns a future that resolves to the result of the operation whether success or not.
  Future<String?> endEvent(String key, [Map<String, Object>? segmentation, int? count, double? sum]);

  /// Cancel timed event with a specified key
  ///
  /// [key]: Name of the custom event, required, must not be an empty string.
  ///
  /// Returns a future that resolves to the result of the operation whether success or not.
  Future<String?> cancelEvent(String key);
}
