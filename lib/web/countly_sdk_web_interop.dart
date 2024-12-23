// ignore_for_file: non_constant_identifier_names

import 'dart:js_interop';

@JS('Countly') // Bind to the global 'Countly' object
@staticInterop
class Countly {
  external static JSArray get features;
  external static String? get salt;

  external static void init(JSAny config);

  // Events
  external static void add_event(JSAny event);
  external static void start_event(String key);
  external static void end_event(JSAny event);

  // Session Management
  external static void begin_session();
  external static void track_sessions(); // Auto session tracking
  external static void end_session();

  // Device ID Management
  external static String get_device_id();
  external static void set_id(String id);
  external static int get_device_id_type();
  external static void change_id(String newId, bool merge);
  external static void enable_offline_mode();

  // Consents
  external static void add_consent(JSAny consents);
  external static void remove_consent(JSAny consents);

  // View Management
  external static void track_view(String viewName, JSArray? ignoreList, JSAny? segments);

  // Crashes
  external static void track_errors(JSAny? globalSegmennts);
  external static void recordError(JSAny error, bool nonfatal, JSAny? segments);
  external static void add_log(String log); // breadcrumb

  // User Profiles
  external static void user_details(JSAny userDetails);

  // Feedback
  external static void get_available_feedback_widgets(JSAny? callback);
  external static void present_feedback_widget(JSAny? presentableFeedback, String? id, String? className, JSAny? feedbackWidgetSegmentation);
  external static void getFeedbackWidgetData(JSAny? CountlyFeedbackWidget, JSAny? callback);
  external static void reportFeedbackWidgetManually(JSAny? CountlyFeedbackWidget, JSAny? CountlyWidgetData, JSAny? widgetResult);

  // Remote Config
  external static void fetch_remote_config(JSArray? keys, JSArray? omit_keys, JSAny? callback);
  external static JSAny get_remote_config();
}

@JS('Countly.content') // Bind to 'Countly.content'
@staticInterop
class CountlyContent {
  external static void enterContentZone();
  external static void exitContentZone();
}

@JS('Countly.userData') // Bind to 'Countly.userData'
@staticInterop
class CountlyUserData {
  external static void set(String key, JSAny? value);
  external static void set_once(String key, JSAny? value);
  external static void increment(String key);
  external static void increment_by(String key, int value);
  external static void multiply(String key, int value);
  external static void max(String key, int value);
  external static void min(String key, int value);
  external static void push(String key, JSAny? value);
  external static void push_unique(String key, JSAny? value);
  external static void pull(String key, JSAny? value);
  external static void save();
}

@JS('Countly.feedback') // Bind to 'Countly.feedback'
@staticInterop
class CountlyFeedback {
  external static void showNPS(String? nameTagOrID);
  external static void showSurvey(String? nameTagOrID);
  external static void showRating(String? nameTagOrID);
}

@JS('Countly._internals') // Bind to 'Countly._internals'
@staticInterop
class CountlyInternal {
  external static JSArray getRequestQueue();
  external static JSArray getEventQueue();
}
