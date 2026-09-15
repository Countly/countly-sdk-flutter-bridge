import 'package:countly_flutter_np/countly_flutter.dart';
import 'package:countly_flutter_example/helpers.dart';
import 'package:flutter/material.dart';

class ConsentPage extends StatelessWidget {
  void giveMultipleConsent() {
    Countly.giveConsent([CountlyConsent.events, CountlyConsent.views, CountlyConsent.starRating, CountlyConsent.crashes]);
  }

  void removeMultipleConsent() {
    Countly.removeConsent([CountlyConsent.events, CountlyConsent.views, CountlyConsent.starRating, CountlyConsent.crashes]);
  }

  void giveAllConsent() {
    Countly.giveAllConsent();
  }

  void removeAllConsent() {
    Countly.removeAllConsent();
  }

  void giveConsentSessions() {
    Countly.giveConsent([CountlyConsent.sessions]);
  }

  void giveConsentEvents() {
    Countly.giveConsent([CountlyConsent.events]);
  }

  void giveConsentViews() {
    Countly.giveConsent([CountlyConsent.views]);
  }

  void giveConsentLocation() {
    Countly.giveConsent([CountlyConsent.location]);
  }

  void giveConsentCrashes() {
    Countly.giveConsent([CountlyConsent.crashes]);
  }

  void giveConsentAttribution() {
    Countly.giveConsent([CountlyConsent.attribution]);
  }

  void giveConsentUsers() {
    Countly.giveConsent([CountlyConsent.users]);
  }

  void giveConsentPush() {
    Countly.giveConsent([CountlyConsent.push]);
  }

  void giveConsentStarRating() {
    Countly.giveConsent([CountlyConsent.starRating]);
  }

  void giveConsentAPM() {
    Countly.giveConsent([CountlyConsent.apm]);
  }

  void removeConsentsessions() {
    Countly.removeConsent([CountlyConsent.sessions]);
  }

  void removeConsentEvents() {
    Countly.removeConsent([CountlyConsent.events]);
  }

  void removeConsentViews() {
    Countly.removeConsent([CountlyConsent.views]);
  }

  void removeConsentlocation() {
    Countly.removeConsent([CountlyConsent.location]);
  }

  void removeConsentcrashes() {
    Countly.removeConsent([CountlyConsent.crashes]);
  }

  void removeConsentattribution() {
    Countly.removeConsent([CountlyConsent.attribution]);
  }

  void removeConsentusers() {
    Countly.removeConsent([CountlyConsent.users]);
  }

  void removeConsentpush() {
    Countly.removeConsent([CountlyConsent.push]);
  }

  void removeConsentstarRating() {
    Countly.removeConsent([CountlyConsent.starRating]);
  }

  void removeConsentAPM() {
    Countly.removeConsent([CountlyConsent.apm]);
  }

  @override
  Widget build(BuildContext context) {
    return CountlyPageScaffold(
      title: 'Consent',
      sections: [
        CountlySection(
          title: 'Bulk Actions',
          children: [
            MyButton(text: 'Give Multiple Consent', type: CountlyButtonType.filled, onPressed: giveMultipleConsent),
            MyButton(text: 'Remove Multiple Consent', type: CountlyButtonType.outlined, onPressed: removeMultipleConsent),
            MyButton(text: 'Give All Consent', type: CountlyButtonType.filled, onPressed: giveAllConsent),
            MyButton(text: 'Remove All Consent', type: CountlyButtonType.outlined, onPressed: removeAllConsent),
          ],
        ),
        CountlySection(
          title: 'Give Individual Consent',
          children: [
            MyButton(text: 'Sessions', type: CountlyButtonType.tonal, onPressed: giveConsentSessions),
            MyButton(text: 'Events', type: CountlyButtonType.tonal, onPressed: giveConsentEvents),
            MyButton(text: 'Views', type: CountlyButtonType.tonal, onPressed: giveConsentViews),
            MyButton(text: 'Location', type: CountlyButtonType.tonal, onPressed: giveConsentLocation),
            MyButton(text: 'Crashes', type: CountlyButtonType.tonal, onPressed: giveConsentCrashes),
            MyButton(text: 'Attribution', type: CountlyButtonType.tonal, onPressed: giveConsentAttribution),
            MyButton(text: 'Users', type: CountlyButtonType.tonal, onPressed: giveConsentUsers),
            MyButton(text: 'Push', type: CountlyButtonType.tonal, onPressed: giveConsentPush),
            MyButton(text: 'Star Rating', type: CountlyButtonType.tonal, onPressed: giveConsentStarRating),
            MyButton(text: 'Performance', type: CountlyButtonType.tonal, onPressed: giveConsentAPM),
          ],
        ),
        CountlySection(
          title: 'Remove Individual Consent',
          children: [
            MyButton(text: 'Sessions', type: CountlyButtonType.outlined, onPressed: removeConsentsessions),
            MyButton(text: 'Events', type: CountlyButtonType.outlined, onPressed: removeConsentEvents),
            MyButton(text: 'Views', type: CountlyButtonType.outlined, onPressed: removeConsentViews),
            MyButton(text: 'Location', type: CountlyButtonType.outlined, onPressed: removeConsentlocation),
            MyButton(text: 'Crashes', type: CountlyButtonType.outlined, onPressed: removeConsentcrashes),
            MyButton(text: 'Attribution', type: CountlyButtonType.outlined, onPressed: removeConsentattribution),
            MyButton(text: 'Users', type: CountlyButtonType.outlined, onPressed: removeConsentusers),
            MyButton(text: 'Push', type: CountlyButtonType.outlined, onPressed: removeConsentpush),
            MyButton(text: 'Star Rating', type: CountlyButtonType.outlined, onPressed: removeConsentstarRating),
            MyButton(text: 'Performance', type: CountlyButtonType.outlined, onPressed: removeConsentAPM),
          ],
        ),
      ],
    );
  }
}
