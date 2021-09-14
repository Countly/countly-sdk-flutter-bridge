// ignore_for_file: non_constant_identifier_names

@JS()
library countly;


import 'package:js/js.dart';

@JS()
@anonymous
class CountlyEvent {
  external factory CountlyEvent({
    String key,
    Segmentation segmentation,
    num? count,
    num? dur,
    num? sum,
  });

  external String get key;
  external Segmentation get segmentation;
  external num? get count;
  external num? get dur;
  external num? get sum;
}

@JS()
@anonymous
class Segmentation {
  external factory Segmentation({
    SegData data,
  });
}

@JS()
@anonymous
class SegData {
  external factory SegData({String id});
}

@JS('Countly')
class CountlyJs {
  external static void init();
  external static String get app_key;
  external static set app_key(String value);
  external static String get url;
  external static set url(String value);
  external static void add_event(CountlyEvent event);
  external static void track_pageview(String pageName);
  external static List get q;
}

void setupCountlyForWeb(String serverUrl, String appKey) async {
  CountlyJs.app_key = appKey;
  CountlyJs.url = serverUrl;

  CountlyJs.q.add([
    ['track_sessions'],
    ['track_pageview'],
    ['track_clicks'],
    ['track_scrolls']
  ]);

  CountlyJs.init();

  //for testing purposes
  CountlyJs.add_event(
    CountlyEvent(
      key: 'eventFromCountlyInterop',
      segmentation: Segmentation(
        data: SegData(id: 'abc'),
      ),
    ),
  );
}
