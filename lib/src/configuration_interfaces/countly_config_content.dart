/// This class holds content features specific configurations to be used with CountlyConfig class and serves as an interface.
/// You can chain multiple configurations.
import '../content_builder.dart';

class CountlyConfigContent {
  /// private variables.
  ContentCallback? _contentCallback;

  /// getters
  ContentCallback? get contentCallback => _contentCallback;

  /// setters / methods

  ///  This is an experimental feature and it can have breaking changes
  //   Register global completion blocks to be executed on content.
  CountlyConfigContent setGlobalContentCallback(ContentCallback callback) {
    _contentCallback = callback;
    return this;
  }
}