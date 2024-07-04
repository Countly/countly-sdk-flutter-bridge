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
  String _deviceIdType = '';

  String makeid() {
    int code = Random().nextInt(999999);
    String random = code.toString();
    print(random);
    return random;
  }

  Future<void> getDeviceIDType() async {
    DeviceIdType? deviceIdType = await Countly.instance.deviceId.getDeviceIDType();
    if (deviceIdType != null) {
      setState(() {
        _deviceIdType = deviceIdType.toString();
      });
    }
  }

  void changeDeviceIdWithMerge() {
    Countly.instance.deviceId.changeDeviceIDWithMerge('123456');
  }

  void changeDeviceIdWithoutMerge() {
    Countly.instance.deviceId.changeDeviceIDWithoutMerge(makeid());
  }

  void enableTemporaryIdMode() {
    Countly.instance.deviceId.changeDeviceIDWithoutMerge(Countly.deviceIDType['TemporaryDeviceID']!);
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
              Text(_deviceIdType, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              MyButton(text: 'Get Device Id Type', color: 'green', onPressed: getDeviceIDType),
              MyButton(text: 'Enable Temporary ID Mode', color: 'orange', onPressed: enableTemporaryIdMode),
              MyButton(text: 'Change Device ID With Merge', color: 'yellow', onPressed: changeDeviceIdWithMerge),
              MyButton(text: 'Change Device ID Without Merge', color: 'teal', onPressed: changeDeviceIdWithoutMerge),
              MyButton(text: 'Set ID', color: 'brown', onPressed: setID),
            ],
          ),
        ),
      ),
    );
  }
}
