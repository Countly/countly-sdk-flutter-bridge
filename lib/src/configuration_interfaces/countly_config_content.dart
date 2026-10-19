/// This class holds content features specific configurations to be used with CountlyConfig class and serves as an interface.
/// You can chain multiple configurations.
import '../content_builder.dart';
import 'intent_schemes.dart';

class CountlyConfigContent {
  /// private variables.
  ContentCallback? _contentCallback;
  int? _zoneTimerInterval;
  WebViewDisplayOption? _webviewDisplayOption;
  List<String>? _allowedIntentSchemes;

  /// getters
  ContentCallback? get contentCallback => _contentCallback;
  int? get zoneTimerInterval => _zoneTimerInterval;
  WebViewDisplayOption? get webviewDisplayOption => _webviewDisplayOption;
  List<String>? get allowedIntentSchemes => _allowedIntentSchemes;

  /// setters / methods

  ///  This is an experimental feature and it can have breaking changes
  //   Register global completion blocks to be executed on content.
  CountlyConfigContent setGlobalContentCallback(ContentCallback callback) {
    _contentCallback = callback;
    return this;
  }

  /// This is an experimental feature and it can have breaking changes
  /// Set the interval for the automatic content update calls
  ///
  /// zoneTimerIntervalSeconds in seconds
  CountlyConfigContent setZoneTimerInterval(int interval) {
    _zoneTimerInterval = interval;
    return this;
  }

  /// Set the webview display option for content
  /// [WebViewDisplayOption.immersive] - The webview will be displayed in immersive mode
  /// [WebViewDisplayOption.safeArea] - The webview will be displayed within the safe area
  CountlyConfigContent setWebviewDisplayOption(WebViewDisplayOption option) {
    _webviewDisplayOption = option;
    return this;
  }

  /// Limit the URI schemes that links in content and feedback widgets may open (Android only).
  /// Without it, every scheme may open except "data", "zip", "intent", "file", "content",
  /// "javascript" and "jar", which stay blocked even when listed.
  /// [List<String> schemes]: the allowed schemes without "://", for example ["https", "myapp"]
  CountlyConfigContent setAllowedIntentSchemes(List<String> schemes) {
    _allowedIntentSchemes = allowedIntentSchemesFrom(schemes, 'content.setAllowedIntentSchemes');
    return this;
  }
}
