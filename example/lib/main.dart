import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:countly/countly.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  onInit(){
    Countly.init("https://try.count.ly", "0e8a00e8c01395a0af8be0e55da05a404bb23c3e");
  }
  initWithID(){
    Countly.init("https://try.count.ly", "0e8a00e8c01395a0af8be0e55da05a404bb23c3e", "1234567890");
  }
  start(){
    Countly.start();
  }
  stop(){
    Countly.stop();
  }
  basicEvent(){
    // example for basic event
    var event = {
        "key": "basic_event",
        "count": 1
    };
    Countly.sendEvent(event);
  }
  eventWithSum(){
    // example for event with sum
     var event = {
            "key": "event_sum",
            "count": 1,
            "sum": "0.99"
        };
        Countly.sendEvent(event);
  }
  eventWithSegment(){
     // example for event with segment
        var event = {
            "key": "event_segment",
            "count": 1
        };
        event["segment"] = {
            "Country": "Turkey",
            "Age": "28"
        };
        Countly.sendEvent(event);
  }

  eventWithSumSegment(){
    // example for event with segment and sum
        var event = {
            "key": "event_segment_sum",
            "count": 1,
            "sum": "0.99"
        };
        event["segment"] = {
            "Country": "Turkey",
            "Age": "28"
        };
        Countly.sendEvent(event);
  }
  event(){
    // setInterval(function() {
            // app.sendSampleEvent();
        // }, 1000);
  }
  endEventBasic(){
    Countly.startEvent("Timed Event");
        // setTimeout(function() {
        Timer timer;
        timer = new Timer(new Duration(seconds: 5), () {
          Countly.endEvent({ "key": "Timed Event" });
          timer.cancel();
        });


        // }, 1000);
  }
