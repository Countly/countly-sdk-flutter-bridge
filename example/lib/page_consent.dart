import 'package:countly_flutter/countly_flutter.dart';
import 'package:countly_flutter_example/helpers.dart';
import 'package:flutter/material.dart';

class ConsentPage extends StatelessWidget {
  void giveMultipleConsent() {
    Countly.giveConsent(['events', 'views', 'star-rating', 'crashes']);
  }

  void removeMultipleConsent() {
    Countly.removeConsent(['events', 'views', 'star-rating', 'crashes']);
  }

  void giveAllConsent() {
    Countly.giveAllConsent();
  }

  void removeAllConsent() {
    Countly.removeAllConsent();
  }

  void giveConsentSessions() {
    Countly.giveConsent(['sessions']);
  }

  void giveConsentEvents() {
    Countly.giveConsent(['events']);
  }

  void giveConsentViews() {
    Countly.giveConsent(['views']);
  }

  void giveConsentLocation() {
    Countly.giveConsent(['location']);
  }

  void giveConsentCrashes() {
    Countly.giveConsent(['crashes']);
  }

  void giveConsentAttribution() {
    Countly.giveConsent(['attribution']);
  }

  void giveConsentUsers() {
    Countly.giveConsent(['users']);
  }

  void giveConsentPush() {
    Countly.giveConsent(['push']);
  }

  void giveConsentStarRating() {
    Countly.giveConsent(['star-rating']);
  }

  void giveConsentAPM() {
    Countly.giveConsent(['apm']);
  }

  void removeConsentsessions() {
    Countly.removeConsent(['sessions']);
  }

  void removeConsentEvents() {
    Countly.removeConsent(['events']);
  }

  void removeConsentViews() {
    Countly.removeConsent(['views']);
  }

  void removeConsentlocation() {
    Countly.removeConsent(['location']);
  }

  void removeConsentcrashes() {
    Countly.removeConsent(['crashes']);
  }

  void removeConsentattribution() {
    Countly.removeConsent(['attribution']);
  }

  void removeConsentusers() {
    Countly.removeConsent(['users']);
  }

  void removeConsentpush() {
    Countly.removeConsent(['push']);
  }

  void removeConsentstarRating() {
    Countly.removeConsent(['star-rating']);
  }

  void removeConsentAPM() {
    Countly.removeConsent(['apm']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sessions'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15),
        child: Center(
            child: Column(
          children: [
            MyButton(text: 'Give multiple consent', color: 'teal', onPressed: giveMultipleConsent),
            MyButton(text: 'Remove multiple consent', color: 'orange', onPressed: removeMultipleConsent),
            MyButton(text: 'Give all Consent', color: 'green', onPressed: giveAllConsent),
            MyButton(text: 'Remove all Consent', color: 'red', onPressed: removeAllConsent),
            MyButton(text: 'Give Consent Sessions', color: 'blue', onPressed: giveConsentSessions),
            MyButton(text: 'Give Consent Events', color: 'blue', onPressed: giveConsentEvents),
            MyButton(text: 'Give Consent Views', color: 'blue', onPressed: giveConsentViews),
            MyButton(text: 'Give Consent Location', color: 'blue', onPressed: giveConsentLocation),
            MyButton(text: 'Give Consent Crashes', color: 'blue', onPressed: giveConsentCrashes),
            MyButton(text: 'Give Consent Attribution', color: 'blue', onPressed: giveConsentAttribution),
            MyButton(text: 'Give Consent Users', color: 'blue', onPressed: giveConsentUsers),
            MyButton(text: 'Give Consent Push', color: 'blue', onPressed: giveConsentPush),
            MyButton(text: 'Give Consent starRating', color: 'blue', onPressed: giveConsentStarRating),
            MyButton(text: 'Give Consent Performance', color: 'blue', onPressed: giveConsentAPM),
            MyButton(text: 'Remove Consent Sessions', color: 'orange', onPressed: removeConsentsessions),
            MyButton(text: 'Remove Consent Events', color: 'orange', onPressed: removeConsentEvents),
            MyButton(text: 'Remove Consent Views', color: 'orange', onPressed: removeConsentViews),
            MyButton(text: 'Remove Consent Location', color: 'orange', onPressed: removeConsentlocation),
            MyButton(text: 'Remove Consent Crashes', color: 'orange', onPressed: removeConsentcrashes),
            MyButton(text: 'Remove Consent Attribution', color: 'orange', onPressed: removeConsentattribution),
            MyButton(text: 'Remove Consent Users', color: 'orange', onPressed: removeConsentusers),
            MyButton(text: 'Remove Consent Push', color: 'orange', onPressed: removeConsentpush),
            MyButton(text: 'Remove Consent starRating', color: 'orange', onPressed: removeConsentstarRating),
            MyButton(text: 'Remove Consent Performance', color: 'orange', onPressed: removeConsentAPM),
          ],
        )),
      ),
    );
  }
}
