import 'dart:async';
import 'dart:math';

import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:countly_flutter_example/helpers.dart';
import 'package:flutter/material.dart';

class FeedbackWidgetsPage extends StatefulWidget {
  @override
  State<FeedbackWidgetsPage> createState() => _FeedbackWidgetsPageState();
}

class _FeedbackWidgetsPageState extends State<FeedbackWidgetsPage> {
  final ratingIdController = TextEditingController();
  final Random rnd = Random();

  @override
  void initState() {
    super.initState();
    ratingIdController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    ratingIdController.dispose();
    super.dispose();
  }

  // for Countly Lite users only
  void askForStarRating() {
    Countly.askForStarRating();
  }

  void presentRatingWidget() {
    // Trying to show a rating widget with a previously know ID.
    // You should replace the given ID with your own, it would be retrieved from your Countly Dashboard.
    Countly.presentRatingWidgetWithID('61eaaf37c935575c7b932b97', closeButtonText: 'close', ratingWidgetCallback: (error) {
      if (error != null) {
        print(error);
      }
    });
  }

  void presentRatingWidgetUsingEditBox() {
    // Trying to show a rating widget with the ID give in the App.
    // In the EditBox you would write the ID that you retrieved from your Countly Dashboard.
    Countly.presentRatingWidgetWithID(ratingIdController.text, closeButtonText: 'close', ratingWidgetCallback: (error) {
      if (error != null) {
        print(error);
      }
    });
  }

  Future<void> showFeedbackWidget() async {
    FeedbackWidgetsResponse feedbackWidgetsResponse = await Countly.getAvailableFeedbackWidgets();
    List<CountlyPresentableFeedback> widgets = feedbackWidgetsResponse.presentableFeedback;
    String? error = feedbackWidgetsResponse.error;

    if (error != null) {
      return;
    }

    if (widgets.isNotEmpty) {
      await Countly.presentFeedbackWidget(widgets.first, 'Close', widgetShown: () {
        print('showFeedbackWidget widget shown');
      }, widgetClosed: () {
        print('showFeedbackWidget widget closed');
      });
    }
  }

  Future<void> showSurvey() async {
    FeedbackWidgetsResponse feedbackWidgetsResponse = await Countly.getAvailableFeedbackWidgets();
    List<CountlyPresentableFeedback> widgets = feedbackWidgetsResponse.presentableFeedback;
    String? error = feedbackWidgetsResponse.error;

    if (error != null) {
      return;
    }

    for (CountlyPresentableFeedback widget in widgets) {
      if (widget.type == 'survey') {
        await Countly.presentFeedbackWidget(widget, 'Cancel');
        break;
      }
    }
  }

  Future<void> showNPS() async {
    FeedbackWidgetsResponse feedbackWidgetsResponse = await Countly.getAvailableFeedbackWidgets();
    List<CountlyPresentableFeedback> widgets = feedbackWidgetsResponse.presentableFeedback;
    String? error = feedbackWidgetsResponse.error;

    if (error != null) {
      return;
    }

    for (CountlyPresentableFeedback widget in widgets) {
      if (widget.type == 'nps') {
        await Countly.presentFeedbackWidget(widget, 'Close', widgetShown: () {
          print('NPS widget shown');
        }, widgetClosed: () {
          print('NPS widget closed');
        });
        break;
      }
    }
  }

  Future<void> showRating() async {
    FeedbackWidgetsResponse feedbackWidgetsResponse = await Countly.getAvailableFeedbackWidgets();
    List<CountlyPresentableFeedback> widgets = feedbackWidgetsResponse.presentableFeedback;
    String? error = feedbackWidgetsResponse.error;

    if (error != null) {
      print(error);
      return;
    }

    for (CountlyPresentableFeedback widget in widgets) {
      if (widget.type == 'rating') {
        await Countly.presentFeedbackWidget(widget, 'Close', widgetShown: () {
          print('Rating widget shown');
        }, widgetClosed: () {
          print('Rating widget closed');
        });
        break;
      }
    }
  }

