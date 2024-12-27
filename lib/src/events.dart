abstract class Events {
  Future<String?> recordEvent(String key, [Map<String, Object>? segmentation, int? count, int? sum, int? duration]);
  Future<String?> startEvent(String key);
  Future<String?> endEvent(String key, [Map<String, Object>? segmentation, int? count, int? sum]);
  Future<String?> cancelEvent(String key);
}
