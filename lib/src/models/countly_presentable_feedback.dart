class CountlyPresentableFeedback {
  CountlyPresentableFeedback(this.widgetId, this.type, this.name);

  final String widgetId;
  final String type;
  final String name;

  static CountlyPresentableFeedback fromJson(dynamic json) {
    return CountlyPresentableFeedback(json['id'], json['type'], json['name']);
  }
}