  Future<void> reportSurveyManually() async {
    FeedbackWidgetsResponse feedbackWidgetsResponse = await Countly.getAvailableFeedbackWidgets();
    List<CountlyPresentableFeedback> widgets = feedbackWidgetsResponse.presentableFeedback;
    String? error = feedbackWidgetsResponse.error;

    if (error != null) {
      return;
    }
    CountlyPresentableFeedback? chosenWidget;
    for (CountlyPresentableFeedback widget in widgets) {
      if (widget.type == 'survey') {
        chosenWidget = widget;
        break;
      }
    }
    if (chosenWidget != null) {
      unawaited(reportSurvey(chosenWidget));
    }
  }

  Future<void> reportSurvey(CountlyPresentableFeedback chosenWidget) async {
    List result = await Countly.getFeedbackWidgetData(chosenWidget);
    String? error = result[1];
    if (error == null) {
      Map<String, dynamic>? retrievedWidgetData = result[0];
      Map<String, Object> segments = {};
      if (retrievedWidgetData != null && retrievedWidgetData.isNotEmpty) {
        List<dynamic>? questions = retrievedWidgetData['questions'];

        if (questions != null) {
          //iterate over all questions and set random answers
          for (int a = 0; a < questions.length; a++) {
            Map<dynamic, dynamic> question = questions[a];
            String wType = question['type'];
            String questionId = question['id'];
            String answerKey = 'answ-$questionId';
            switch (wType) {
              //multiple answer question
              case 'multi':
                List<dynamic> choices = question['choices'];
                String str = '';
                for (int b = 0; b < choices.length; b++) {
                  if (b % 2 == 0) {
                    if (b != 0) {
                      str += ',';
                    }
                    str += (choices[b] as Map)['key'];
                  }
                }
                segments[answerKey] = str;
                break;
              case 'radio':
              //dropdown value selector
              case 'dropdown':
                List<dynamic> choices = question['choices'];
                int pick = rnd.nextInt(choices.length);
                segments[answerKey] = (choices[pick] as Map)['key']; //pick the key of random choice
                break;
              //text input field
              case 'text':
                segments[answerKey] = 'Some random text${rnd.nextInt(999999)}';
                break;
              //rating picker
              case 'rating':
                segments[answerKey] = rnd.nextInt(11);
                break;
            }
          }
        }
      }
      await Countly.reportFeedbackWidgetManually(chosenWidget, retrievedWidgetData ?? {}, segments);
    }
  }

  Future<void> reportNPSManually() async {
    FeedbackWidgetsResponse feedbackWidgetsResponse = await Countly.getAvailableFeedbackWidgets();
    List<CountlyPresentableFeedback> widgets = feedbackWidgetsResponse.presentableFeedback;
    String? error = feedbackWidgetsResponse.error;

    if (error != null) {
      return;
    }

    CountlyPresentableFeedback? chosenWidget;
    for (CountlyPresentableFeedback widget in widgets) {
      if (widget.type == 'nps') {
        chosenWidget = widget;
        break;
      }
    }
    if (chosenWidget != null) {
      reportNPS(chosenWidget);
    }
  }

  void reportNPS(CountlyPresentableFeedback chosenWidget) {
    Countly.getFeedbackWidgetData(chosenWidget, onFinished: (retrievedWidgetData, error) {
      if (error == null) {
        print(retrievedWidgetData);
        Map<String, Object> segments = {'rating': rnd.nextInt(10), 'comment': 'Filled out comment${rnd.nextInt(999999)}'};
        Countly.reportFeedbackWidgetManually(chosenWidget, retrievedWidgetData, segments);
      }
    });
  }

  Future<void> reportRatingManually() async {
    FeedbackWidgetsResponse feedbackWidgetsResponse = await Countly.getAvailableFeedbackWidgets();
    List<CountlyPresentableFeedback> widgets = feedbackWidgetsResponse.presentableFeedback;
    String? error = feedbackWidgetsResponse.error;

    if (error != null) {
      return;
    }

    CountlyPresentableFeedback? chosenWidget;
    for (CountlyPresentableFeedback widget in widgets) {
      if (widget.type == 'rating') {
        chosenWidget = widget;
        break;
      }
    }
    if (chosenWidget != null) {
      reportRating(chosenWidget);
    }
  }

