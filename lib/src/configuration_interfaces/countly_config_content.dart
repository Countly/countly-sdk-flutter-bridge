/// This class holds content features specific configurations to be used with CountlyConfig class and serves as an interface.
/// You can chain multiple configurations.
import '../content_builder.dart';

class CountlyConfigContent {
  /// private variables.
  ContentCallback? _contentCallback;
  int? _zoneTimerInterval;
  WebViewDisplayOption? _webviewDisplayOption;
  ContentUrlHandler? _contentUrlHandler;
  List<String> _contentUrlPrefixes = const [];
  double? _overlayCornerRadius;
  bool _widgetsWithinAppEnabled = false;

  /// getters
  ContentCallback? get contentCallback => _contentCallback;
  int? get zoneTimerInterval => _zoneTimerInterval;
  WebViewDisplayOption? get webviewDisplayOption => _webviewDisplayOption;
  ContentUrlHandler? get contentUrlHandler => _contentUrlHandler;
  List<String> get contentUrlPrefixes => _contentUrlPrefixes;
  double? get overlayCornerRadius => _overlayCornerRadius;
  bool get widgetsWithinAppEnabled => _widgetsWithinAppEnabled;

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
  /// [WebViewDisplayOption.immersive]: The webview will be displayed in immersive mode
  /// [WebViewDisplayOption.safeArea]: The webview will be displayed within the safe area
  CountlyConfigContent setWebviewDisplayOption(WebViewDisplayOption option) {
    _webviewDisplayOption = option;
    return this;
  }

  /// Take over the links opened from content blocks and feedback widgets, which is how an application
  /// routes its own deep links. A link whose URL starts with one of [urlPrefixes], compared ignoring
  /// case, is handed to [handler] and not opened by the SDK; every other link is opened by the SDK as
  /// usual. Without prefixes every link is handed over and the SDK opens none of them, since it can not
  /// wait for the application's answer.
  /// Not supported on web
  /// [ContentUrlHandler handler]: called with each matching URL
  /// [List<String> urlPrefixes]: the beginnings of the URLs the application handles, such as "myapp://" or "https://example.com/app/"
  CountlyConfigContent setContentUrlHandler(ContentUrlHandler handler, {List<String> urlPrefixes = const []}) {
    _contentUrlHandler = handler;
    _contentUrlPrefixes = urlPrefixes.where((prefix) => prefix.isNotEmpty).toList();
    return this;
  }

  /// Set the corner radius of the overlay, in points, when widgets are shown within the application's
  /// window. Left unset, the radius is read from the window. Only has an effect together with
  /// [showWidgetsWithinApp].
  /// macOS only, ignored on every other platform
  CountlyConfigContent setOverlayCornerRadius(double radius) {
    _overlayCornerRadius = radius;
    return this;
  }

  /// Show content blocks and feedback widgets inside the application's own window rather than over the
  /// whole screen, so they move with the window and never paint over anything else.
  /// macOS only, ignored on every other platform
  CountlyConfigContent showWidgetsWithinApp() {
    _widgetsWithinAppEnabled = true;
    return this;
  }
}
