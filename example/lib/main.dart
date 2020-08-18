import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:countly_flutter/countly_flutter.dart';

/// This or a similar call needs to added to catch and report Dart Errors to Countly,
/// You need to run app inside a Zone
/// and provide the [Countly.recordDartError] callback for [onError()]
void main() {
  runZonedGuarded<Future<void>>(() async {
    runApp(MyApp());
  }, Countly.recordDartError);
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    Countly.isInitialized().then((bool isInitialized){
      if(!isInitialized){

        /// Recommended settings for Countly initialisation
        Countly.setLoggingEnabled(true); // Enable countly internal debugging logs
        Countly.enableCrashReporting(); // Enable crash reporting to report unhandled crashes to Countly
        Countly.setRequiresConsent(true); // Set that consent should be required for features to work.
        Countly.setAutomaticViewTracking(true); // Enable automatic view tracking

        /// Optional settings for Countly initialisation
        Countly.enableParameterTamperingProtection("salt"); // Set the optional salt to be used for calculating the checksum of requested data which will be sent with each request
        Countly.setHttpPostForced(false); // Set to "true" if you want HTTP POST to be used for all requests
        Countly.enableApm(); // Enable APM features, which includes the recording of app start time.
        Countly.enableAttribution(); // Enable to measure your marketing campaign performance by attributing installs from specific campaigns.

        Countly.setRemoteConfigAutomaticDownload((result){
          print(result);
        }); // Set Automatic value download happens when the SDK is initiated or when the device ID is changed.
        var segment = {"Key": "Value"};
        Countly.setCustomCrashSegment(segment); // Set optional key/value segment added for crash reports.
        Countly.eventSendThreshold(10); // Should be used only if you know what you are doing. Set event grouping threshold value. The default is 10.
        Countly.init(SERVER_URL, APP_KEY).then((value){

          /// Push notifications settings
          /// Should be call after init
          Countly.pushTokenType(Countly.messagingMode["TEST"]); // Set messaging mode for push notifications
          Countly.onNotification((String notification){
            print("The notification");
            print(notification);
          }); // Set callback to receive push notifications
          Countly.askForNotificationPermission(); // This method will ask for permission, enables push notification and send push token to countly server.;

          Countly.giveAllConsent(); // give consent for all features, should be call after init
//        Countly.giveConsent(["events", "views"]); // give consent for some specific features, should be call after init.
        }); // Initialize the countly SDK.
      }else{
        print("Countly: Already initialized.");
      }
    });
  }

  // ignore: non_constant_identifier_names
  static String SERVER_URL = "https://try.count.ly";
  // ignore: non_constant_identifier_names
  static String APP_KEY = "YOUR_API_KEY";

  enableTemporaryIdMode(){
    Countly.changeDeviceId(Countly.deviceIDType["TemporaryDeviceID"], false);
  }
  start(){
    Countly.start();
  }
  manualSessionHandling(){
    Countly.manualSessionHandling();
  }
  stop(){
    Countly.stop();
  }
  basicEvent(){
    // example for basic event
    var event = {
      "key": "Basic Event",
      "count": 1
    };
    Countly.recordEvent(event);
  }
  eventWithSum(){
    // example for event with sum
    var event = {
      "key": "Event With Sum",
      "count": 1,
      "sum": "0.99",
    };
    Countly.recordEvent(event);
  }
  eventWithSegment(){
    // example for event with segment
    var event = {
      "key": "Event With Segment",
      "count": 1
    };
    event["segmentation"] = {
      "Country": "Turkey",
      "Age": "28"
    };
    Countly.recordEvent(event);
  }

  eventWithSumSegment(){
    // example for event with segment and sum
    var event = {
      "key": "Event With Sum And Segment",
      "count": 1,
      "sum": "0.99"
    };
    event["segmentation"] = {
      "Country": "Turkey",
      "Age": "28"
    };
    Countly.recordEvent(event);
  }
  endEventBasic(){
    Countly.startEvent("Timed Event");
    Timer timer;
    timer = new Timer(new Duration(seconds: 5), () {
      Countly.endEvent({ "key": "Timed Event" });
      timer.cancel();
    });
  }
  endEventWithSum(){
    Countly.startEvent("Timed Event With Sum");
    Timer timer;
    timer = new Timer(new Duration(seconds: 5), () {
      Countly.endEvent({ "key": "Timed Event With Sum", "sum": "0.99" });
      timer.cancel();
    });
  }
  endEventWithSegment(){
    Countly.startEvent("Timed Event With Segment");
    Timer timer;
    timer = new Timer(new Duration(seconds: 5), () {
      var event = {
        "key": "Timed Event With Segment",
        "count": 1,
      };
      event["segmentation"] = {
        "Country": "Turkey",
        "Age": "28"
      };
      Countly.endEvent(event);
      timer.cancel();
    });
  }
  endEventWithSumSegment(){
    Countly.startEvent("Timed Event With Segment, Sum and Count");
    Timer timer;
    timer = new Timer(new Duration(seconds: 5), () {
      var event = {
        "key": "Timed Event With Segment, Sum and Count",
        "count": 1,
        "sum": "0.99"
      };
      event["segmentation"] = {
        "Country": "Turkey",
        "Age": "28"
      };
      Countly.endEvent(event);
      timer.cancel();
    });
  }
  recordViewHome(){
    Map<String, Object> segments = {
      "Key_1": "Value_1",
      "Key_2": "Value_2"
    };
    Countly.recordView("HomePage", segments);
  }
  recordViewDashboard(){
    Countly.recordView("Dashboard");
  }
  String makeid(){
    int code = new Random().nextInt(999999);
    String random = code.toString();
    print(random);
    return random;
  }
  setCaptianAmericaData(){
    // example for setCaptianAmericaData
    var deviceId = makeid();
    Countly.changeDeviceId(deviceId, false);

    Map<String, Object> options = {
      "name": "Captian America",
      "username": "captianamerica",
      "email": "captianamerica@avengers.com",
      "organization": "Avengers",
      "phone": "+91 555 555 5555",
      "picture": "http://icons.iconarchive.com/icons/hopstarter/superhero-avatar/256/Avengers-Captain-America-icon.png",
      "picturePath": "",
      "gender": "M", // "F"
      "byear": "1989",
    };
    Countly.setUserData(options);
  }
  setIronManData(){
    // example for setIronManData
    var deviceId = makeid();
    Countly.changeDeviceId(deviceId, false);

    Map<String, Object> options = {
      "name": "Iron Man",
      "username": "ironman",
      "email": "ironman@avengers.com",
      "organization": "Avengers",
      "phone": "+91 555 555 5555",
      "picture": "http://icons.iconarchive.com/icons/hopstarter/superhero-avatar/256/Avengers-Iron-Man-icon.png",
      "picturePath": "",
      "gender": "M", // "F"
      "byear": "1989",
    };
    Countly.setUserData(options);
    Countly.start();
  }
  setSpiderManData(){
    var deviceId = makeid();
    Countly.changeDeviceId(deviceId, false);

    Map<String, Object> options = {
      "name": "Spider-Man",
      "username": "spiderman",
      "email": "spiderman@avengers.com",
      "organization": "Avengers",
      "phone": "+91 555 555 5555",
      "picture": "http://icons.iconarchive.com/icons/mattahan/ultrabuuf/512/Comics-Spiderman-Morales-icon.png",
      "picturePath": "",
      "gender": "M", // "F"
      "byear": "1989"
    };
    Countly.setUserData(options);
    Countly.start();
  }
  setUserData(){
    Map<String, Object> options = {
      "name": "Trinisoft Technologies",
      "username": "trinisofttechnologies",
      "email": "trinisofttechnologies@gmail.com",
      "organization": "Trinisoft Technologies Pvt. Ltd.",
      "phone": "+91 812 840 2946",
      "picture": "https://avatars0.githubusercontent.com/u/10754117?s=400&u=fe019f92d573ac76cbfe7969dde5e20d7206975a&v=4",
      "picturePath": "",
      "gender": "M", // "F"
      "byear": "1989",
    };
    Countly.setUserData(options);
  }
  setProperty(){
    Countly.setProperty("setProperty", "My Property");
  }
  increment(){
    Countly.increment("increment");
  }
  incrementBy(){
    Countly.incrementBy("incrementBy", 10);
  }
  multiply(){
    Countly.multiply("multiply", 20);
  }
   saveMax(){
    Countly.saveMax("saveMax", 100);
  }
  saveMin(){
    Countly.saveMin("saveMin", 50);
  }
  setOnce(){
    Countly.setOnce("setOnce", "200");
  }
  pushUniqueValue(){
    Countly.pushUniqueValue("pushUniqueValue", "morning");
  }
  pushValue(){
    Countly.pushValue("pushValue", "morning");
  }
  pullValue(){
    Countly.pullValue("pushValue", "morning");
  }
  //
  giveMultipleConsent(){
    Countly.giveConsent(["events", "views", "star-rating", "crashes"]);
  }
  removeMultipleConsent(){
    Countly.removeConsent(["events", "views", "star-rating", "crashes"]);
  }
  giveAllConsent() {
    Countly.giveAllConsent();
  }
  removeAllConsent(){
    Countly.removeAllConsent();
  }

  giveConsentSessions(){
    Countly.giveConsent(["sessions"]);
  }
  giveConsentEvents(){
    Countly.giveConsent(["events"]);
  }
  giveConsentViews(){
    Countly.giveConsent(["views"]);
  }
  giveConsentLocation(){
    Countly.giveConsent(["location"]);
  }
  giveConsentCrashes(){
    Countly.giveConsent(["crashes"]);
  }
  giveConsentAttribution(){
    Countly.giveConsent(["attribution"]);
  }
  giveConsentUsers(){
    Countly.giveConsent(["users"]);
  }
  giveConsentPush(){
    Countly.giveConsent(["push"]);
  }
  giveConsentStarRating(){
    Countly.giveConsent(["star-rating"]);
  }
  giveConsentAPM(){
  Countly.giveConsent(["apm"]);
  }

  removeConsentsessions(){
    Countly.removeConsent(["sessions"]);
  }
  removeConsentEvents(){
    Countly.removeConsent(["events"]);
  }
  removeConsentViews(){
    Countly.removeConsent(["views"]);
  }
  removeConsentlocation(){
    Countly.removeConsent(["location"]);
  }
  removeConsentcrashes(){
    Countly.removeConsent(["crashes"]);
  }
  removeConsentattribution(){
    Countly.removeConsent(["attribution"]);
  }
  removeConsentusers(){
    Countly.removeConsent(["users"]);
  }
  removeConsentpush(){
    Countly.removeConsent(["push"]);
  }
  removeConsentstarRating(){
    Countly.removeConsent(["star-rating"]);
  }
  removeConsentAPM(){
    Countly.removeConsent(["apm"]);
  }

  askForNotificationPermission(){
    Countly.askForNotificationPermission();
  }
  remoteConfigUpdate(){
    Countly.remoteConfigUpdate((result){
      print(result);
    });
  }
  updateRemoteConfigForKeysOnly(){
    Countly.updateRemoteConfigForKeysOnly(["name"],(result){
      print(result);
    });
  }
  getRemoteConfigValueForKeyString(){
    Countly.getRemoteConfigValueForKey("stringValue",(result){
      print(result);
    });
  }
  getRemoteConfigValueForKeyBoolean(){
    Countly.getRemoteConfigValueForKey("booleanValue",(result){
      print(result);
    });
  }
  getRemoteConfigValueForKeyFloat(){
    Countly.getRemoteConfigValueForKey("floatValue",(result){
      print(result);
    });
  }
  getRemoteConfigValueForKeyInteger(){
    Countly.getRemoteConfigValueForKey("integerValue",(result){
      print(result);
    });
  }

  updateRemoteConfigExceptKeys(){
    Countly.updateRemoteConfigExceptKeys(["url"],(result){
      print(result);
    });
  }

  remoteConfigClearValues(){
    Countly.remoteConfigClearValues((result){
      print(result);
    });
  }

  getRemoteConfigValueForKey(){
    Countly.getRemoteConfigValueForKey("name", (result){
      print(result);
    });
  }

  changeDeviceIdWithMerge(){
    Countly.changeDeviceId("123456", true);
  }
  changeDeviceIdWithoutMerge(){
    Countly.changeDeviceId("123456", false);
  }
  enableParameterTamperingProtection(){
    Countly.enableParameterTamperingProtection("salt");
  }
   setOptionalParametersForInitialization(){
    Map<String, Object> options = {
      "city": "Tampa",
      "country": "US",
      "latitude": "28.006324",
      "longitude": "-82.7166183",
      "ipAddress": "255.255.255.255"
    };
    Countly.setOptionalParametersForInitialization(options);
  }

  addCrashLog(){
    Countly.enableCrashReporting();
    Countly.addCrashLog("User Performed Step A");
    Timer timer;
    timer = new Timer(new Duration(seconds: 5), () {
      Countly.logException("one.js \n two.js \n three.js", true, {"_facebook_version": "0.0.1"});
      timer.cancel();
    });
  }
  causeException(){
    Map<String, Object> options = json.decode("This is a on purpose error.");
  }

  throwException() {
    throw new StateError('This is an thrown Dart exception.');
  }

  throwNativeException() {
    Countly.throwNativeException();
  }

  throwExceptionAsync() async {
    foo() async {
      throw new StateError('This is an async Dart exception.');
    }
    bar() async {
      await foo();
    }
    await bar();
  }

  recordExceptionManually() {
    Countly.logException("This is a manually created exception", true, null);
  }

  dividedByZero() {
    try {
      int firstInput = 20;
      int secondInput = 0;
      int result = firstInput ~/ secondInput;
      print('The result of $firstInput divided by $secondInput is $result');
    } catch (e, s) {
      print('Exception occurs: $e');
      print('STACK TRACE\n: $s');
      Countly.logExceptionEx(e, true, stacktrace: s);
    }
  }

  setLoggingEnabled(){
    Countly.setLoggingEnabled(false);
  }
  askForStarRating(){
    Countly.askForStarRating();
  }
  askForFeedback(){
    Countly.askForFeedback("5e391ef47975d006a22532c0", "Close");
  }
  setLocation(){
    Countly.setLocation("-33.9142687","18.0955802");
  }

  // APM Examples
  startTrace(){
    String traceKey = "Trace Key";
    Countly.startTrace(traceKey);
  }
  endTrace(){
    String traceKey = "Trace Key";
    Map<String, int> customMetric = {
      "ABC": 1233,
      "C44C": 1337
    };
    Countly.endTrace(traceKey, customMetric);
  }
  List<int> successCodes = [100, 101, 200, 201, 202, 205, 300, 301, 303, 305];
  List<int> failureCodes = [400, 402, 405, 408, 500, 501, 502, 505];
  recordNetworkTraceSuccess(){
    String networkTraceKey = "api/endpoint.1";
    var rnd = new Random();
    int responseCode = successCodes[rnd.nextInt(successCodes.length)];
    int requestPayloadSize = rnd.nextInt(700) + 200;
    int responsePayloadSize = rnd.nextInt(700) + 200;
    int startTime = new DateTime.now().millisecondsSinceEpoch;
    int endTime = startTime + 500;
    Countly.recordNetworkTrace(networkTraceKey, responseCode, requestPayloadSize, responsePayloadSize, startTime, endTime);
  }
  recordNetworkTraceFailure(){
    String networkTraceKey = "api/endpoint.1";
    var rnd = new Random();
    int responseCode = failureCodes[rnd.nextInt(failureCodes.length)];
    int requestPayloadSize = rnd.nextInt(700) + 250;
    int responsePayloadSize = rnd.nextInt(700) + 250;
    int startTime = new DateTime.now().millisecondsSinceEpoch;
    int endTime = startTime + 500;
    Countly.recordNetworkTrace(networkTraceKey, responseCode, requestPayloadSize, responsePayloadSize, startTime, endTime);
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Countly SDK Dart Demo'),
        ),
        body: Center(
          child: SingleChildScrollView(child:
            Column(children: <Widget>[
              MyButton(text: "Start", color: "green", onPressed: start),
              MyButton(text: "Stop", color: "red", onPressed: stop),

              MyButton(text: "Basic event", color: "brown", onPressed: basicEvent),
              MyButton(text: "Event with Sum", color: "brown", onPressed: eventWithSum),
              MyButton(text: "Event with Segment", color: "brown", onPressed: eventWithSegment),
              MyButton(text: "Even with Sum and Segment", color: "brown", onPressed: eventWithSumSegment),
              MyButton(text: "Timed event: Start / Stop", color: "grey", onPressed: endEventBasic),
              MyButton(text: "Timed event Sum: Start / Stop", color: "grey", onPressed: endEventWithSum),
              MyButton(text: "Timed event Segment: Start / Stop", color: "grey", onPressed: endEventWithSegment),
              MyButton(text: "Timed event Sum Segment: Start / Stop", color: "grey", onPressed: endEventWithSumSegment),

              MyButton(text: "Record View: 'HomePage'", color: "olive", onPressed: recordViewHome),
              MyButton(text: "Record View: 'Dashboard'", color: "olive", onPressed: recordViewDashboard),

              MyButton(text: "Send Captian America Data", color: "teal", onPressed: setCaptianAmericaData),
              MyButton(text: "Send Iron Man Data", color: "teal", onPressed: setIronManData),
              MyButton(text: "Send Spider-Man Data", color: "teal", onPressed: setSpiderManData),
              MyButton(text: "Send Users Data", color: "teal", onPressed: setUserData),
              MyButton(text: "UserData.setProperty", color: "teal", onPressed: setProperty),
              MyButton(text: "UserData.increment", color: "teal", onPressed: increment),
              MyButton(text: "UserData.incrementBy", color: "teal", onPressed: incrementBy),
              MyButton(text: "UserData.multiply", color: "teal", onPressed: multiply),
              MyButton(text: "UserData.saveMax", color: "teal", onPressed: saveMax),
              MyButton(text: "UserData.saveMin", color: "teal", onPressed: saveMin),
              MyButton(text: "UserData.setOnce", color: "teal", onPressed: setOnce),
              MyButton(text: "UserData.pushUniqueValue", color: "teal", onPressed: pushUniqueValue),
              MyButton(text: "UserData.pushValue", color: "teal", onPressed: pushValue),
              MyButton(text: "UserData.pullValue", color: "teal", onPressed: pullValue),

              MyButton(text: "Give multiple consent", color: "blue", onPressed: giveMultipleConsent),
              MyButton(text: "Remove multiple consent", color: "blue", onPressed: removeMultipleConsent),
              MyButton(text: "Give all Consent", color: "blue", onPressed: giveAllConsent),
              MyButton(text: "Remove all Consent", color: "blue", onPressed: removeAllConsent),

              MyButton(text: "Give Consent Sessions", color: "blue", onPressed: giveConsentSessions),
              MyButton(text: "Give Consent Events", color: "blue", onPressed:giveConsentEvents),
              MyButton(text: "Give Consent Views", color: "blue", onPressed: giveConsentViews),
              MyButton(text: "Give Consent Location", color: "blue", onPressed: giveConsentLocation),
              MyButton(text: "Give Consent Crashes", color: "blue", onPressed: giveConsentCrashes),
              MyButton(text: "Give Consent Attribution", color: "blue", onPressed:giveConsentAttribution),
              MyButton(text: "Give Consent Users", color: "blue", onPressed: giveConsentUsers),
              MyButton(text: "Give Consent Push", color: "blue", onPressed: giveConsentPush),
              MyButton(text: "Give Consent starRating", color: "blue", onPressed: giveConsentStarRating),
              MyButton(text: "Give Consent Performance", color: "blue", onPressed: giveConsentAPM),


              MyButton(text: "Remove Consent Sessions", color: "blue", onPressed: removeConsentsessions),
              MyButton(text: "Remove Consent Events", color: "blue", onPressed:removeConsentEvents),
              MyButton(text: "Remove Consent Views", color: "blue", onPressed: removeConsentViews),
              MyButton(text: "Remove Consent Location", color: "blue", onPressed: removeConsentlocation),
              MyButton(text: "Remove Consent Crashes", color: "blue", onPressed: removeConsentcrashes),
              MyButton(text: "Remove Consent Attribution", color: "blue", onPressed:removeConsentattribution),
              MyButton(text: "Remove Consent Users", color: "blue", onPressed: removeConsentusers),
              MyButton(text: "Remove Consent Push", color: "blue", onPressed: removeConsentpush),
              MyButton(text: "Remove Consent starRating", color: "blue", onPressed: removeConsentstarRating),
              MyButton(text: "Remove Consent Performance", color: "blue", onPressed: removeConsentAPM),



              MyButton(text: "Countly.remoteConfigUpdate", color: "purple", onPressed: remoteConfigUpdate),
              MyButton(text: "Countly.updateRemoteConfigForKeysOnly", color: "purple", onPressed: updateRemoteConfigForKeysOnly),
              MyButton(text: "Countly.updateRemoteConfigExceptKeys", color: "purple", onPressed: updateRemoteConfigExceptKeys),
              MyButton(text: "Countly.remoteConfigClearValues", color: "purple", onPressed: remoteConfigClearValues),
              MyButton(text: "Get String Value", color: "purple", onPressed: getRemoteConfigValueForKeyString),
              MyButton(text: "Get Boolean Value", color: "purple", onPressed: getRemoteConfigValueForKeyBoolean),
              MyButton(text: "Get Float Value", color: "purple", onPressed: getRemoteConfigValueForKeyFloat),
              MyButton(text: "Get Integer Value", color: "purple", onPressed: getRemoteConfigValueForKeyInteger),

              MyButton(text: "Push Notification", color: "primary", onPressed: askForNotificationPermission),

              MyButton(text: "Enable Temporary ID Mode", color: "violet", onPressed: enableTemporaryIdMode),
              MyButton(text: "Change Device ID With Merge", color: "violet", onPressed: changeDeviceIdWithMerge),
              MyButton(text: "Change Device ID Without Merge", color: "violet", onPressed: changeDeviceIdWithoutMerge),
              MyButton(text: "Enable Parameter Tapmering Protection", color: "violet", onPressed: enableParameterTamperingProtection),
              MyButton(text: "City, State, and Location", color: "violet", onPressed: setOptionalParametersForInitialization),
              MyButton(text: "setLocation", color: "violet", onPressed: setLocation),

              MyButton(text: "Send Crash Report", color: "violet", onPressed: addCrashLog),
              MyButton(text: "Cause Exception", color: "violet", onPressed: causeException),
              MyButton(text: "Throw Exception", color: "violet", onPressed: throwException),

              MyButton(text: "Throw Exception Async", color: "violet", onPressed: throwExceptionAsync),
              MyButton(text: "Throw Native Exception", color: "violet", onPressed: throwNativeException),
              MyButton(text: "Record Exception Manually", color: "violet", onPressed: recordExceptionManually),
              MyButton(text: "Divided By Zero Exception", color: "violet", onPressed: dividedByZero),

              MyButton(text: "Enabling logging", color: "violet", onPressed: setLoggingEnabled),

              MyButton(text: "Open rating modal", color: "orange", onPressed: askForStarRating),
              MyButton(text: "Open feedback modal", color: "orange", onPressed: askForFeedback),

              MyButton(text: "Start Trace", color: "black", onPressed: startTrace),
              MyButton(text: "End Trace", color: "black", onPressed: endTrace),
              MyButton(text: "Record Network Trace Success", color: "black", onPressed: recordNetworkTraceSuccess),
              MyButton(text: "Record Network Trace Failure", color: "black", onPressed: recordNetworkTraceFailure),
            ],),
          )
        ),
      ),
    );
  }
}