  void reportRating(CountlyPresentableFeedback chosenWidget) {
    Countly.getFeedbackWidgetData(chosenWidget, onFinished: (retrievedWidgetData, error) {
      if (error == null) {
        print(retrievedWidgetData);
        Map<String, Object> segments = {'rating': rnd.nextInt(6), 'comment': 'Filled out comment${rnd.nextInt(999999)}', 'email': 'test${rnd.nextInt(999999)}@yahoo.com'};
        Countly.reportFeedbackWidgetManually(chosenWidget, retrievedWidgetData, segments);
      }
    });
  }

  void demoNPS(nameTagOrID, callback) {
    if (ratingIdController.text.isNotEmpty) {
      nameTagOrID = ratingIdController.text;
    }
    Countly.instance.feedback.presentNPS(nameTagOrID, callback);
  }

  void demoSurvey(nameTagOrID, callback) {
    if (ratingIdController.text.isNotEmpty) {
      nameTagOrID = ratingIdController.text;
    }
    Countly.instance.feedback.presentSurvey(nameTagOrID, callback);
  }

  void demoRating(nameTagOrID, callback) {
    if (ratingIdController.text.isNotEmpty) {
      nameTagOrID = ratingIdController.text;
    }
    Countly.instance.feedback.presentRating(nameTagOrID, callback);
  }

  @override
  Widget build(BuildContext context) {
    FeedbackCallback widgetCB = FeedbackCallback(onClosed: () {
      showCountlyToast(context, 'Widget Closed', Colors.green);
    }, onFinished: (error) {
      if (error != null) {
        showCountlyToast(context, 'Error: $error', Colors.red);
      } else {
        showCountlyToast(context, 'Widget Finished', Colors.green);
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: Text('FeedbackWidgets'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15),
        child: Center(
            child: Column(
          children: [
            MyButton(text: 'Present NPS', color: 'green', onPressed: () => demoNPS(null, null)),
            MyButton(text: 'Present Survey', color: 'green', onPressed: () => demoSurvey(null, null)),
            MyButton(text: 'Present Rating', color: 'green', onPressed: () => demoRating(null, null)),
            MyButton(text: 'Present NPS wCallback', color: 'green', onPressed: () => demoNPS(null, widgetCB)),
            MyButton(text: 'Present Survey wCallback', color: 'green', onPressed: () => demoSurvey(null, widgetCB)),
            MyButton(text: 'Present Rating wCallback', color: 'green', onPressed: () => demoRating(null, widgetCB)),
            MyButton(text: 'Open rating modal', color: 'orange', onPressed: askForStarRating),
            MyButton(text: 'Open feedback modal', color: 'orange', onPressed: presentRatingWidget),
            TextField(
              controller: ratingIdController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Rating ID, Tag or Name',
              ),
            ),
            MyButton(text: 'Show Rating using EditBox', color: 'orange', onPressed: ratingIdController.text.isNotEmpty ? presentRatingWidgetUsingEditBox : null),
            MyButton(text: 'Show Survey', color: 'orange', onPressed: showSurvey),
            MyButton(text: 'Show NPS', color: 'orange', onPressed: showNPS),
            MyButton(text: 'Show Rating', color: 'orange', onPressed: showRating),
            MyButton(text: 'Show Feedback Widget', color: 'orange', onPressed: showFeedbackWidget),
            MyButton(text: 'Report Survey Manually', color: 'orange', onPressed: reportSurveyManually),
            MyButton(text: 'Report NPS Manually', color: 'orange', onPressed: reportNPSManually),
            MyButton(text: 'Report Rating Manually', color: 'orange', onPressed: reportRatingManually),
          ],
        )),
      ),
    );
  }
}
