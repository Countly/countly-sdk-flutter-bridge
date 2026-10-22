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
  /// Resets the instance and its queues. For tests.
  external void halt();

  // Events
  /// Records [event], an object with key, count, sum, dur and segmentation.
  external void add_event(JSAny event);

  /// Starts timing the event [key].
  external void start_event(String key);

  /// Ends the timed event named by the key of [event] and records it with the given values.
  external void end_event(JSAny event);

  /// Drops the timed event [key] without recording it.
  external void cancel_event(String key);

  // Session Management
  /// Begins a session; [noHeartBeat] stops automatic extensions, [force] ignores the session cookie.
  external void begin_session([bool? noHeartBeat, bool? force]);

  /// Begins, extends and ends sessions automatically with the page lifecycle.
  external void track_sessions();

  /// Ends the session with [seconds] since the last report; [force] ignores the session cookie.
  external void end_session([int? seconds, bool? force]);

  // Device ID Management
  /// The current device ID.
  external String get_device_id();

  /// Sets the device ID, merging the old one into it unless it was set by the developer.
  external void set_id(String id);

  /// The device ID type: 0 developer supplied, 1 SDK generated, 2 temporary.
  external int get_device_id_type();

  /// Changes the device ID to [newId], merging the old one into it when [merge] is true.
  external void change_id(String newId, bool merge);

  /// Switches to a temporary device ID, keeping requests until a real one is set.
  external void enable_offline_mode();

  // Consents
  /// Gives the consent for [consents], a feature name or a list of them.
  external void add_consent(JSAny consents);

  /// Removes the consent for [consents], a feature name or a list of them.
  external void remove_consent(JSAny consents);

  // View Management
  /// Starts the view [page] with [segments], ending the view that ran before.
  external void track_pageview(String? page, JSArray? ignoreList, JSAny? segments);

  // Crashes
  /// Reports uncaught errors of the page as fatal crashes, with [globalSegments] added.
  external void track_errors(JSAny? globalSegments);

  /// Reports [error] as a crash, handled when [nonfatal] is true, with [segments].
  external void recordError(JSAny error, bool nonfatal, JSAny? segments);

  /// Adds [log] to the breadcrumbs sent with the next crash.
  external void add_log(String log);

  // User Profiles
  /// Sends [userDetails], the named and custom user properties.
  external void user_details(JSAny userDetails);

  // Feedback
  /// Fetches the feedback widgets of the app and passes them, or an error, to [callback].
  external void get_available_feedback_widgets(JSAny? callback);

  /// Shows the feedback widget [presentableFeedback] from the widget list.
  external void present_feedback_widget(JSAny? presentableFeedback, String? id, String? className, JSAny? feedbackWidgetSegmentation);

  /// Fetches the questions of [countlyFeedbackWidget] and passes them, or an error, to [callback].
  external void getFeedbackWidgetData(JSAny? countlyFeedbackWidget, JSAny? callback);

  /// Reports [widgetResult], the answers to a widget the app showed itself, or null for a closed one.
  external void reportFeedbackWidgetManually(JSAny? countlyFeedbackWidget, JSAny? countlyWidgetData, JSAny? widgetResult);

  // Remote Config
  /// Downloads remote config values, only [keys] or all but [omitKeys], and calls [callback].
  external void fetch_remote_config(JSAny? keys, JSAny? omitKeys, JSAny? callback);

  /// The stored remote config value of [key], or every stored value without a key.
  external JSAny? get_remote_config([String? key]);

  /// Enrolls the user into the A/B tests of [keys].
  external void enrollUserToAb(JSAny? keys);

  // Performance Monitoring
  /// Sends [trace], a performance trace with type, name, stz, etz and apm_metrics.
  external void report_trace(JSAny trace);

  // Attribution
  /// Records the attribution to the campaign [campaignId] and the campaign user [campaignUserId]. A
  /// missing one is taken from the campaign the page was opened from, and without a campaign the
  /// user is recorded as organic.
  external void recordDirectAttribution([String? campaignId, String? campaignUserId]);

  // Networking
  /// Moves waiting events into the request queue and works through the queue now.
  external void attempt_to_send_stored_requests();

  /// Headers added to every request, read when a request is sent.
  external JSAny? get headers;
  external set headers(JSAny? value);

  // Location, read when a request is prepared
  /// The country code sent with requests.
  external JSAny? get country_code;
  external set country_code(JSAny? value);

  /// The city sent with requests.
  external JSAny? get city;
  external set city(JSAny? value);

  /// The IP address sent with requests.
  external JSAny? get ip_address;
  external set ip_address(JSAny? value);

  /// The content zone calls.
  external CountlyWebContent get content;

  /// The user profile calls.
  external CountlyWebUserData get userData;

  /// The feedback widget calls.
  external CountlyWebFeedback get feedback;

  /// The internal calls, which are not part of the public API.
  @JS('_internals')
  external CountlyWebInternals get internals;
}

