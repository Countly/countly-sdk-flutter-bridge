/// This class holds push notification specific configurations to be used with CountlyConfig class and serves as an interface.
/// You can chain multiple configurations.
/// Every option here applies to the web platform only, where a push subscription is created in the browser.
/// Android and iOS take their push credentials from the platform project and ignore these values.
class CountlyConfigPush {
  /// private variables.
  String? _vapidPublicKey;
  String? _serviceWorkerPath;

  /// A Flutter web application registers "flutter_service_worker.js" at the root scope and the SDK
  /// will not replace it, so Countly takes a narrower scope of its own. Push messages and
  /// notification clicks reach the worker regardless of its scope.
  String _serviceWorkerScope = '/countly-push/';
  bool _automaticRegistrationDisabled = false;
  int? _subscribeTimeout;

  /// getters
  String? get vapidPublicKey => _vapidPublicKey;
  int? get subscribeTimeout => _subscribeTimeout;
  String? get serviceWorkerPath => _serviceWorkerPath;
  String get serviceWorkerScope => _serviceWorkerScope;
  bool get automaticRegistrationDisabled => _automaticRegistrationDisabled;

  /// setters / methods

  /// Set the VAPID public key the browser subscribes with. Without it web push stays off.
  /// Generate it in the Countly dashboard under your application's settings.
  /// [String publicKey]: a base64-url encoded uncompressed P-256 public key
  CountlyConfigPush setVapidPublicKey(String publicKey) {
    _vapidPublicKey = publicKey;
    return this;
  }

  /// Set where the Countly service worker is served from, relative to the site root.
  /// The default is "/countly_sw.js", so copy "countly_sw.js" into the "web" folder of your application.
  /// [String path]: path of the service worker script
  CountlyConfigPush setServiceWorkerPath(String path) {
    _serviceWorkerPath = path;
    return this;
  }

  /// Set the scope the service worker is registered under. The default is "/countly-push/".
  /// [String scope]: scope of the service worker
  CountlyConfigPush setServiceWorkerScope(String scope) {
    _serviceWorkerScope = scope;
    return this;
  }

  /// Stop the SDK from resubscribing on its own when notification permission was already granted.
  /// Subscribing then only happens when "Countly.askForNotificationPermission" is called.
  CountlyConfigPush disableAutomaticRegistration() {
    _automaticRegistrationDisabled = true;
    return this;
  }

  /// Set how long the SDK waits for the browser to finish creating a push subscription before it gives up,
  /// so that a browser which never answers does not block a later attempt. The default is 30000.
  /// [int timeout]: duration in milliseconds
  CountlyConfigPush setSubscribeTimeout(int timeout) {
    _subscribeTimeout = timeout;
    return this;
  }
}
