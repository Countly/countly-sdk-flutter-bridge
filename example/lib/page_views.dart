import 'package:countly_flutter/countly_flutter.dart';
import 'package:countly_flutter_example/helpers.dart';
import 'package:flutter/material.dart';

class ViewsPage extends StatelessWidget {
  final List<String> viewNames = ['viewName', 'viewName1'];
  final List<String> viewIDs = [];

  void recordViewHome() {
    Map<String, Object> segments = {'Cats': 123, 'Moons': 9.98, 'Moose': 'Deer'};
    // ignore: deprecated_member_use
    Countly.recordView('HomePage', segments);
  }

  void recordViewDashboard() {
    // ignore: deprecated_member_use
    Countly.recordView('Dashboard');
  }

  void stopViewWithID() {
    Countly.instance.views.stopViewWithID(viewIDs[0]);
  }

  void stopViewWithName() {
    Countly.instance.views.stopViewWithName(viewNames[0]);
  }

  void pauseViewWithID() {
    Countly.instance.views.pauseViewWithID(viewIDs[0]);
  }

  void resumeViewWithID() {
    Countly.instance.views.resumeViewWithID(viewIDs[0]);
  }

  Future<void> startViewWithSegmentation() async {
    viewIDs[0] = await Countly.instance.views.startView(viewNames[0], {'abcd': '123'}) ?? '';
    print(viewIDs[0]);
  }

  Future<void> startView() async {
    viewIDs[1] = await Countly.instance.views.startView(viewNames[1]) ?? '';
    print(viewIDs[1]);
  }

  void setGlobalViewSegmentation() {
    Countly.instance.views.setGlobalViewSegmentation({'abcd': '123'});
  }

  void updateGlobalViewSegmentation() {
    Countly.instance.views.updateGlobalViewSegmentation({'abcd': '123'});
  }

  Future<void> addSegmentationToViewWithID() async {
    await Countly.instance.views.addSegmentationToViewWithID(viewIDs[1], {'addSegmentationToViewWithID': 'page'});
  }

  Future<void> addSegmentationToViewWithName() async {
    await Countly.instance.views.addSegmentationToViewWithName(viewIDs[1], {'addSegmentationToViewWithName': 'page'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Views'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15),
        child: Center(
            child: Column(
          children: [
            MyButton(text: "Record View: 'HomePage'", color: 'olive', onPressed: recordViewHome),
            MyButton(text: "Record View: 'Dashboard'", color: 'olive', onPressed: recordViewDashboard),
            MyButton(text: 'Start View', color: 'yellow', onPressed: startView),
            MyButton(text: 'Start View With Segmentation', color: 'yellow', onPressed: startViewWithSegmentation),
            MyButton(text: 'Stop View with ID', color: 'orange', onPressed: stopViewWithID),
            MyButton(text: 'Stop View with Name', color: 'orange', onPressed: stopViewWithName),
            MyButton(text: 'Pause View with ID', color: 'yellow', onPressed: pauseViewWithID),
            MyButton(text: 'Resume View with ID', color: 'yellow', onPressed: resumeViewWithID),
            MyButton(text: 'Set Global View Segmentation', color: 'grey', onPressed: setGlobalViewSegmentation),
            MyButton(text: 'Update Global View Segmentation', color: 'grey', onPressed: updateGlobalViewSegmentation),
            MyButton(text: 'Add Segmentation to View with ID', color: 'grey', onPressed: addSegmentationToViewWithID),
            MyButton(text: 'Add Segmentation to View with Name', color: 'grey', onPressed: addSegmentationToViewWithName),
          ],
        )),
      ),
    );
  }
}
