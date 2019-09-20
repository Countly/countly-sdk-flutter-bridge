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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Countly SDK Dart Demo'),
        ),
        body: Center(
          child: Column(children: <Widget>[
            MyButton(text: "init", color: Colors.white, onPressed: onInit),
            MyButton(text: "start", color: Colors.white, onPressed: onInit),
          ],),
        ),
      ),
    );
  }
}

class MyButton extends StatelessWidget{
  String _text;
  Color _color;
  Function _onPressed;
  MyButton({Color color, String text, Function onPressed}){
    _text = text;
    _color = color;
    _onPressed = onPressed;
  }

  @override
  Widget build(BuildContext context){
    return new OutlineButton(
      onPressed: _onPressed,
      color: _color,
      child: SizedBox(
        width: double.maxFinite,
        child: Text(_text, style: new TextStyle(color: Colors.black),textAlign: TextAlign.center)
        )
    );
  }
}