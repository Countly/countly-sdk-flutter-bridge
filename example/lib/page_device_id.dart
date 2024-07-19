import 'dart:math';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:countly_flutter_example/helpers.dart';
import 'package:flutter/material.dart';

class DeviceIDPage extends StatefulWidget {
  @override
  State<DeviceIDPage> createState() => _DeviceIDPageState();
}

class _DeviceIDPageState extends State<DeviceIDPage> {
  /// To Show the device id type in UI, when user tap on 'Get Device Id Type' button
  String _deviceId = '';
  String _deviceIdType = '';

  String makeid() {
    int code = Random().nextInt(999999);
    String random = code.toString();
    print(random);
    return random;
  }

  Future<void> getID() async {
    String? deviceId = await Countly.instance.deviceId.getID();
    if (deviceId != null) {
      setState(() {
        _deviceId = deviceId.toString();
      });
    }
  }

  Future<void> getIDType() async {
    DeviceIdType? deviceIdType = await Countly.instance.deviceId.getIDType();
    if (deviceIdType != null) {
      setState(() {
        _deviceIdType = deviceIdType.toString();
      });
    }
  }

  void changeWithMerge() {
    Countly.instance.deviceId.changeWithMerge('123456');
  }

  void changeWithoutMerge() {
    Countly.instance.deviceId.changeWithoutMerge(makeid());
  }

  void enableTemporaryIDMode() {
    Countly.instance.deviceId.enableTemporaryIDMode();
  }

  void setID() {
    Countly.instance.deviceId.setID(makeid());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Device ID Management'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15),
        child: Center(
          child: Column(
            children: [
              Text(_deviceId, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              SizedBox(height: 10),
              Text(_deviceIdType, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              MyButton(text: 'Get Device Id', color: 'olive', onPressed: getID),
              MyButton(text: 'Get Device Id Type', color: 'green', onPressed: getIDType),
              MyButton(text: 'Enable Temporary ID Mode', color: 'orange', onPressed: enableTemporaryIDMode),
              MyButton(text: 'Change Device ID With Merge', color: 'yellow', onPressed: changeWithMerge),
              MyButton(text: 'Change Device ID Without Merge', color: 'teal', onPressed: changeWithoutMerge),
              MyButton(text: 'Set ID', color: 'brown', onPressed: setID),
            ],
          ),
        ),
      ),
    );
  }
}
