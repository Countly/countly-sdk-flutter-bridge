import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:countly/countly.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await Countly.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
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
            "eventName": "basic_event",
            "eventCount": 1
        };
        Countly.sendEvent(events);
  }
  eventWithSum(){
    // example for event with sum
     var events = {
            "eventName": "event_sum",
            "eventCount": 1,
            "eventSum": "0.99"
        };
        Countly.sendEvent(events);
  }
  eventWithSegment(){
     // example for event with segment
        var events = {
            "eventName": "event_segment",
            "eventCount": 1
        };
        events.segments = {
            "Country": "Turkey",
            "Age": "28"
        };
        Countly.sendEvent(events);
  }
  eventWithSum_Segment(){
    // example for event with segment and sum
        var events = {
            "eventName": "event_segment_sum",
            "eventCount": 1,
            "eventSum": "0.99"
        };
        events.segments = {
            "Country": "Turkey",
            "Age": "28"
        };
        Countly.sendEvent(events);
  }
  event(){
    setInterval(function() {
            app.sendSampleEvent();
        }, 1000);
  }
  endEventBasic(){
    Countly.startEvent("Timed Event");
        setTimeout(function() {
            Countly.endEvent({ "eventName": "Timed Event" });
        }, 1000);
  }
endEventWithSum(){
     Countly.startEvent("Timed Event With Sum");
        setTimeout(function() {
            Countly.endEvent({ "eventName": "Timed Event With Sum", "eventSum": "0.99" });
        }, 1000);
  }
  endEventWithSegment(){
    Countly.startEvent("Timed Event With Segment");
        setTimeout(function() {

            var events = {
                "eventName": "Timed Event With Segment"
            };
            events.segments = {
                "Country": "Turkey",
                "Age": "28"
            };
            Countly.endEvent(events);
        }, 1000);
  }
  endEventWithSumSegment(){
    Countly.startEvent("Timed Event With Segment, Sum and Count");
        setTimeout(function() {
            var events = {
                "eventName": "Timed Event With Segment, Sum and Count",
                "eventCount": 1,
                "eventSum": "0.99"
            };
            events.segments = {
                "Country": "Turkey",
                "Age": "28"
            };
            Countly.endEvent(events);
        }, 1000);
  }
  recordViewHome(){
    Countly.recordView(viewName);
  }
  recordViewDashboard(){
    Countly.recordView(viewName);
  }
  setCaptianAmericaData(){
     // example for setCaptianAmericaData
        var deviceId = makeid();
        Countly.changeDeviceId(deviceId, false);
        
        var options = {};
        options.name = "Captian America";
        options.username = "captianamerica";
        options.email = "captianamerica@avengers.com";
        options.organization = "Avengers";
        options.phone = "+91 555 555 5555";
        options.picture = "http://icons.iconarchive.com/icons/hopstarter/superhero-avatar/256/Avengers-Captain-America-icon.png";
        options.picturePath = "";
        options.gender = "M"; // "F"
        options.byear = 1989;
        Countly.setUserData(options);
  }
  setIronManData(){
      // example for setIronManData 
        var deviceId = makeid();
        Countly.changeDeviceId(deviceId, false);
        
        var options = {};
        options.name = "Iron Man";
        options.username = "ironman";
        options.email = "ironman@avengers.com";
        options.organization = "Avengers";
        options.phone = "+91 555 555 5555";
        options.picture = "http://icons.iconarchive.com/icons/hopstarter/superhero-avatar/256/Avengers-Iron-Man-icon.png";
        options.picturePath = "";
        options.gender = "M"; // "F"
        options.byear = 1989;
        Countly.setUserData(options);
        Countly.start();
  }
  setSpiderManData(){
       var deviceId = makeid();
        Countly.changeDeviceId(deviceId, false);
        
        var options = {};
        options.name = "Spider-Man";
        options.username = "spiderman";
        options.email = "spiderman@avengers.com";
        options.organization = "Avengers";
        options.phone = "+91 555 555 5555";
        options.picture = "http://icons.iconarchive.com/icons/mattahan/ultrabuuf/512/Comics-Spiderman-Morales-icon.png";
        options.picturePath = "";
        options.gender = "M"; // "F"
        options.byear = 1989;
        Countly.setUserData(options);
        Countly.start();
  }
  setUserData(){
      // example for setUserData
        var options = {};
        options.name = "Trinisoft Technologies";
        options.username = "trinisofttechnologies";
        options.email = "trinisofttechnologies@gmail.com";
        options.organization = "Trinisoft Technologies Pvt. Ltd.";
        options.phone = "+91 812 840 2946";
        options.picture = "https://avatars0.githubusercontent.com/u/10754117?s=400&u=fe019f92d573ac76cbfe7969dde5e20d7206975a&v=4";
        options.picturePath = "";
        options.gender = "M"; // "F"
        options.byear = 1989;
        Countly.setUserData(options);
  }
  setProperty(){
      Countly.userData.setProperty("setProperty", "My Property");
  }
  increment(){
      Countly.userData.increment("increment");
  }
  incrementBy(){
      Countly.userData.incrementBy("incrementBy", 10);
  }
  multiply(){
       Countly.userData.multiply("multiply", 20);
  }
   saveMax(){
       Countly.userData.saveMax("saveMax", 100);
  }
  saveMin(){
       Countly.userData.saveMin("saveMin", 50);
  }
  setOnce(){
       Countly.userData.setOnce("setOnce", 200);
  }
  sendPushToken(){
       var push = PushNotification.init({
            android: {sound: true},
            ios: {
                alert: "true",
                badge: "true",
                sound: "true"
            },
            windows: {}
        });

        push.on('registration', function(data) {
            alert('Token received: '+data.registrationId);
            Countly.sendPushToken({
                "token": data.registrationId,
                "messagingMode": Countly.messagingMode.DEVELOPMENT
            });
        });

        push.on('notification', function(data) {
            alert(JSON.stringify(data));
            // data.message,
            // data.title,
            // data.count,
            // data.sound,
            // data.image,
            // data.additionalData
        });

        // // Test android 8.0 and 9.0
        // push.subscribe('myTopic', function(n){
        //     alert(JSON.stringify(n));
        // }, function(e){
        //     alert(JSON.stringify(e));
        // });

        push.on('error', function(e) {
            // e.message
        });
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
            "messagingMode": Countly.messagingMode.DEVELOPMENT
        });
  }
  testiOSPush(){
    Countly.sendPushToken({
            "token": "1234567890",
            "messagingMode": Countly.messagingMode.DEVELOPMENT
        });
  }
  changeDeviceId(){
    Countly.changeDeviceId("123456", true);
  }
  enableParameterTamperingProtection(){
    Countly.enableParameterTamperingProtection("salt");
  }
   setOptionalParametersForInitialization(){
      Countly.setOptionalParametersForInitialization({
            city: "Tampa",
            country: "US",
            latitude: "28.006324",
            longitude: "-82.7166183"
        });
  }
  addCrashLog(){
      Countly.enableCrashReporting();
        Countly.addCrashLog("User Performed Step A");
        setTimeout(function() {
            Countly.addCrashLog("User Performed Step B");
        }, 1000);
        setTimeout(function() {
            Countly.addCrashLog("User Performed Step C");
            // console.log("Opps found and error");
            a();
        }, 1000);
  }
  sendRating(){
    Countly.sendRating(5);
  }
  askForStarRating(){
    Countly.askForStarRating(function(ratingResult){
            console.log(ratingResult);
        });
  }
  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Countly SDK Dart Demo'),
        ),
        body: Center(
          child: Column(children: <Widget>[
            MyButton(text: "Init", color: "green", onPressed: onInit),
            MyButton(text: "Init with ID", color: "green", onPressed: initWithID),
            MyButton(text: "Start", color: "green", onPressed: start),
            MyButton(text: "Stop", color: "green", onPressed: stop),
            MyButton(text: "Basic Events", color: "default", onPressed: basicEvent),
            MyButton(text: "Event with Sum", color: "default", onPressed: eventWithSum),
            MyButton(text: "Event with Segment", color: "default", onPressed: eventWithSegment),  
            MyButton(text: "Even with Sum and Segment", color: "", onPressed: eventWithSum_Segment),
            MyButton(text: "All Events", color: "black", onPressed: event),
            MyButton(text: "Timed event: Start / Stop", color: "default", onPressed: endEventBasic),
            MyButton(text: "Timed event Sum: Start / Stop", color: "default", onPressed: endEventWithSum),
            MyButton(text: "Timed event Segment: Start / Stop", color: "default", onPressed: endEventWithSegment),
            MyButton(text: "Timed event Sum Segment: Start / Stop", color: "default", onPressed: endEventWithSumSegment),
            MyButton(text: "Record View: 'HomePage'", color: "default", onPressed: recordViewHome),
            MyButton(text: "Record View: 'Dashboard'", color: "default", onPressed: recordViewDashboard),
            MyButton(text: "Send Captian America Data", color: "default", onPressed: setCaptianAmericaData),
            MyButton(text: "Send Iron Man Data", color: "default", onPressed: setIronManData),
            MyButton(text: "Send Spider-Man Data", color: "default", onPressed: setSpiderManData),
            MyButton(text: "Send Users Data", color: "default", onPressed: setUserData),
            MyButton(text: "UserData.setProperty", color: "default", onPressed: setProperty),
            MyButton(text: "UserData.increment", color: "default", onPressed: increment),
            MyButton(text: "UserData.incrementBy", color: "default", onPressed: incrementBy),
            MyButton(text: "UserData.multiply", color: "default", onPressed: multiply),
            MyButton(text: "UserData.saveMax", color: "default", onPressed: saveMax),
            MyButton(text: "UserData.saveMin", color: "default", onPressed: saveMin),
            MyButton(text: "UserData.setOnce", color: "default", onPressed: setOnce),
            MyButton(text: "Push Message", color: "default", onPressed: sendPushToken),
            MyButton(text: "Push Test Android", color: "default", onPressed: testAndroidPush),
            MyButton(text: "Push Test iOS", color: "default", onPressed: testiOSPush),
            MyButton(text: "Change Device ID", color: "default", onPressed: changeDeviceId),
            MyButton(text: "Enable Parameter Tapmering Protection", color: "default", onPressed: enableParameterTamperingProtection),
            MyButton(text: "City, State, and Location", color: "default", onPressed: setOptionalParametersForInitialization),
            MyButton(text: "Send Crash Report", color: "default", onPressed: addCrashLog),
            MyButton(text: "Send 5 star rating!!", color: "default", onPressed: sendRating),
            MyButton(text: "Open rating modal", color: "default", onPressed: askForStarRating),
            
          ],),
        ),
      ),
    );
  }
}

class MyButton extends StatelessWidget{
  String _text;
  String _color;
  Function _onPressed;
  MyButton({String color, String text, Function onPressed}){
    _text = text;
    _color = color;
    _onPressed = onPressed;
  }

  @override
  Widget build(BuildContext context){
    return new OutlineButton(
      onPressed: _onPressed,
      color: Colors.white,
      child: SizedBox(
        width: double.maxFinite,
        child: Text(_text, style: new TextStyle(color: Colors.black),textAlign: TextAlign.center)
        )
    );
  }
}