@JS()
library countly;

import 'package:js/js.dart';
import 'js_object.dart';

@JS()
@anonymous
class CountlyEvent {
  external factory CountlyEvent({
    String key,
    Segmentation? segmentation,
    num? count,
    num? dur,
    num? sum,
  });

  external String get key;
  external Segmentation? get segmentation;
  external num? get count;
  external num? get dur;
  external num? get sum;
}

@JS()
@anonymous
class Segmentation {
  external factory Segmentation({
    String data,
  });
  external String get data;
}

@JS('Countly')
class CountlyJs {
  external static CountlyInstanceJs init();
  external static String get app_key;
  external static set app_key(String value);
  external static String get url;
  external static set url(String value);
  external static List get q;
}

@JS()
@anonymous
class CountlyInstanceJs {
  external void log_error(JsObject err, String? segments);
  external void add_event(CountlyEvent event);
  external void track_pageview(
      String page, List? ignoreList, JsObject viewSegments);
}
