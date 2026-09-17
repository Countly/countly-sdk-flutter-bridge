// ignore_for_file: non_constant_identifier_names
import 'dart:js_interop';

/// The global object the Web SDK installs. It holds what is shared between instances, and the
/// members of the first instance that was initialized are copied onto it as well.
@JS('Countly')
external CountlyGlobal get countlyGlobal;

/// Constructs an instance of the Web SDK directly, instead of going through "Countly.init".
/// The SDK keys its own registry by app key, so two Countly instances sharing one app key would be
/// the same object there. Named instances are built here and kept in the plugin's own registry.
@JS('Countly.CountlyClass')
extension type CountlyClass._(JSObject _) implements JSObject {
  external CountlyClass(JSAny config);
}

extension type CountlyGlobal._(JSObject _) implements JSObject {
  external JSArray get features;

  /// Initializes and registers the instance for the app key in the given configuration.
  external Countly init(JSAny config);
}

extension type Countly._(JSObject _) implements JSObject {
  // SDK
  external void halt();

  // Events
  external void add_event(JSAny event);
  external void start_event(String key);
  external void end_event(JSAny event);
  external void cancel_event(String key);

  // Session Management
  external void begin_session();
  external void track_sessions(); // Auto session tracking
  external void end_session();

  // Device ID Management
  external String get_device_id();
  external void set_id(String id);
  external int get_device_id_type();
  external void change_id(String newId, bool merge);
  external void enable_offline_mode();

  // Consents
  external void add_consent(JSAny consents);
  external void remove_consent(JSAny consents);

  // View Management
  external void track_pageview(String? page, JSArray? ignoreList, JSAny? segments);

  // Crashes
  external void track_errors(JSAny? globalSegmennts);
  external void recordError(JSAny error, bool nonfatal, JSAny? segments);
  external void add_log(String log); // breadcrumb

  // User Profiles
  external void user_details(JSAny userDetails);

  // Feedback
  external void get_available_feedback_widgets(JSAny? callback);
  external void present_feedback_widget(JSAny? presentableFeedback, String? id, String? className, JSAny? feedbackWidgetSegmentation);
  external void getFeedbackWidgetData(JSAny? CountlyFeedbackWidget, JSAny? callback);
  external void reportFeedbackWidgetManually(JSAny? CountlyFeedbackWidget, JSAny? CountlyWidgetData, JSAny? widgetResult);

  // Performance monitoring
  external void report_trace(JSAny trace);

  // Attribution
  external void recordDirectAttribution(String? campaignId, String? campaignUserId);

  // Remote Config
  external void fetch_remote_config(JSAny? keys, JSAny? omit_keys, JSAny? callback);
  external JSAny? get_remote_config([String? key]);
  external void enrollUserToAb(JSAny? keys);

  // Sub interfaces
  external CountlyContent get content;
  external CountlyUserData get userData;
  external CountlyFeedback get feedback;

  @JS('_internals')
  external CountlyInternal get internals;
}

extension type CountlyContent._(JSObject _) implements JSObject {
  external void enterContentZone();
  external void exitContentZone();
}

extension type CountlyUserData._(JSObject _) implements JSObject {
  external void set(String key, JSAny? value);
  external void set_once(String key, JSAny? value);
  external void increment(String key);
  external void increment_by(String key, int value);
  external void multiply(String key, int value);
  external void max(String key, int value);
  external void min(String key, int value);
  external void push(String key, JSAny? value);
  external void push_unique(String key, JSAny? value);
  external void pull(String key, JSAny? value);
  external void save();
}

extension type CountlyFeedback._(JSObject _) implements JSObject {
  external void showNPS(String? nameTagOrID);
  external void showSurvey(String? nameTagOrID);
  external void showRating(String? nameTagOrID);
}

extension type CountlyInternal._(JSObject _) implements JSObject {
  external JSArray getRequestQueue();
  external JSArray getEventQueue();
}
