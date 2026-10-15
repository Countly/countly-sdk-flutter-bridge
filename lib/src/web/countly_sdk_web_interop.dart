// ignore_for_file: non_constant_identifier_names
import 'dart:js_interop';

/// The page's global `Countly` object, the Web SDK's entry point. Only class level members are
/// used on it; everything else is called on the instance [CountlyGlobalMembers.init] returns, so
/// a Countly instance the host page created itself never receives this plugin's data.
@JS()
@staticInterop
class CountlyGlobal {}

/// The global `Countly` object, or undefined until the Web SDK script has loaded.
@JS('Countly')
external CountlyGlobal get countlyGlobal;

/// Class level members of the global `Countly` object.
extension CountlyGlobalMembers on CountlyGlobal {
  external JSArray get features;

  /// Creates the instance for the app key in [config], or returns it when it already exists.
  /// Returns nothing when the page set Countly.loadAPMScriptsAsync, as init then runs later.
  external CountlyWeb? init(JSAny config);
}

/// One Web SDK instance, as returned by `Countly.init`.
@JS()
@staticInterop
class CountlyWeb {}

/// Members of a Web SDK instance.
extension CountlyWebMembers on CountlyWeb {
  external void halt();

  // Events
  external void add_event(JSAny event);
  external void start_event(String key);
  external void end_event(JSAny event);
  external void cancel_event(String key);

  // Session Management
  external void begin_session([bool? noHeartBeat, bool? force]);
  external void track_sessions();
  external void session_duration(int seconds);
  external void end_session([int? seconds, bool? force]);

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
  external void track_errors(JSAny? globalSegments);
  external void recordError(JSAny error, bool nonfatal, JSAny? segments);
  external void add_log(String log);

  // User Profiles
  external void user_details(JSAny userDetails);

  // Feedback
  external void get_available_feedback_widgets(JSAny? callback);
  external void present_feedback_widget(JSAny? presentableFeedback, String? id, String? className, JSAny? feedbackWidgetSegmentation);
  external void getFeedbackWidgetData(JSAny? countlyFeedbackWidget, JSAny? callback);
  external void reportFeedbackWidgetManually(JSAny? countlyFeedbackWidget, JSAny? countlyWidgetData, JSAny? widgetResult);

  // Remote Config
  external void fetch_remote_config(JSAny? keys, JSAny? omitKeys, JSAny? callback);
  external JSAny? get_remote_config([String? key]);
  external void enrollUserToAb(JSAny? keys);

  // Performance Monitoring
  external void report_trace(JSAny trace);

  // Attribution
  external void recordDirectAttribution(String campaignId, [String? campaignUserId]);

  // Networking
  external void attempt_to_send_stored_requests();

  /// Headers added to every request, read when a request is sent.
  external JSAny? get headers;
  external set headers(JSAny? value);

  // Location, read when a request is prepared
  external JSAny? get country_code;
  external set country_code(JSAny? value);
  external JSAny? get city;
  external set city(JSAny? value);
  external JSAny? get ip_address;
  external set ip_address(JSAny? value);

  external CountlyWebContent get content;
  external CountlyWebUserData get userData;
  external CountlyWebFeedback get feedback;
  @JS('_internals')
  external CountlyWebInternals get internals;
}

/// The content zone members of a Web SDK instance.
@JS()
@staticInterop
class CountlyWebContent {}

/// Members of [CountlyWebContent].
extension CountlyWebContentMembers on CountlyWebContent {
  external void enterContentZone();
  external void refreshContentZone();
  external void exitContentZone();
}

/// The user profile members of a Web SDK instance.
@JS()
@staticInterop
class CountlyWebUserData {}

/// Members of [CountlyWebUserData].
extension CountlyWebUserDataMembers on CountlyWebUserData {
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

/// The feedback members of a Web SDK instance.
@JS()
@staticInterop
class CountlyWebFeedback {}

/// Members of [CountlyWebFeedback].
extension CountlyWebFeedbackMembers on CountlyWebFeedback {
  external void showNPS(String? nameTagOrID);
  external void showSurvey(String? nameTagOrID);
  external void showRating(String? nameTagOrID);
}

/// The internal members of a Web SDK instance: the queues the tests read, and the view calls the
/// public API lacks.
@JS()
@staticInterop
class CountlyWebInternals {}

/// Members of [CountlyWebInternals].
extension CountlyWebInternalsMembers on CountlyWebInternals {
  external JSArray getRequestQueue();
  external JSArray getEventQueue();

  /// The name of the running view, or null when none runs.
  external JSAny? getLastView();

  /// Ends the running view and reports its duration.
  external void reportViewDuration();
}
