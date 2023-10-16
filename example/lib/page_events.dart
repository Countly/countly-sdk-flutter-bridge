import 'dart:async';

import 'package:countly_flutter/countly_flutter.dart';
import 'package:countly_flutter_example/helpers.dart';
import 'package:flutter/material.dart';

class EventsPage extends StatelessWidget {
  void basicEvent() {
    // example for basic event
    var event = {'key': 'Basic Event', 'count': 1};
    Countly.recordEvent(event);
  }

  void eventWithSum() {
    // example for event with sum
    var event = {
      'key': 'Event With Sum',
      'count': 1,
      'sum': '0.99',
    };
    Countly.recordEvent(event);
  }

  void eventWithSegment() {
    // example for event with segment
    var event = {'key': 'Event With Segment', 'count': 1};
    event['segmentation'] = {'Country': 'Turkey', 'Age': '28'};
    Countly.recordEvent(event);
  }

  void eventWithSumSegment() {
    // example for event with segment and sum
    var event = {'key': 'Event With Sum And Segment', 'count': 1, 'sum': '0.99'};
    event['segmentation'] = {'Country': 'Turkey', 'Age': '28'};
    Countly.recordEvent(event);
  }

  void endEventBasic() {
    Countly.startEvent('Timed Event');
    Timer(const Duration(seconds: 5), () {
      Countly.endEvent({'key': 'Timed Event'});
    });
  }

  void endEventWithSum() {
    Countly.startEvent('Timed Event With Sum');
    Timer(const Duration(seconds: 5), () {
      Countly.endEvent({'key': 'Timed Event With Sum', 'sum': '0.99'});
    });
  }

  void endEventWithSegment() {
    Countly.startEvent('Timed Event With Segment');
    Timer(const Duration(seconds: 5), () {
      var event = {
        'key': 'Timed Event With Segment',
        'count': 1,
      };
      event['segmentation'] = {'Country': 'Turkey', 'Age': '28'};
      Countly.endEvent(event);
    });
  }

  void endEventWithSumSegment() {
    Countly.startEvent('Timed Event With Segment, Sum and Count');
    Timer(const Duration(seconds: 5), () {
      var event = {'key': 'Timed Event With Segment, Sum and Count', 'count': 1, 'sum': '0.99'};
      event['segmentation'] = {'Country': 'Turkey', 'Age': '28'};
      Countly.endEvent(event);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Events'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15),
        child: Center(
            child: Column(
          children: [
            MyButton(text: 'Basic event', color: 'brown', onPressed: basicEvent),
            MyButton(text: 'Event with Sum', color: 'brown', onPressed: eventWithSum),
            MyButton(text: 'Event with Segment', color: 'brown', onPressed: eventWithSegment),
            MyButton(text: 'Even with Sum and Segment', color: 'brown', onPressed: eventWithSumSegment),
            MyButton(text: 'Timed event: Start / Stop', color: 'grey', onPressed: endEventBasic),
            MyButton(text: 'Timed event Sum: Start / Stop', color: 'grey', onPressed: endEventWithSum),
            MyButton(text: 'Timed event Segment: Start / Stop', color: 'grey', onPressed: endEventWithSegment),
            MyButton(text: 'Timed event Sum Segment: Start / Stop', color: 'grey', onPressed: endEventWithSumSegment),
          ],
        )),
      ),
    );
  }
}
