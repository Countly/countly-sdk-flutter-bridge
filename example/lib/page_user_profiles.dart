import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:countly_flutter_example/helpers.dart';
import 'package:flutter/material.dart';

class UserProfilesPage extends StatelessWidget {
  void setUserData() {
    Map<String, Object> options = {
      'name': 'Name of User',
      'username': 'Username',
      'email': 'User Email',
      'organization': 'User Organization',
      'phone': 'User Contact number',
      'picture': 'https://count.ly/images/logos/countly-logo.png',
      'picturePath': '',
      'gender': 'User Gender',
      'byear': '1989',
    };
    Countly.instance.userProfile.setUserProperties(options);
  }

  void setProperties() {
    Map<String, Object> userProperties = {
      'name': 'Name of User',
      'username': 'Username',
      'email': 'User Email',
      'organization': 'User Organization',
      'phone': 123456789,
      'picture': 'https://count.ly/images/logos/countly-logo.png',
      'picturePath': '',
      'gender': 'User Gender',
      'byear': '1989',
      'Custom Integer': 123,
      'Custom String': 'Some String',
      'Custom Array': ['array value 1', 'array value 2'],
      'Custom Map': {'key 1': 'value 1', 'key 2': 'value 2'},
    };

    Countly.instance.userProfile.setUserProperties(userProperties);
  }

  void setProperty() {
    Countly.instance.userProfile.setProperty('setProperty', 'My Property');
  }

  void increment() {
    Countly.instance.userProfile.increment('increment');
  }

  void incrementBy() {
    Countly.instance.userProfile.incrementBy('incrementBy', 10);
  }

  void multiply() {
    Countly.instance.userProfile.multiply('multiply', 20);
  }

  void saveMax() {
    Countly.instance.userProfile.saveMax('saveMax', 100);
  }

  void saveMin() {
    Countly.instance.userProfile.saveMin('saveMin', 50);
  }

  void setOnce() {
    Countly.instance.userProfile.setOnce('setOnce', '200');
  }

  void pushUniqueValue() {
    Countly.instance.userProfile.pushUnique('pushUniqueValue', 'morning');
  }

  void pushValue() {
    Countly.instance.userProfile.push('pushValue', 'morning');
  }

  void pullValue() {
    Countly.instance.userProfile.pull('pushValue', 'morning');
  }

  void save() {
    Countly.instance.userProfile.save();
  }

  void clear() {
    Countly.instance.userProfile.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profiles'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15),
        child: Center(
            child: Column(
          children: [
            MyButton(text: 'Send Users Data', color: 'green', onPressed: setUserData),
            MyButton(text: 'setProperties', color: 'teal', onPressed: setProperties),
            MyButton(text: 'setProperty', color: 'teal', onPressed: setProperty),
            MyButton(text: 'increment', color: 'teal', onPressed: increment),
            MyButton(text: 'incrementBy', color: 'teal', onPressed: incrementBy),
            MyButton(text: 'multiply', color: 'teal', onPressed: multiply),
            MyButton(text: 'saveMax', color: 'teal', onPressed: saveMax),
            MyButton(text: 'saveMin', color: 'teal', onPressed: saveMin),
            MyButton(text: 'setOnce', color: 'teal', onPressed: setOnce),
            MyButton(text: 'pushUniqueValue', color: 'teal', onPressed: pushUniqueValue),
            MyButton(text: 'pushValue', color: 'teal', onPressed: pushValue),
            MyButton(text: 'pullValue', color: 'teal', onPressed: pullValue),
            MyButton(text: 'save', color: 'green', onPressed: save),
            MyButton(text: 'clear', color: 'orange', onPressed: clear),
          ],
        )),
      ),
    );
  }
}
