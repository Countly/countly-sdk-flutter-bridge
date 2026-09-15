abstract class Events {
  /// Records a custom event with the specified values.
  ///
  /// [key]: Name of the custom event, required, must not be an empty string.
  /// [segmentation]: Segmentation map to associate with the event, can be null. (optional)
  /// [count]: Count to associate with the event, should be more than zero. (optional)
  /// [sum]: Sum to associate with the event. (optional)
  /// [duration]: Duration of the event. (optional)
  Future<void> recordEvent(String key, [Map<String, Object>? segmentation, int? count, double? sum, int? duration]);

  /// Start timed event with a specified key
  ///
  /// [key]: Name of the custom event, required, must not be an empty string.
  Future<void> startEvent(String key);

  /// Ends a timed event with a specified key.
  ///
  /// [key]: Name of the custom event, required, must not be an empty string.
  /// [segmentation]: Segmentation map to associate with the event, can be null. (optional)
  /// [count]: Count to associate with the event, should be more than zero. Default value is 1. (optional)
  /// [sum]: Sum to associate with the event. Default value is 0. (optional)
  Future<void> endEvent(String key, [Map<String, Object>? segmentation, int? count, double? sum]);

  /// Cancel timed event with a specified key
  ///
  /// [key]: Name of the custom event, required, must not be an empty string.
  Future<void> cancelEvent(String key);
}