endEventWithSum(){
     Countly.startEvent("Timed Event With Sum");
        // setTimeout(function() {
        Timer timer;
        timer = new Timer(new Duration(seconds: 5), () {
          Countly.endEvent({ "key": "Timed Event With Sum", "sum": "0.99" });
          timer.cancel();
        });

        // }, 1000);
  }
  endEventWithSegment(){
    Countly.startEvent("Timed Event With Segment");
    //     // setTimeout(function() {
      Timer timer;
      var event = {
          "key": "Timed Event With Segment",
          "segment": {
              "Country": "Turkey",
              "Age": "28"
          }
      };

      timer = new Timer(new Duration(seconds: 5), () {
        Countly.endEvent(event);
        timer.cancel();
      });

    //     // }, 1000);
  }
  endEventWithSumSegment(){
    Countly.startEvent("Timed Event With Segment, Sum and Count");
    //     setTimeout(function() {
      Timer timer;
      timer = new Timer(new Duration(seconds: 5), () {
        var event = {
            "key": "Timed Event With Segment, Sum and Count",
            "count": 1,
            "sum": "0.99"
        };
        event["segment"] = {
            "Country": "Turkey",
            "Age": "28"
        };
        Countly.endEvent(event);
        timer.cancel();
      });

    //     }, 1000);
  }
  recordViewHome(){
    Countly.recordView("HomePage");
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
       Countly.setOnce("setOnce", 200);
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
  setRequiresConsent(){
    Countly.setRequiresConsent(true);
  }
  giveMultipleConsent(){
    Countly.giveConsent(["events", "views", "star-rating", "crashes"]);
  }
  removeMultipleConsent(){
    Countly.removeConsent(["events", "views", "star-rating", "crashes"]);
  }
  giveAllConsent(){
    Countly.giveAllConsent();
  }
  removeAllConsent(){
    Countly.removeAllConsent();
  }
  sendPushToken(){
      //  var push = PushNotification.init({
      //       android: {sound: true},
      //       ios: {
      //           alert: "true",
      //           badge: "true",
      //           sound: "true"
      //       },
      //       windows: {}
      //   });

      //   push.on('registration', function(data) {
      //       alert('Token received: '+data.registrationId);
      //       Countly.sendPushToken({
      //           "token": data.registrationId,
      //           "messagingMode": Countly.messagingMode.DEVELOPMENT
      //       });
      //   });

      //   push.on('notification', function(data) {
      //       alert(JSON.stringify(data));
      //       // data.message,
      //       // data.title,
      //       // data.count,
      //       // data.sound,
      //       // data.image,
      //       // data.additionalData
      //   });

        // // Test android 8.0 and 9.0
        // push.subscribe('myTopic', function(n){
        //     alert(JSON.stringify(n));
        // }, function(e){
        //     alert(JSON.stringify(e));
        // });

        // push.on('error', function(e) {
        //     // e.message
        // });
        // Countly.messagingMode.DEVELOPMENT
        // Countly.messagingMode.PRODUCTION
        // Countly.messagingMode.ADHOC
        // Countly.mode = Countly.messagingMode.DEVELOPMENT;
        // Countly.Push.onRegisterPushNotification();
        // @depricated: The below commented method is depricated and no longer works.
        // Countly.initMessaging({
        //     "messageMode": Countly.messagingMode.TEST,
        //     "projectId": "881000050249"
        // });

        // Tesing purpose only

  }
  setRemoteConfigAutomaticDownload(){
    Countly.setRemoteConfigAutomaticDownload((r){
        print(r);
    });
  }
  remoteConfigUpdate(){
    Countly.remoteConfigUpdate((r){
       print(r);
    },(r){
      print(r);
    });
  }
  updateRemoteConfigForKeysOnly(){
    Countly.updateRemoteConfigForKeysOnly(["name"],(r){
        print(r);
    }, (r){
        print(r);
    });
  }
  updateRemoteConfigExceptKeys(){
    Countly.updateRemoteConfigExceptKeys(["url"],(r){
        print(r);
    },(r){
        print(r);
    });
  }

  remoteConfigClearValues(){
    Countly.remoteConfigClearValues((r){
        print(r);
    }, (r){
        print(r);
    });
  }

  getRemoteConfigValueForKey(){
    Countly.getRemoteConfigValueForKey("name", (r){
        print(r);
    },(r){
        print(r);
    });
  }

  testAndroidPush(){
    Countly.sendPushToken({
        "token": "1234567890",
        "messagingMode": Countly.messagingMode["DEVELOPMENT"]
    });
  }


  testiOSPush(){
    Countly.sendPushToken({
        "token": "1234567890",
        "messagingMode": Countly.messagingMode["DEVELOPMENT"]
    });
  }
  changeDeviceId(){
    Countly.changeDeviceId("123456", true);
  }
  enableParameterTamperingProtection(){
    Countly.enableParameterTamperingProtection("salt");
  }
   setOptionalParametersForInitialization(){
     Map<String, Object> options = {
          "city": "Tampa",
          "country": "US",
          "latitude": "28.006324",
          "longitude": "-82.7166183"
      };
      Countly.setOptionalParametersForInitialization(options);
  }
  addCrashLog(){
      Countly.enableCrashReporting();
      //   Countly.addCrashLog("User Performed Step A");
      //   // setTimeout(function() {
      //       Countly.addCrashLog("User Performed Step B");
      //   // }, 1000);
      //   // setTimeout(function() {
      //       Countly.addCrashLog("User Performed Step C");
      //       // console.log("Opps found and error");
      //       // a();
      //   // }, 1000);
  }
  sendRating(){
    Countly.sendRating(5);
  }
  askForStarRating(){
    // Countly.askForStarRating(function(ratingResult){
      // console.log(ratingResult);
    // });
  }
  askForFeedback(){
    // Countly.askForFeedback("5d80915a31ec7124c86df698", function(url){
    //         //
    //         url = "https://try.count.ly/feedback?widget_id=5d80915a31ec7124c86df698&device_id=a02cee5e35b6b8e8&app_key=0e8a00e8c01395a0af8be0e55da05a404bb23c3e";
    //         // open modal + close button with iframe.
    //     });
  }
  logException(){
    Countly.logException();
  }

  setHttpPostForced(){
    // Countly.setHttpPostForced(true);
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
              MyButton(text: "Init", color: "green", onPressed: onInit),
              MyButton(text: "Init with ID", color: "green", onPressed: initWithID),
              MyButton(text: "Start", color: "green", onPressed: start),
              MyButton(text: "Stop", color: "red", onPressed: stop),

              MyButton(text: "Basic event", color: "brown", onPressed: basicEvent),
              MyButton(text: "Event with Sum", color: "brown", onPressed: eventWithSum),
              MyButton(text: "Event with Segment", color: "brown", onPressed: eventWithSegment),
              MyButton(text: "Even with Sum and Segment", color: "brown", onPressed: eventWithSumSegment),

              MyButton(text: "All event", color: "default", onPressed: event),

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

              MyButton(text: "Init Consent", color: "blue", onPressed: setRequiresConsent),
              MyButton(text: "Give multiple consent", color: "blue", onPressed: giveMultipleConsent),
              MyButton(text: "Remove multiple consent", color: "blue", onPressed: removeMultipleConsent),
              MyButton(text: "Give all Consent", color: "blue", onPressed: giveAllConsent),
              MyButton(text: "Remove all Consent", color: "blue", onPressed: removeAllConsent),

              MyButton(text: "Countly.setRemoteConfigAutomaticDownload", color: "purple", onPressed: setRemoteConfigAutomaticDownload),
              MyButton(text: "Countly.remoteConfigUpdate", color: "purple", onPressed: remoteConfigUpdate),
              MyButton(text: "Countly.updateRemoteConfigForKeysOnly", color: "purple", onPressed: updateRemoteConfigForKeysOnly),
              MyButton(text: "Countly.updateRemoteConfigExceptKeys", color: "purple", onPressed: updateRemoteConfigExceptKeys),
              MyButton(text: "Countly.remoteConfigClearValues", color: "purple", onPressed: remoteConfigClearValues),
              MyButton(text: "Countly.getRemoteConfigValueForKey", color: "purple", onPressed: getRemoteConfigValueForKey),

              MyButton(text: "Push Message", color: "primary", onPressed: sendPushToken),
              MyButton(text: "Push Test Android", color: "primary", onPressed: testAndroidPush),
              MyButton(text: "Push Test iOS", color: "primary", onPressed: testiOSPush),

              MyButton(text: "Change Device ID", color: "violet", onPressed: changeDeviceId),
              MyButton(text: "Enable Parameter Tapmering Protection", color: "violet", onPressed: enableParameterTamperingProtection),
              MyButton(text: "City, State, and Location", color: "violet", onPressed: setOptionalParametersForInitialization),
              MyButton(text: "Send Crash Report", color: "violet", onPressed: addCrashLog),

              MyButton(text: "Send 5 star rating!!", color: "orange", onPressed: sendRating),
              MyButton(text: "Open rating modal", color: "orange", onPressed: askForStarRating),
              MyButton(text: "Open feedback modal", color: "orange", onPressed: askForFeedback),

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
  // "teal": {
  //   "button": Color(0xff00b5ad),
  //   "text": Color(0xff000000)
  // },
  "blue": {
    "button": Color(0xff00b5ad),
    "text": Color(0xff000000)
  },
  "black": {
    "button": Color(0xff1b1c1d),
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
    // if(theColor.containsKey(color)){
    //   tColor = theColor[color];
    //   print('mathc');
    // }
    // void forEach(k, v) {
    //   if(k == color){
    //     print("match");
    //     tColor = v;
    //   }
    // }
    // for(var key in theColor){
    //   if(key == color){
    //     print('match');
    //     tColor = theColor[key];
    //   }
    // }
    // theColor.forEach(forEach);
    // tColor = theColor.get(color);
    tColor = getColor(color);
    // print(color);
    // print(tColor);
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
