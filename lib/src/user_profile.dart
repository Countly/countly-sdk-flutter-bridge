abstract class UserProfile {
  /// Provide a map of user properties to set.
  /// Those can be either custom user properties or predefined user properties
  /// [Map<String, Object> properties] - map of custom and predefined user propetries.
  Future<void> setUserProperties(Map<String, Object> userProperties);

  /// Set a single user property. It can be either a custom one or one of the predefined ones.
  /// [String key] - the key for the user property
  /// [Object value] - the value for the user property to be set. The value should be the allowed data type.
  Future<void> setProperty(String key, Object value);

  /// Increment custom property value by 1.
  /// [String key] - property name to increment
  Future<void> increment(String key);

  /// Increment custom property value by provided value.
  /// [String key] - property name to increment
  /// [int value] - value by which to increment
  Future<void> incrementBy(String key, int value);

  /// Multiply custom property value by provided value.
  /// [String key] - property name to multiply
  /// [int value] - value by which to multiply
  Future<void> multiply(String key, int value);

  /// Save maximal value between existing and provided.
  /// [String key] - property name to check for max
  /// [int value] - value to check for max
  Future<void> saveMax(String key, int value);

  /// Save minimal value between existing and provided.
  /// [String key] - property name to check for min
  /// [int value] - value to check for min
  Future<void> saveMin(String key, int value);

  /// Set value only if property does not exist yet
  /// [String key] - property name to set
  /// [String value] - value to set
  Future<void> setOnce(String key, String value);

  /// Create array property, if property does not exist and add value to array
  /// You can only use it on array properties or properties that do not exist yet
  /// [String key] - property name for array property
  /// [String value] - value to add to array
  Future<void> push(String key, String value);

  /// Create array property, if property does not exist and add value to array, only if value is not yet in the array
  /// You can only use it on array properties or properties that do not exist yet
  /// [String key] - property name for array property
  /// [String value] - value to add to array
  Future<void> pushUnique(String key, String value);

  /// If a custom property exists, its value is an array, and the specified value is present within that array, then this will remove the specified value from the array.
  /// You can only use it on array properties that exist.
  /// [String key] - property name for array property
  /// [String value] - value to remove from array
  Future<void> pull(String key, String value);

  /// Send/Save provided values to server
  Future<void> save();

  /// Clear queued operations / modifications
  Future<void> clear();
}
