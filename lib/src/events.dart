abstract class Events {
  Future<String?> recordEvent(String key, [Map<String, Object>? segmentation, int? count, double? sum, int? duration]);
  Future<String?> startEvent(String key);
  Future<String?> endEvent(String key, [Map<String, Object>? segmentation, int? count, double? sum]);
  Future<String?> cancelEvent(String key);
}
