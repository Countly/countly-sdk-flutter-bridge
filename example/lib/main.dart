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
    var events = {
        "key": "basic_event",
        "count": 1
    };
    Countly.sendEvent(events);
  }
  eventWithSum(){
    // example for event with sum
     var events = {
            "key": "event_sum",
            "count": 1,
            "sum": "0.99"
        };
        Countly.sendEvent(events);
  }
  eventWithSegment(){
     // example for event with segment
        var events = {
            "key": "event_segment",
            "count": 1
        };
        events["segment"] = {
            "Country": "Turkey",
            "Age": "28"
        };
        Countly.sendEvent(events);
  }

  eventWithSumSegment(){
    // example for event with segment and sum
        var events = {
            "key": "event_segment_sum",
            "count": 1,
            "sum": "0.99"
        };
        events["segment"] = {
            "Country": "Turkey",
            "Age": "28"
        };
        Countly.sendEvent(events);
  }
  event(){
    // setInterval(function() {
            // app.sendSampleEvent();
        // }, 1000);
  }
  endEventBasic(){
    Countly.startEvent("Timed Event");
        // setTimeout(function() {
            // Countly.endEvent({ "key": "Timed Event" });
        // }, 1000);
  }
endEventWithSum(){
     Countly.startEvent("Timed Event With Sum");
        // setTimeout(function() {
            // Countly.endEvent({ "key": "Timed Event With Sum", "sum": "0.99" });
        // }, 1000);
  }
  endEventWithSegment(){
    Countly.startEvent("Timed Event With Segment");
    //     // setTimeout(function() {

    //         var events = {
    //             "key": "Timed Event With Segment"
    //         };
    //         events["segment"] = {
    //             "Country": "Turkey",
    //             "Age": "28"
    //         };
    //         Countly.endEvent(events);
    //     // }, 1000);
  }
  endEventWithSumSegment(){
    Countly.startEvent("Timed Event With Segment, Sum and Count");
    //     setTimeout(function() {
    //         var events = {
    //             "key": "Timed Event With Segment, Sum and Count",
    //             "count": 1,
    //             "sum": "0.99"
    //         };
    //         events["segment"] = {
    //             "Country": "Turkey",
    //             "Age": "28"
    //         };
    //         Countly.endEvent(events);
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
      // Countly.enableCrashReporting();
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
    //         console.log(ratingResult);
    //     });
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
              MyButton(text: "Basic Events", color: "default", onPressed: basicEvent),
              MyButton(text: "Event with Sum", color: "default", onPressed: eventWithSum),
              MyButton(text: "Event with Segment", color: "default", onPressed: eventWithSegment),
              MyButton(text: "Even with Sum and Segment", color: "", onPressed: eventWithSumSegment),
              MyButton(text: "All Events", color: "black", onPressed: event),
              MyButton(text: "Timed event: Start / Stop", color: "default", onPressed: endEventBasic),
              MyButton(text: "Timed event Sum: Start / Stop", color: "default", onPressed: endEventWithSum),
              MyButton(text: "Timed event Segment: Start / Stop", color: "default", onPressed: endEventWithSegment),
              MyButton(text: "Timed event Sum Segment: Start / Stop", color: "default", onPressed: endEventWithSumSegment),
              MyButton(text: "Record View: 'HomePage'", color: "default", onPressed: recordViewHome),
              MyButton(text: "Record View: 'Dashboard'", color: "default", onPressed: recordViewDashboard),
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
              MyButton(text: "Push Message", color: "teal", onPressed: sendPushToken),
              MyButton(text: "Push Test Android", color: "teal", onPressed: testAndroidPush),
              MyButton(text: "Push Test iOS", color: "teal", onPressed: testiOSPush),
              MyButton(text: "Change Device ID", color: "default", onPressed: changeDeviceId),
              MyButton(text: "Enable Parameter Tapmering Protection", color: "default", onPressed: enableParameterTamperingProtection),
              MyButton(text: "City, State, and Location", color: "default", onPressed: setOptionalParametersForInitialization),
              MyButton(text: "Send Crash Report", color: "default", onPressed: addCrashLog),
              MyButton(text: "Send 5 star rating!!", color: "default", onPressed: sendRating),
              MyButton(text: "Open rating modal", color: "default", onPressed: askForStarRating),

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
  "green": {
    "button": Colors.green,
    "text": Color(0xffffffff)
  }
};
Map<String, Object> getColor(color){
  if(color == "green"){
    return theColor["green"];
  }else if(color == "teal"){
    return theColor["default"];
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