Map<String, Object> theColor = {
  "default": {
    "button": Color(0xffe0e0e0),
    "text": Color(0xff000000)
  },
  "red": {
    "button": Color(0xffdb2828),
    "text": Color(0xff000000)
  },
  "green": {
    "button": Colors.green,
    "text": Color(0xffffffff)
  },
  "teal": {
    "button": Color(0xff00b5ad),
    "text": Color(0xff000000)
  },
  "blue": {
    "button": Color(0xff00b5ad),
    "text": Color(0xff000000)
  },
  "primary": {
    "button": Color(0xff54c8ff),
    "text": Color(0xff000000)
  },
  "grey": {
    "button": Color(0xff767676),
    "text": Color(0xff000000)
  },
  "brown": {
    "button": Color(0xffa5673f),
    "text": Color(0xff000000)
  },
  "purple": {
    "button": Color(0xffa333c8),
    "text": Color(0xff000000)
  },
  "violet": {
    "button": Color(0xff6435c9),
    "text": Color(0xff000000)
  },
  "yellow": {
    "button": Color(0xfffbbd08),
    "text": Color(0xffffffff)
  },
  "black": {
    "button": Color(0xff1b1c1d),
    "text": Color(0xffffffff)
  },
  "olive": {
    "button": Color(0xffd9e778),
    "text": Color(0xff000000)
  },
  "orange": {
    "button": Color(0xffff851b),
    "text": Color(0xff000000)
  }

};
Map<String, Object> getColor(color){
  if(color == "green"){
    return theColor["green"];
  }else if(color == "teal"){
    return theColor["teal"];
  }else if(color == "red"){
    return theColor["red"];
  }else if(color == "brown"){
    return theColor["brown"];
  }else if(color == "grey"){
    return theColor["grey"];
  }else if(color == "blue"){
    return theColor["blue"];
  }else if(color == "purple"){
    return theColor["purple"];
  }else if(color == "primary"){
    return theColor["primary"];
  }else if(color == "violet"){
    return theColor["violet"];
  }else if(color == "black"){
    return theColor["black"];
  }else if(color == "olive"){
    return theColor["olive"];
  }else if(color == "orange"){
    return theColor["orange"];
  }else{
    return theColor["default"];
  }
}
class MyButton extends StatelessWidget{
  String _text;
  Color _button;
  Color _textC;
  Function _onPressed;
  MyButton({String color, String text, Function onPressed}){
    _text = text;

    Map<String, Object> tColor;
    tColor = getColor(color);
    if(tColor == null){
      tColor = theColor["default"];
    }
    _button = tColor["button"];
    _textC = tColor["text"];

    _onPressed = onPressed;
  }

  @override
  Widget build(BuildContext context){
    return new RaisedButton(
      onPressed: _onPressed,
      color: _button,
      child: SizedBox(
        width: double.maxFinite,
        child: Text(_text, style: new TextStyle(color: _textC),textAlign: TextAlign.center)
        )
    );
  }
}