/// The content zone members of a Web SDK instance.
@JS()
@staticInterop
class CountlyWebContent {}

/// Members of [CountlyWebContent].
extension CountlyWebContentMembers on CountlyWebContent {
  /// Starts fetching and showing content for the user.
  external void enterContentZone();

  /// Leaves the content zone and enters it again to fetch content now.
  external void refreshContentZone();

  /// Stops fetching content.
  external void exitContentZone();

  /// Keeps [segmentation] for every content and feedback widget event; null or an empty object clears it.
  external void setGlobalContentSegmentation(JSAny? segmentation);
}

/// The user profile members of a Web SDK instance.
@JS()
@staticInterop
class CountlyWebUserData {}

/// Members of [CountlyWebUserData].
extension CountlyWebUserDataMembers on CountlyWebUserData {
  /// Sets the custom property [key] to [value].
  external void set(String key, JSAny? value);

  /// Sets the custom property [key] to [value] unless it has a value already.
  external void set_once(String key, JSAny? value);

  /// Increments the custom property [key] by one.
  external void increment(String key);

  /// Increments the custom property [key] by [value].
  external void increment_by(String key, int value);

  /// Multiplies the custom property [key] by [value].
  external void multiply(String key, int value);

  /// Keeps the larger of the custom property [key] and [value].
  external void max(String key, int value);

  /// Keeps the smaller of the custom property [key] and [value].
  external void min(String key, int value);

  /// Adds [value] to the array custom property [key].
  external void push(String key, JSAny? value);

  /// Adds [value] to the array custom property [key] unless it is there already.
  external void push_unique(String key, JSAny? value);

  /// Removes [value] from the array custom property [key].
  external void pull(String key, JSAny? value);

  /// Sends the custom property changes made since the last save.
  external void save();
}

/// The feedback members of a Web SDK instance.
@JS()
@staticInterop
class CountlyWebFeedback {}

/// Members of [CountlyWebFeedback].
extension CountlyWebFeedbackMembers on CountlyWebFeedback {
  /// Shows the NPS widget with the name, tag or ID [nameTagOrID], or the first one.
  external void showNPS(String? nameTagOrID);

  /// Shows the survey widget with the name, tag or ID [nameTagOrID], or the first one.
  external void showSurvey(String? nameTagOrID);

  /// Shows the rating widget with the name, tag or ID [nameTagOrID], or the first one.
  external void showRating(String? nameTagOrID);
}

/// The internal members of a Web SDK instance that the tests read.
@JS()
@staticInterop
class CountlyWebInternals {}

/// Members of [CountlyWebInternals].
extension CountlyWebInternalsMembers on CountlyWebInternals {
  /// The requests waiting to be sent.
  external JSArray getRequestQueue();

  /// The events waiting to be moved into a request.
  external JSArray getEventQueue();
}
